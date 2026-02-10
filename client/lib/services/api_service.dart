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
      (r) => r['name'] == 'Direct Drive: St Chads View to East Leake',
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
      // Smart: Cost + 0.3 * Time
      combos.sort((a, b) {
        double scoreA = a.cost + (a.time * 0.3);
        double scoreB = b.cost + (b.time * 0.3);
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

    // Helper to attach path
    void attachPath(Map<String, dynamic> leg, String? routeNameOverride) {
      String? routeName;
      if (routeNameOverride != null) {
        routeName = routeNameOverride;
      } else {
        String id = leg['id'];
        if (id == 'uber') {
          routeName = routesMap['uber'];
        } else if (id == 'bus') {
          routeName = routesMap['bus'];
        } else if (id == 'cycle') {
          routeName = routesMap['cycle'];
        } else if (id == 'train_walk_headingley') {
          routeName = routesMap['train_walk_headingley'];
        } else if (id == 'train_main') {
          routeName = routesMap['train_main'];
        } else if (id == 'drive_park') {
          routeName = routesMap['uber'];
        } else if (id == 'train_uber_headingley') {
          routeName = routesMap['train_walk_headingley'];
        }
      }

      if (routeName != null) {
        final route = rawRoutesData.firstWhere(
          (r) => r['name'] == routeName,
          orElse: () => {},
        );
        if (route.isNotEmpty && route['polyline'] != null) {
          List<LatLng> points = decodePolyline(route['polyline']);
          // Inject into segments
          if (leg['segments'] != null) {
             List segments = leg['segments'] as List;
             leg['segments'] = segments.map((s) {
               var sMap = Map<String, dynamic>.from(s);

               // Logic to decide if we should attach path to this segment
               String mode = sMap['mode'] ?? '';
               String routeNameLower = routeName!.toLowerCase();
               bool shouldAttach = false;

               if (routeNameLower.contains('train') && mode == 'train') {
                 shouldAttach = true;
               } else if ((routeNameLower.contains('drive') || routeNameLower.contains('uber')) && (mode == 'car' || mode == 'taxi')) {
                 shouldAttach = true;
               } else if (routeNameLower.contains('bus') && mode == 'bus') {
                 shouldAttach = true;
               } else if (routeNameLower.contains('cycle') && mode == 'bike') {
                 shouldAttach = true;
               } else if (routeNameLower.contains('direct drive') && mode == 'car') {
                 shouldAttach = true;
               }

               if (shouldAttach) {
                 sMap['path'] = points;
               }
               return sMap;
             }).toList();
          }
        }
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
        String? routeName;
        String id = leg['id'];
        if (id == 'uber') {
          routeName = routesMap['last_uber'];
        } else if (id == 'bus') {
          routeName = routesMap['last_bus'];
        } else if (id == 'cycle') {
          routeName = routesMap['last_cycle'];
        }

        attachPath(leg, routeName);
    }

    return SegmentOptions.fromJson(data);
  }
}
