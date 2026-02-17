import 'dart:convert';
import 'package:flutter/services.dart';
import '../models.dart';

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

    // Filter Modes
    List<JourneyResult> combos = initData.journeys.where((combo) {
      final allSegments = [
        ...combo.leg1.segments,
        ...initData.segmentOptions.mainLeg.segments,
        ...combo.leg3.segments,
      ];

      bool checkSegment(Segment seg) {
        if (seg.subSegments != null && seg.subSegments!.isNotEmpty) {
          return seg.subSegments!.every(checkSegment);
        }
        if (seg.mode == 'walk' || seg.mode == 'wait') return true;
        if (seg.mode == 'taxi') return selectedModes['taxi'] ?? true;
        return selectedModes[seg.mode] ?? true;
      }

      return allSegments.every(checkSegment);
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
