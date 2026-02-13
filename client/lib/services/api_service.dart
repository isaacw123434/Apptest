import 'package:flutter/services.dart';
import '../models.dart';
import '../utils/emission_utils.dart';
import '../utils/routes_parser.dart';

class ApiService {
  // Simulate network delay
  static const Duration _delay = Duration(milliseconds: 500);

  Future<InitData> _loadRoutes() async {
    final jsonString = await rootBundle.loadString('assets/routes.json');
    return parseRoutesJson(jsonString);
  }

  Future<InitData> fetchInitData() async {
    await Future.delayed(_delay);
    return _loadRoutes();
  }

  Future<List<JourneyResult>> searchJourneys({
    required String tab,
    required Map<String, bool> selectedModes,
  }) async {
    await Future.delayed(_delay);

    final initData = await _loadRoutes();
    final options = initData.segmentOptions;
    final directDrive = initData.directDrive;

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
        // Use pre-calculated CO2 or calculate on fly
        double carEmission = directDrive.co2 ?? calculateEmission(directDrive.distance, IconIds.car);

        double totalEmission = (l1.co2 ?? calculateEmission(l1.distance, l1.iconId)) +
            (options.mainLeg.co2 ?? calculateEmission(options.mainLeg.distance, options.mainLeg.iconId)) +
            (l3.co2 ?? calculateEmission(l3.distance, l3.iconId));

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

    // Filter Bike Last Mile Restriction
    combos = combos.where((combo) {
      bool isLastMileBike = combo.leg3.id.contains('cycle');
      if (isLastMileBike) {
        String l1 = combo.leg1.id;
        // Allowed:
        // 1. 'cycle' (Cycle Start)
        // 2. 'direct_drive' (Drive and Park - Group 1 Drive)
        // 3. 'train_cycle_headingley' (Cycle + Train via Headingley)
        bool isCycleStart = l1 == 'cycle';
        bool isDrivePark = l1 == 'direct_drive' || l1 == 'drive_park';
        bool isHeadingleyCycle = l1 == 'train_cycle_headingley';

        return isCycleStart || isDrivePark || isHeadingleyCycle;
      }
      return true;
    }).toList();

    // Sort based on Tab
    if (tab == 'fastest') {
      combos.sort((a, b) => a.time.compareTo(b.time));
    } else if (tab == 'cheapest') {
      combos.sort((a, b) => a.cost.compareTo(b.cost));
    } else {
      // Smart: Cost + 0.3 * Time + 20 * (Risk - MinRisk)
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
}
