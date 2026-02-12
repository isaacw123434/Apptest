import 'package:latlong2/latlong.dart';
import '../models.dart';
import '../utils/emission_utils.dart';
import 'mock_data.dart';
import 'new_mock_data.dart';
import '../utils/polyline.dart';

class ApiService {
  // Simulate network delay
  static const Duration _delay = Duration(milliseconds: 500);

  Future<InitData> fetchInitData() async {
    await Future.delayed(_delay);

    final segmentOptions = _getSegmentOptionsWithPaths();

    // Mock path for Direct Drive (Leeds to East Leake)
    final directDriveRoute = rawRoutesData.firstWhere(
      (r) => r['id'] == 'direct_drive',
      orElse: () => {'polyline': ''},
    );

    List<LatLng> mockPath = [];
    if (directDriveRoute['polyline'] != null && (directDriveRoute['polyline'] as String).isNotEmpty) {
      mockPath = decodePolyline(directDriveRoute['polyline']);
    } else {
      mockPath = [
        LatLng(53.8008, -1.5491), // Leeds
        LatLng(52.7698, -1.2062), // East Leake
      ];
    }

    return InitData(
      segmentOptions: segmentOptions,
      directDrive: DirectDrive.fromJson(directDriveData),
      mockPath: mockPath,
    );
  }

  Future<List<JourneyResult>> searchJourneys({
    required String tab,
    required Map<String, bool> selectedModes,
  }) async {
    await Future.delayed(_delay);

    final options = _getSegmentOptionsWithPaths();
    List<JourneyResult> combos = [];

    // Generate Combinations
    for (var l1 in options.firstMile) {
      for (var l3 in options.lastMile) {
        // Calculate Stats
        int buffer = 10; // Hardcoded buffer
        double cost = l1.cost + options.mainLeg.cost + l3.cost;
        int time = l1.time + buffer + options.mainLeg.time + l3.time;
        int risk = l1.riskScore + options.mainLeg.riskScore + l3.riskScore;

        // Calculate Emissions
        double directDriveDist = directDriveData['distance'] as double;
        double carEmission = directDriveDist * 0.27; // direct drive distance * factor

        double totalEmission = (l1.distance * getEmissionFactor(l1.iconId)) +
            (options.mainLeg.distance * getEmissionFactor(options.mainLeg.iconId)) +
            (l3.distance * getEmissionFactor(l3.iconId));

        double savings = carEmission - totalEmission;
        int savingsPercent = 0;
        if (carEmission > 0) {
           savingsPercent = ((savings / carEmission) * 100).round();
        }

        combos.add(JourneyResult(
          id: '${l1.id}-${l3.id}',
          leg1: l1,
          leg3: l3,
          cost: cost,
          time: time,
          buffer: buffer,
          risk: risk,
          emissions: Emissions(
            val: savings,
            percent: savingsPercent,
            text: savings > 0 ? 'Saves $savingsPercent% CO₂ vs driving' : null
          ),
        ));
      }
    }

    // Filter Modes
    combos = combos.where((combo) {
      final allSegments = [
        ...combo.leg1.segments,
        ...options.mainLeg.segments,
        ...combo.leg3.segments
      ];
      return allSegments.every((seg) {
        if (seg.mode == 'walk') return true;
        if (seg.mode == 'taxi') return selectedModes['taxi'] ?? true;
        return selectedModes[seg.mode] ?? true;
      });
    }).toList();

    // Sort based on Tab
    if (tab == 'fastest') {
      combos.sort((a, b) => a.time.compareTo(b.time));
    } else if (tab == 'cheapest') {
      combos.sort((a, b) => a.cost.compareTo(b.cost));
    } else {
      // Smart: Cost + 0.3 * Time + 20 * (Risk - MinRisk)
      // Prioritize lowest risk by giving it a baseline of 0 and penalizing excess risk heavily.
      int minRisk = 0;
      if (combos.isNotEmpty) {
        minRisk = combos.map((c) => c.risk).reduce((a, b) => a < b ? a : b);
      }

      combos.sort((a, b) {
        double scoreA = a.cost + (a.time * 0.3) + ((a.risk - minRisk) * 20.0);
        double scoreB = b.cost + (b.time * 0.3) + ((b.risk - minRisk) * 20.0);
        return scoreA.compareTo(scoreB);
      });
    }

    return combos.take(3).toList();
  }

  SegmentOptions _getSegmentOptionsWithPaths() {
    // Create a deep copy of the data structure to inject paths

    Map<String, dynamic> data = Map<String, dynamic>.from(segmentOptionsData);
    data['firstMile'] = (data['firstMile'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    data['lastMile'] = (data['lastMile'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    data['mainLeg'] = Map<String, dynamic>.from(data['mainLeg']);

    // Helper to extract path and color from a specific leg of a journey
    void attachFromJourney(Map<String, dynamic> optionLeg, String journeyName, List<int> legIndices) {
       final journey = newRoutesData.firstWhere(
          (j) => (j['name'] as String).startsWith(journeyName),
          orElse: () => {},
       );

       if (journey.isEmpty || journey['legs'] == null) return;

       List legs = journey['legs'] as List;
       List segments = optionLeg['segments'] as List;

       List<Map<String, dynamic>> newSegments = [];
       for (int i = 0; i < segments.length; i++) {
          var sMap = Map<String, dynamic>.from(segments[i]);

          if (i < legIndices.length) {
             int legIndex = legIndices[i];
             if (legIndex < legs.length) {
                var legData = legs[legIndex];
                String polyline = legData['polyline'];
                String color = legData['color'];

                sMap['path'] = decodePolyline(polyline);
                sMap['lineColor'] = color;
             }
          }
          newSegments.add(sMap);
       }
       optionLeg['segments'] = newSegments;
    }

    // Process First Mile
    for (var leg in data['firstMile']) {
       String id = leg['id'];
       if (id == 'cycle') {
          attachFromJourney(leg, "Cycle to Station", [0]);
       } else if (id == 'bus') {
          attachFromJourney(leg, "Bus to Station", [0]);
       } else if (id == 'drive_park') {
          attachFromJourney(leg, "Drive to Station", [0]);
       } else if (id == 'uber') {
           // Reuse Drive to Station leg 0 as approximation for Uber to Station
           attachFromJourney(leg, "Drive to Station", [0]);
       } else if (id == 'train_walk_headingley') {
          attachFromJourney(leg, "Walk/Train + Train + Cycle", [0, 1]);
       } else if (id == 'train_uber_headingley') {
          attachFromJourney(leg, "Uber/Train + Train + Walk/Bus", [0, 1]);
       }
    }

    // Process Main Leg
    // "Cycle to Station + Train + Bus" has Main Leg at index 1
    attachFromJourney(data['mainLeg'], "Cycle to Station", [1]);

    // Process Last Mile
    for (var leg in data['lastMile']) {
       String id = leg['id'];
       if (id == 'uber') {
          // "Drive to Station + Train + Uber" -> Leg 2 is Uber
          attachFromJourney(leg, "Drive to Station", [2]);
       } else if (id == 'bus') {
          // "Cycle to Station + Train + Bus" -> Leg 2 is Bus
          attachFromJourney(leg, "Cycle to Station", [2]);
       } else if (id == 'cycle') {
          // "Walk/Train + Train + Cycle" -> Leg 3 is Cycle
          attachFromJourney(leg, "Walk/Train", [3]);
       }
    }

    return SegmentOptions.fromJson(data);
  }
}
