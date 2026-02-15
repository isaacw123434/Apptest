import 'dart:convert';
import 'package:flutter/services.dart';
import '../models.dart';
import '../utils/emission_utils.dart';

class ApiService {
  // Simulate network delay
  static const Duration _delay = Duration(milliseconds: 500);

  Future<InitData> _loadRoutes(String? routeId) async {
    String assetPath = 'assets/routes_clean.json';
    if (routeId == 'route2') {
      assetPath = 'assets/routes_2_clean.json';
    }
    final jsonString = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    return InitData.fromJson(jsonData);
  }

  Future<InitData> fetchInitData({String? routeId}) async {
    await Future.delayed(_delay);
    return _loadRoutes(routeId);
  }

  Future<List<JourneyResult>> searchJourneys({
    required String tab,
    required Map<String, bool> selectedModes,
    String? routeId,
  }) async {
    await Future.delayed(_delay);

    final initData = await _loadRoutes(routeId);
    final options = initData.segmentOptions;
    final directDrive = initData.directDrive;

    List<JourneyResult> combos = [];

    // Determine buffer based on routeId
    // Route 1 (Mock 1): Needs 10 min buffer at Leeds (Main Leg transfer)
    // Route 2 (Mock 2): Buffer at start is handled by routes_parser. Buffer at Leeds (end) is not needed.
    int buffer = routeId == 'route2' ? 0 : 10;

    // Generate Combinations
    for (var l1 in options.firstMile) {
      // Fix for Issue 1: Route 2 P&R options already include the last mile walk to destination.
      bool isRoute2PnR = (routeId == 'route2' &&
          (l1.id.contains('p_r') ||
           l1.label.contains('P&R') ||
           l1.label.contains('Stourton') ||
           l1.label.contains('Temple Green') ||
           l1.label.contains('Elland Road')));

      if (isRoute2PnR) {
         // Create a single combination with empty leg3
         Leg emptyLeg3 = Leg(
           id: 'empty_last_mile',
           label: 'Arrived',
           segments: [],
           time: 0,
           cost: 0,
           distance: 0,
           riskScore: 0,
           iconId: IconIds.footprints,
           lineColor: '#000000',
         );

         combos.add(_createJourneyResult(l1, options.mainLeg, emptyLeg3, directDrive, buffer));
         continue; // Skip inner loop
      }

      for (var l3 in options.lastMile) {
        combos.add(_createJourneyResult(l1, options.mainLeg, l3, directDrive, buffer));
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

  JourneyResult _createJourneyResult(Leg l1, Leg mainLeg, Leg l3, DirectDrive directDrive, int buffer) {
        double cost = l1.cost + mainLeg.cost + l3.cost;
        int time = l1.time + buffer + mainLeg.time + l3.time;
        int risk = l1.riskScore + mainLeg.riskScore + l3.riskScore;

        // Calculate Emissions
        // Use pre-calculated CO2 or calculate on fly
        double carEmission = directDrive.co2 ?? calculateEmission(directDrive.distance, IconIds.car);

        double totalEmission = (l1.co2 ?? calculateEmission(l1.distance, l1.iconId)) +
            (mainLeg.co2 ?? calculateEmission(mainLeg.distance, mainLeg.iconId)) +
            (l3.co2 ?? calculateEmission(l3.distance, l3.iconId));

        double savings = carEmission - totalEmission;
        int savingsPercent = 0;
        if (carEmission > 0) {
           savingsPercent = ((savings / carEmission) * 100).round();
        }

        return JourneyResult(
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
        );
  }
}
