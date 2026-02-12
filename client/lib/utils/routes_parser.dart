import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../models.dart';
import 'polyline.dart';
import 'emission_utils.dart';

InitData parseRoutesJson(String jsonString) {
  final Map<String, dynamic> data = jsonDecode(jsonString);
  final List<dynamic> groups = data['groups'];

  List<Leg> firstMile = [];
  Leg? mainLeg;
  List<Leg> lastMile = [];
  DirectDrive? directDrive;
  List<LatLng> mockPath = [];

  for (var group in groups) {
    String name = group['name'] ?? '';
    List<dynamic> options = group['options'] ?? [];

    if (name.contains('Group 1') || name.contains('Group 2')) {
      for (var option in options) {
        firstMile.add(_parseOptionToLeg(option));
      }
    } else if (name.contains('Group 3')) {
      if (options.isNotEmpty) {
        mainLeg = _parseOptionToLeg(options.first);
      }
    } else if (name.contains('Group 4')) {
      for (var option in options) {
        lastMile.add(_parseOptionToLeg(option));
      }
    } else if (name.contains('Group 5')) {
      // Direct Drive
      if (options.isNotEmpty) {
        var directOption = options.first;

        double totalDistMeters = 0;
        int totalDurationSeconds = 0;
        List<LatLng> fullPath = [];
        List<dynamic> legs = directOption['legs'] ?? [];

        for (var leg in legs) {
           totalDurationSeconds += (leg['duration_value'] as num).toInt();
           totalDistMeters += (leg['distance_value'] as num).toDouble();
           String polyline = leg['polyline'] ?? '';
           if (polyline.isNotEmpty) {
             fullPath.addAll(decodePolyline(polyline));
           }
        }

        double totalDistMiles = totalDistMeters / 1609.34;

        mockPath = fullPath;
        directDrive = DirectDrive(
          time: (totalDurationSeconds / 60).round(),
          cost: _estimateCost('Direct Drive', totalDistMiles, []),
          distance: double.parse(totalDistMiles.toStringAsFixed(2)),
          co2: calculateEmission(totalDistMiles, IconIds.car),
        );
      }
    }
  }

  // Fallback if missing
  mainLeg ??= Leg(id: 'main_placeholder', label: 'Main', segments: [], time: 0, cost: 0, distance: 0, riskScore: 0, iconId: IconIds.train, lineColor: '#000000');

  directDrive ??= DirectDrive(time: 0, cost: 0, distance: 0);

  return InitData(
    segmentOptions: SegmentOptions(
      firstMile: firstMile,
      mainLeg: mainLeg,
      lastMile: lastMile,
    ),
    directDrive: directDrive,
    mockPath: mockPath,
  );
}

Leg _parseOptionToLeg(Map<String, dynamic> option) {
  String name = option['name'] ?? 'Unknown';
  List<dynamic> jsonLegs = option['legs'] ?? [];

  List<Segment> segments = [];
  double totalDistMeters = 0;
  int totalDurationSeconds = 0;

  for (var jsonLeg in jsonLegs) {
    Segment newSeg = _parseSegment(jsonLeg);

    if (segments.isNotEmpty) {
      Segment lastSeg = segments.last;
      if (_shouldMerge(lastSeg, newSeg)) {
        segments.last = _mergeSegments(lastSeg, newSeg);
        totalDistMeters += (jsonLeg['distance_value'] as num).toDouble();
        totalDurationSeconds += (jsonLeg['duration_value'] as num).toInt();
        continue;
      }
    }

    segments.add(newSeg);
    totalDistMeters += (jsonLeg['distance_value'] as num).toDouble();
    totalDurationSeconds += (jsonLeg['duration_value'] as num).toInt();
  }

  double totalDistMiles = totalDistMeters / 1609.34;
  String id = _generateId(name);
  String iconId = _mapIconId(name, segments);

  // Calculate total CO2 based on segments
  double totalCo2 = 0;
  for (var seg in segments) {
      if (seg.co2 != null) {
        totalCo2 += seg.co2!;
      } else {
          // Estimate
          totalCo2 += calculateEmission(seg.distance ?? 0, seg.iconId);
      }
  }

  return Leg(
    id: id,
    label: name,
    time: (totalDurationSeconds / 60).round(),
    cost: _estimateCost(name, totalDistMiles, segments),
    distance: double.parse(totalDistMiles.toStringAsFixed(2)),
    riskScore: 0,
    iconId: iconId,
    lineColor: _mapLineColor(name, segments),
    segments: segments,
    co2: double.parse(totalCo2.toStringAsFixed(2)),
    detail: _generateDetail(segments),
  );
}

bool _shouldMerge(Segment a, Segment b) {
  // Always merge consecutive segments of the same mode/label for walking/cycling/driving
  if (a.mode == b.mode && a.label == b.label) {
    // Optionally exclude 'bus'/'train' if we want to show stops,
    // but usually consecutive transit legs mean "stay on vehicle" if label is same.
    return true;
  }
  return false;
}

Segment _mergeSegments(Segment a, Segment b) {
  // Concatenate paths
  List<LatLng> newPath = [];
  if (a.path != null) newPath.addAll(a.path!);
  if (b.path != null) newPath.addAll(b.path!);

  // Sum metrics
  int newTime = a.time + b.time;
  double newDist = (a.distance ?? 0) + (b.distance ?? 0);
  double newCo2 = (a.co2 ?? 0) + (b.co2 ?? 0);

  return Segment(
    mode: a.mode,
    label: a.label,
    lineColor: a.lineColor,
    iconId: a.iconId,
    time: newTime,
    path: newPath,
    distance: newDist,
    co2: newCo2,
    detail: a.detail, // Keep original detail or update?
  );
}

