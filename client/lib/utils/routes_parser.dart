import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../models.dart';
import 'polyline.dart';
import 'emission_utils.dart';

const Map<String, Map<String, double>> pricing = {
  'brough': {'parking': 5.80, 'uber': 22.58, 'train': 8.10},
  'york': {'parking': 13.95, 'uber': 46.24, 'train': 5.20},
  'beverley': {'parking': 4.40, 'uber': 4.62, 'train': 12.10},
  'hull': {'parking': 6.00, 'uber': 20.63, 'train': 9.60},
  'eastrington': {'parking': 0.00, 'uber': 34.75, 'train': 7.00},
};

InitData parseRoutesJson(String jsonString, {String? routeId}) {
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
        firstMile.add(_parseOptionToLeg(option, groupName: name, routeId: routeId));
      }
    } else if (name.contains('Group 3')) {
      if (options.isNotEmpty) {
        mainLeg = _parseOptionToLeg(options.first, groupName: name, routeId: routeId);
      }
    } else if (name.contains('Group 4')) {
      for (var option in options) {
        lastMile.add(_parseOptionToLeg(option, groupName: name, routeId: routeId));
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

Leg _parseOptionToLeg(Map<String, dynamic> option, {String groupName = '', String? routeId}) {
  String name = option['name'] ?? 'Unknown';
  List<dynamic> jsonLegs = option['legs'] ?? [];

  List<Segment> rawSegments = [];

  for (var jsonLeg in jsonLegs) {
    rawSegments.add(_parseSegment(jsonLeg, optionName: name));
  }

  // Filter short walks
  List<Segment> filteredSegments = [];
  for (int i = 0; i < rawSegments.length; i++) {
    Segment seg = rawSegments[i];
    bool remove = false;
    // Remove short walks <= 1 min
    if (seg.mode == 'walk' && seg.time <= 1) {
       remove = true;
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

  // Deduplicate Base Fare for Generic Trains (assume single ticket)
  // If multiple train segments exist, only the first one should carry the base fare (5.00).
  // _parseSegment adds 5.00 to every train segment.
  bool trainBaseApplied = false;
  for (int i = 0; i < mergedSegments.length; i++) {
      if (mergedSegments[i].mode == 'train') {
          if (trainBaseApplied) {
              // Remove base fare of 5.00
              double newCost = mergedSegments[i].cost - 5.00;
              if (newCost < 0) newCost = 0;

              var seg = mergedSegments[i];
              mergedSegments[i] = Segment(
                  mode: seg.mode, label: seg.label, lineColor: seg.lineColor, iconId: seg.iconId, time: seg.time,
                  from: seg.from, to: seg.to, detail: seg.detail, path: seg.path, co2: seg.co2, distance: seg.distance,
                  cost: newCost
              );
          }
          trainBaseApplied = true;
      }
  }

  // Determine Location for Pricing
  String? location;
  // Try to find a train segment and get its origin
  for (var seg in mergedSegments) {
      if (seg.mode == 'train' && seg.from != null) {
          location = seg.from!.toLowerCase().split(' ')[0]; // "York (YRK)" -> "york"
          if (location.contains('eastrington')) location = 'eastrington';
          break;
      }
  }
  // Fallback: check option name
  if (location == null) {
      String lowerName = name.toLowerCase();
      if (lowerName.contains('brough')) {
        location = 'brough';
      } else if (lowerName.contains('york')) {
        location = 'york';
      } else if (lowerName.contains('beverley')) {
        location = 'beverley';
      } else if (lowerName.contains('hull')) {
        location = 'hull';
      } else if (lowerName.contains('eastrington')) {
        location = 'eastrington';
      }
  }

  // Insert Parking Segment
  for (int i = 0; i < mergedSegments.length - 1; i++) {
     Segment current = mergedSegments[i];
     Segment next = mergedSegments[i+1];

     if (current.mode == 'car' && next.mode == 'train') {
         // Check if it's NOT Uber
         bool isUber = current.label.toLowerCase().contains('uber');
         if (!isUber) {
             double parkingCost = 5.00;
             if (location != null && pricing.containsKey(location)) {
                 parkingCost = pricing[location]!['parking'] ?? 5.00;
             }

             // Insert Parking
             mergedSegments.insert(i + 1, Segment(
                 mode: 'parking',
                 label: 'Parking',
                 lineColor: '#000000',
                 iconId: IconIds.parking,
                 time: 0,
                 cost: parkingCost,
             ));
             i++; // Skip the newly inserted segment
         }
     }
  }

  // Inject Transfer Buffer for Route 2 Access Options (Issue 4)
  if (routeId == 'route2' &&
      groupName.contains('Access Options') &&
      name.toLowerCase().contains('train')) {

        // Find the train segment index
        int trainIndex = -1;
        for (int i=0; i<mergedSegments.length; i++) {
           if (mergedSegments[i].mode == 'train') {
              trainIndex = i;
              break;
           }
        }

        if (trainIndex != -1) {
           // Insert Transfer before train
           mergedSegments.insert(trainIndex, Segment(
             mode: 'wait',
             label: 'Transfer',
             lineColor: '#000000',
             iconId: 'clock',
             time: 10,
             detail: 'Transfer Buffer',
           ));
        }
  }

  // Apply Specific Pricing if available
  if (location != null && pricing.containsKey(location)) {
      final prices = pricing[location]!;
      bool trainCostApplied = false;
      bool uberCostApplied = false;

      for (int i = 0; i < mergedSegments.length; i++) {
          final seg = mergedSegments[i];
          if (seg.mode == 'train' && prices.containsKey('train')) {
              double cost = trainCostApplied ? 0.0 : prices['train']!;
              mergedSegments[i] = Segment(
                  mode: seg.mode, label: seg.label, lineColor: seg.lineColor, iconId: seg.iconId, time: seg.time,
                  from: seg.from, to: seg.to, detail: seg.detail, path: seg.path, co2: seg.co2, distance: seg.distance,
                  cost: cost
              );
              trainCostApplied = true;
          }
          if (seg.mode == 'car' && seg.label.toLowerCase().contains('uber') && prices.containsKey('uber')) {
              double cost = uberCostApplied ? 0.0 : prices['uber']!;
              mergedSegments[i] = Segment(
                  mode: seg.mode, label: seg.label, lineColor: seg.lineColor, iconId: seg.iconId, time: seg.time,
                  from: seg.from, to: seg.to, detail: seg.detail, path: seg.path, co2: seg.co2, distance: seg.distance,
                  cost: cost
              );
              uberCostApplied = true;
          }
      }
  }

  // Recalculate totals
  double finalDistMiles = 0;
  int finalTime = 0;
  double totalCo2 = 0;
  double totalCost = 0;

  for (var seg in mergedSegments) {
      finalDistMiles += seg.distance ?? 0;
      finalTime += seg.time;
      if (seg.co2 != null) {
        totalCo2 += seg.co2!;
      } else {
         totalCo2 += calculateEmission(seg.distance ?? 0, seg.iconId);
      }
      totalCost += seg.cost;
  }

  String id = _generateId(name);
  String iconId = _mapIconId(name, mergedSegments);
  final risk = _calculateRisk(groupName, name);

  return Leg(
    id: id,
    label: name,
    time: finalTime,
    cost: totalCost, // Use summed cost
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
    if (a.mode == 'train') return false;
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
  double newCost = a.cost + b.cost;

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
    cost: newCost,
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
  String? from;
  String? to;

  if (jsonSegment['transit_details'] != null) {
      var td = jsonSegment['transit_details'];

      if (td['departure_stop'] != null) {
        from = td['departure_stop']['name'];
      }
      if (td['arrival_stop'] != null) {
        to = td['arrival_stop']['name'];
      }

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

      // Try to parse instructions for From/To if not transit
      String instructions = jsonSegment['instructions'] ?? '';
      if (instructions.isNotEmpty) {
          // "Driving from A to B"
          // "Walk to B"

          final fromMatch = RegExp(r'from\s+(.*?)(?=\s+to\s+|$)', caseSensitive: false).firstMatch(instructions);
          if (fromMatch != null) {
              from ??= fromMatch.group(1);
          }

          final toMatch = RegExp(r'to\s+(.*?)(?=$)', caseSensitive: false).firstMatch(instructions);
          if (toMatch != null) {
              to ??= toMatch.group(1);
          }
      }
  }

  // Capitalize label
  if (label.isNotEmpty) {
      label = label[0].toUpperCase() + label.substring(1);
  }

  double distMiles = (jsonSegment['distance_value'] as num).toDouble() / 1609.34;

  double cost = 0.0;
  if (mode == 'car') {
     if (label.toLowerCase().contains('uber') || optionName.toLowerCase().contains('uber')) {
         cost = 2.50 + (2.00 * distMiles);
     } else {
         cost = 0.45 * distMiles;
     }
  } else if (mode == 'bus') {
     cost = 2.00 + (0.10 * distMiles);
  } else if (mode == 'train') {
     cost = 5.00 + (0.30 * distMiles);
  }

  return Segment(
    mode: mode,
    label: label,
    lineColor: lineColor,
    iconId: iconId,
    time: ((jsonSegment['duration_value'] as num) / 60).round(),
    path: path,
    distance: distMiles,
    co2: calculateEmission(distMiles, iconId),
    from: from,
    to: to,
    cost: cost,
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

    // Extract hub name if possible
    String? hub;
    if (lower.contains('brough')) {
      hub = 'brough';
    } else if (lower.contains('york')) {
      hub = 'york';
    } else if (lower.contains('beverley')) {
      hub = 'beverley';
    } else if (lower.contains('hull')) {
      hub = 'hull';
    } else if (lower.contains('eastrington')) {
      hub = 'eastrington';
    } else if (lower.contains('headingley')) {
      hub = 'headingley';
    }

    // P&R
    if (lower.contains('p&r') || lower.contains('park & ride')) {
       if (lower.contains('stourton')) return 'drive_stourton_pr';
       if (lower.contains('temple green')) return 'drive_temple_green_pr';
       if (lower.contains('elland road')) return 'drive_elland_road_pr';
       return 'drive_pr'; // fallback
    }

    if (lower.contains('train')) {
        if (hub != null) {
             if (lower.contains('walk')) return 'train_walk_$hub';
             if (lower.contains('cycle')) return 'train_cycle_$hub';
             if (lower.contains('uber')) return 'train_uber_$hub';
             if (lower.contains('drive')) return 'train_drive_$hub';
             if (lower.contains('bus')) return 'train_bus_$hub';
             return 'train_$hub';
        }

        // Fallback for Headingley legacy if not explicitly matched above but contained 'headingley' (already handled)
        // Or if no hub found (e.g. "Train: Leeds to Loughborough" -> train_main)
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
