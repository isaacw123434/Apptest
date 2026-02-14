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
        firstMile.add(_parseOptionToLeg(option, groupName: name));
      }
    } else if (name.contains('Group 3')) {
      if (options.isNotEmpty) {
        mainLeg = _parseOptionToLeg(options.first, groupName: name);
      }
    } else if (name.contains('Group 4')) {
      for (var option in options) {
        lastMile.add(_parseOptionToLeg(option, groupName: name));
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

Leg _parseOptionToLeg(Map<String, dynamic> option, {String groupName = ''}) {
  String name = option['name'] ?? 'Unknown';
  List<dynamic> jsonLegs = option['legs'] ?? [];

  List<Segment> rawSegments = [];

  for (var jsonLeg in jsonLegs) {
    rawSegments.add(_parseSegment(jsonLeg, optionName: name));
  }

  // Filter short walks between trains
  List<Segment> filteredSegments = [];
  for (int i = 0; i < rawSegments.length; i++) {
    Segment seg = rawSegments[i];
    bool remove = false;
    // Standardize filter threshold to 2.5 mins (<= 2)
    if (seg.mode == 'walk' && seg.time <= 2) {
       // Check if between trains
       if (i > 0 && i < rawSegments.length - 1) {
           Segment prev = rawSegments[i-1];
           Segment next = rawSegments[i+1];
           if (prev.mode == 'train' && next.mode == 'train') {
               remove = true;
           }
       }
    }
    if (!remove) {
        filteredSegments.add(seg);
    }
  }

  // Merge consecutive segments
  List<Segment> mergedSegments = [];
  for (var seg in filteredSegments) {
      if (mergedSegments.isNotEmpty) {
          Segment last = mergedSegments.last;
          if (_shouldMerge(last, seg)) {
              mergedSegments.last = _mergeSegments(last, seg);
              continue;
          }
      }
      mergedSegments.add(seg);
  }

  // Recalculate totals
  double finalDistMiles = 0;
  int finalTime = 0;
  double totalCo2 = 0;

  for (var seg in mergedSegments) {
      finalDistMiles += seg.distance ?? 0;
      finalTime += seg.time;
      if (seg.co2 != null) {
        totalCo2 += seg.co2!;
      } else {
         totalCo2 += calculateEmission(seg.distance ?? 0, seg.iconId);
      }
  }

  String id = _generateId(name);
  String iconId = _mapIconId(name, mergedSegments);
  final risk = _calculateRisk(groupName, name);

  return Leg(
    id: id,
    label: name,
    time: finalTime,
    cost: _estimateCost(name, finalDistMiles, mergedSegments),
    distance: double.parse(finalDistMiles.toStringAsFixed(2)),
    riskScore: risk['score'],
    riskReason: risk['reason'],
    iconId: iconId,
    lineColor: _mapLineColor(name, mergedSegments),
    segments: mergedSegments,
    co2: double.parse(totalCo2.toStringAsFixed(2)),
    detail: _generateDetail(mergedSegments),
  );
}

Map<String, dynamic> _calculateRisk(String groupName, String optionName) {
  String lowerGroup = groupName.toLowerCase();
  String lowerOption = optionName.toLowerCase();

  // Group 1: Access to Leeds Station (First Mile)
  if (lowerGroup.contains('group 1')) {
    if (lowerOption.contains('cycle')) {
      return {'score': 1, 'reason': 'Weather dependent, fitness required'};
    }
    if (lowerOption.contains('bus')) {
      return {'score': 0, 'reason': 'Frequent, reliable'};
    }
    if (lowerOption.contains('uber') || lowerOption.contains('drive')) {
      return {'score': 0, 'reason': 'Most reliable'};
    }
  }

  // Group 2: Access via Headingley (First Mile) OR Access Options (Route 2)
  if (lowerGroup.contains('group 2')) {
    // Route 2: Bus + Train
    if (lowerOption.contains('bus') && lowerOption.contains('train')) {
       return {'score': 2, 'reason': 'Bus risk (+1) + Connection risk (+1)'};
    }

    // Route 2: P&R
    if (lowerOption.contains('p&r')) {
       return {'score': 1, 'reason': 'Connection risk'};
    }

    // Route 1 existing
    if (lowerOption.contains('walk') && lowerOption.contains('train')) {
      return {'score': 2, 'reason': 'Timing risk (+1) + Connection risk (+1)'};
    }
    if (lowerOption.contains('cycle') && lowerOption.contains('train')) {
      return {'score': 1, 'reason': 'Weather dependent, connection risk'};
    }
    // Route 1 & 2 Uber/Drive + Train
    if ((lowerOption.contains('uber') || lowerOption.contains('drive')) && lowerOption.contains('train')) {
      return {'score': 1, 'reason': 'Connection risk'};
    }
  }

  // Group 3: Core Journey (Main Leg)
  if (lowerGroup.contains('group 3')) {
    if (lowerOption.contains('train')) {
      return {'score': 1, 'reason': 'Delay/timing risk'};
    }
  }

  // Group 4: Final Mile
  if (lowerGroup.contains('group 4')) {
    if (lowerOption.contains('bus')) {
      return {'score': 2, 'reason': 'Unfamiliar area, less frequent'};
    }
    if (lowerOption.contains('uber')) {
      return {'score': 0, 'reason': 'Most reliable'};
    }
    if (lowerOption.contains('cycle')) {
      return {'score': 1, 'reason': 'Weather dependent, fitness required'};
    }
  }

  // Group 5: Direct Option (Direct Drive)
  if (lowerGroup.contains('group 5')) {
     return {'score': 0, 'reason': 'Most reliable'};
  }

  return {'score': 0, 'reason': 'Standard risk'};
}

bool _shouldMerge(Segment a, Segment b) {
  // Always merge consecutive segments of the same mode/label
  if (a.mode == b.mode && a.label == b.label) {
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

Segment _parseSegment(Map<String, dynamic> jsonSegment, {String optionName = ''}) {
  String rawMode = (jsonSegment['mode'] as String? ?? '').toLowerCase();
  String mode = _mapMode(rawMode, jsonSegment['transit_details']);
  String polyline = jsonSegment['polyline'] ?? '';
  List<LatLng> path = decodePolyline(polyline);

  String label = mode;
  String lineColor = '#000000';
  String iconId = IconIds.footprints;

  if (jsonSegment['transit_details'] != null) {
      var td = jsonSegment['transit_details'];

      String? color = td['color'];
      if (td['line'] != null && td['line']['color'] != null) {
        color = td['line']['color'];
      }
      if (color != null) lineColor = color;

      String? lineName = td['line_name'];
      if (td['line'] != null) {
         // FIX: Prioritize short_name (Provider) over name (Route Direction)
         lineName = td['line']['short_name'];

         // Fallback to agency name if short_name is missing
         if (lineName == null && td['line']['agencies'] != null) {
            var agencies = td['line']['agencies'] as List;
            if (agencies.isNotEmpty) {
               lineName = agencies[0]['name'];
            }
         }

         // Final fallback to the route name
         lineName ??= td['line']['name'];
      }

      String? vehicleType = td['vehicle_type'];
      if (td['line'] != null && td['line']['vehicle'] != null) {
         vehicleType = td['line']['vehicle']['name'];
      }

      label = lineName ?? vehicleType ?? mode;

      if (mode == 'bus') iconId = IconIds.bus;
      if (mode == 'train') iconId = IconIds.train;

      // If label is just a number and mode is bus, prepend "Bus "
      if (mode == 'bus' && RegExp(r'^\d+$').hasMatch(label)) {
          label = 'Bus $label';
      }
      // Also set lineColor for bus/train if not present in transit_details (though it usually is)
  } else {
      // Defaults
      if (mode == 'car' || mode == 'taxi') {
          iconId = IconIds.car;
          if (optionName.toLowerCase().contains('uber')) {
             label = 'Uber';
             lineColor = '#000000'; // Black for Uber
          } else {
             label = 'Drive';
             lineColor = '#0000FF';
          }
      } else if (mode == 'bike') {
          iconId = IconIds.bike;
          lineColor = '#00FF00';
      } else if (mode == 'walk') {
          iconId = IconIds.footprints;
          lineColor = '#475569';
      }
  }

  // Capitalize label
  if (label.isNotEmpty) {
      label = label[0].toUpperCase() + label.substring(1);
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
            String? type = transitDetails['vehicle_type'] as String?;

            if (type == null && transitDetails['line'] != null && transitDetails['line']['vehicle'] != null) {
               type = transitDetails['line']['vehicle']['type'];
            }

            type = type?.toUpperCase() ?? '';

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
        if (lower.contains('cycle')) return 'train_cycle_headingley';
        if (lower.contains('uber')) return 'train_uber_headingley';
        if (lower.contains('drive')) return 'train_drive';
        if (lower.contains('bus')) return 'train_bus';
        return 'train_main';
    }
    if (lower.contains('uber')) return 'uber';
    if (lower.contains('bus')) return 'bus';
    if (lower.contains('cycle')) return 'cycle';
    if (lower.contains('direct drive')) return 'direct_drive';
    if (lower.contains('drive')) return 'drive';

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
        if (lower.contains('cycle')) return IconIds.bike;
        if (lower.contains('uber')) return IconIds.car;
        if (lower.contains('drive')) return IconIds.car;
        if (lower.contains('bus')) return IconIds.bus;
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

    // P&R logic
    if (lower.contains('p&r')) {
        // Drive cost + Parking (£5.00)
        return 5.00 + (0.45 * distanceMiles);
    }

    // Train logic (covers Access + Train combinations)
    if (lower.contains('train')) {
        // Generalized Train Cost: Base + Rate
        double trainCost = 5.00 + (0.30 * distanceMiles);

        // Add Access Cost
        if (lower.contains('uber')) {
            return trainCost + 8.00 + (1.50 * 3); // Approx access
        }
        if (lower.contains('drive')) {
             return trainCost + 5.00; // Fuel/Parking
        }
        if (lower.contains('bus')) {
             return trainCost + 2.00;
        }
        return trainCost;
    }

    if (lower.contains('uber')) {
        return 2.50 + (2.00 * distanceMiles);
    }
    if (lower.contains('drive') || lower.contains('parking') || lower.contains('direct drive')) {
         return 0.45 * distanceMiles;
    }
    if (lower.contains('bus')) {
        return 2.00 + (0.10 * distanceMiles);
    }
    if (lower.contains('cycle') || lower.contains('walk')) {
        return 0.00;
    }
    return 0.00;
}