Segment _parseSegment(Map<String, dynamic> jsonSegment) {
  String rawMode = jsonSegment['mode'] ?? '';
  String mode = _mapMode(rawMode, jsonSegment['transit_details']);
  String polyline = jsonSegment['polyline'] ?? '';
  List<LatLng> path = decodePolyline(polyline);

  String label = mode;
  String lineColor = '#000000';
  String iconId = IconIds.footprints;

  if (jsonSegment.containsKey('transit_details')) {
      var td = jsonSegment['transit_details'];
      String? color = td['color'];
      if (color != null) lineColor = color;

      label = td['line_name'] ?? td['vehicle_type'] ?? mode;

      if (mode == 'bus') iconId = IconIds.bus;
      if (mode == 'train') iconId = IconIds.train;
      // Also set lineColor for bus/train if not present in transit_details (though it usually is)
  } else {
      // Defaults
      if (mode == 'car' || mode == 'taxi') {
          iconId = IconIds.car;
          lineColor = '#0000FF';
      } else if (mode == 'bike') {
          iconId = IconIds.bike;
          lineColor = '#00FF00';
      } else if (mode == 'walk') {
          iconId = IconIds.footprints;
          lineColor = '#475569';
      }
  }

  double distMiles = (jsonSegment['distance_value'] as num).toDouble() / 1609.34;

  return Segment(
    mode: mode,
    label: label,
    lineColor: lineColor,
    iconId: iconId,
    time: ((jsonSegment['duration_value'] as num) / 60).round(),
    path: path,
    distance: distMiles,
    co2: calculateEmission(distMiles, iconId),
  );
}

String _mapMode(String rawMode, Map<String, dynamic>? transitDetails) {
    if (rawMode == 'walking') return 'walk';
    if (rawMode == 'driving') return 'car';
    if (rawMode == 'bicycling') return 'bike';
    if (rawMode == 'transit') {
        if (transitDetails != null) {
            String type = (transitDetails['vehicle_type'] as String?)?.toUpperCase() ?? '';
            if (type == 'BUS') return 'bus';
            if (type == 'HEAVY_RAIL' || type == 'TRAIN') return 'train';
        }
        return 'bus'; // Default to bus?
    }
    return rawMode; // e.g. taxi?
}

String _generateId(String name) {
    String lower = name.toLowerCase();
    if (lower.contains('train')) {
        if (lower.contains('walk')) return 'train_walk_headingley';
        if (lower.contains('uber')) return 'train_uber_headingley';
        return 'train_main';
    }
    if (lower.contains('uber')) return 'uber';
    if (lower.contains('bus')) return 'bus';
    if (lower.contains('cycle')) return 'cycle';
    if (lower.contains('drive')) return 'direct_drive'; // or drive_park
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
}

String _mapIconId(String name, List<Segment> segments) {
    String lower = name.toLowerCase();
    if (lower.contains('uber')) return IconIds.car;
    if (lower.contains('bus')) return IconIds.bus;
    if (lower.contains('cycle')) return IconIds.bike;
    if (lower.contains('train')) {
        // If it's pure train, train. If walk+train, walk? No, icon for the leg usually represents the main mode.
        // Or specific logic.
        if (lower.contains('walk')) return IconIds.footprints; // Based on mock data
        if (lower.contains('uber')) return IconIds.car;
        return IconIds.train;
    }
    if (lower.contains('walk')) return IconIds.footprints;
    return IconIds.car;
}

String _mapLineColor(String name, List<Segment> segments) {
    // Return color of the main segment or just mapped from name
    String lower = name.toLowerCase();
    if (lower.contains('cycle')) return '#00FF00';

    // Find the segment with the "biggest" mode?
    // Or just look for specific modes.
    for (var seg in segments) {
        if (seg.mode == 'train') return seg.lineColor;
        if (seg.mode == 'bus') return seg.lineColor;
    }

    return '#000000';
}

String _generateDetail(List<Segment> segments) {
    // "5min walk + 16min bus"
    // Summarize consecutive same-mode segments? Or just major ones.

    // Simple approach: list distinct modes with times
    // But walk+bus+walk -> "5min walk + 16min bus + 4min walk"
    // This matches "5min walk + 16min bus" from mock data roughly.

    List<String> parts = [];
    for (var seg in segments) {
        if (seg.time > 0) {
            parts.add('${seg.time}m ${seg.mode}');
        }
    }
    if (parts.isEmpty) return "";
    return parts.join(' + ');
}

double _estimateCost(String name, double distanceMiles, List<Segment> segments) {
    String lower = name.toLowerCase();
    if (lower.contains('uber') || lower.contains('drive')) {
        // Uber: Base £2.50 + £1.25/mile
        return 2.50 + (1.25 * distanceMiles);
    }
    if (lower.contains('bus')) {
        return 2.00; // Flat fare
    }
    if (lower.contains('train')) {
        return 5.00 + (0.5 * distanceMiles);
    }
    if (lower.contains('cycle') || lower.contains('walk')) {
        return 0.00;
    }
    return 0.00;
}
