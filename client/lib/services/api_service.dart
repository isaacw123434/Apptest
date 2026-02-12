import 'package:latlong2/latlong.dart';
import '../models.dart';
import '../utils/emission_utils.dart';
import 'mock_data.dart';
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

    // Pre-fetch all routes
    Map<String, List<LatLng>> routePolylines = {};
    for (var route in rawRoutesData) {
      if (route['polyline'] != null && (route['polyline'] as String).isNotEmpty) {
        routePolylines[route['id']] = decodePolyline(route['polyline']);
      }
    }

    List<LatLng>? getPoints(String? routeId) {
      if (routeId == null) return null;
      return routePolylines[routeId];
    }

    // Helper to attach path
    void attachPath(Map<String, dynamic> leg, String? routeIdOverride) {
      String id = leg['id'];
      List segments = leg['segments'] as List;

      // Special handling for multi-segment legs
      if (id == 'train_walk_headingley') {
        leg['segments'] = segments.map((s) {
          var sMap = Map<String, dynamic>.from(s);
          String mode = sMap['mode'] ?? '';
          if (mode == 'train') {
            sMap['path'] = getPoints(routesMap['train_walk_headingley']);
          } else {
            sMap.remove('path');
          }
          return sMap;
        }).toList();
        return;
      } else if (id == 'train_uber_headingley') {
        leg['segments'] = segments.map((s) {
          var sMap = Map<String, dynamic>.from(s);
          String mode = sMap['mode'] ?? '';
          if (mode == 'train') {
            sMap['path'] = getPoints(routesMap['train_walk_headingley']);
          } else {
            sMap.remove('path');
          }
          return sMap;
        }).toList();
        return;
      }

      String? routeId;
      if (routeIdOverride != null) {
        routeId = routeIdOverride;
      } else {
        if (id == 'uber') {
          routeId = routesMap['uber'];
        } else if (id == 'bus') {
          routeId = routesMap['bus'];
        } else if (id == 'cycle') {
          routeId = routesMap['cycle'];
        } else if (id == 'train_main') {
          routeId = routesMap['train_main'];
        } else if (id == 'drive_park') {
          routeId = routesMap['uber']; // Approximation
        }
      }

      final points = getPoints(routeId);

      if (points != null) {
        leg['segments'] = segments.map((s) {
          var sMap = Map<String, dynamic>.from(s);

          // Logic to decide if we should attach path to this segment
          String mode = sMap['mode'] ?? '';
          String routeIdString = routeId!.toLowerCase();
          bool shouldAttach = false;

          // Check keywords in the ID
          if (routeIdString.contains('train') && mode == 'train') {
            shouldAttach = true;
          } else if ((routeIdString.contains('drive') || routeIdString.contains('uber')) &&
              (mode == 'car' || mode == 'taxi')) {
            shouldAttach = true;
          } else if (routeIdString.contains('bus') && mode == 'bus') {
            shouldAttach = true;
          } else if (routeIdString.contains('cycle') && mode == 'bike') {
            shouldAttach = true;
          } else if (routeIdString.contains('direct_drive') && mode == 'car') {
             // direct_drive contains 'drive', so the second condition might catch it,
             // but 'direct_drive' mode might be different?
             // Actually direct drive mode is 'car' usually.
             // But direct drive is handled via fetchInitData directDrive prop, not here usually.
             // However, checking just in case.
            shouldAttach = true;
          }

          if (shouldAttach) {
            sMap['path'] = points;
          }
          return sMap;
        }).toList();
      }
    }

    // Process First Mile
    for (var leg in data['firstMile']) {
      attachPath(leg, null);
    }

    // Process Main Leg
    attachPath(data['mainLeg'], routesMap['train_main']);

    // Process Last Mile
    for (var leg in data['lastMile']) {
        String? routeId;
        String id = leg['id'];
        if (id == 'uber') {
          routeId = routesMap['last_uber'];
        } else if (id == 'bus') {
          routeId = routesMap['last_bus'];
        } else if (id == 'cycle') {
          routeId = routesMap['last_cycle'];
        }

        attachPath(leg, routeId);
    }

    return SegmentOptions.fromJson(data);
  }
}
