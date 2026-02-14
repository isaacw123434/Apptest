import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/risk_helper.dart';
import 'package:client/models.dart';

void main() {
  test('calculateRiskBreakdown shifts risk for Uber + Train', () {
    // Setup
    final leg1 = Leg(
      id: 'uber_train',
      label: 'Uber to Beverley + Train',
      time: 60,
      cost: 10,
      distance: 10,
      riskScore: 1,
      riskReason: 'Connection risk',
      iconId: 'car',
      lineColor: '#000000',
      segments: [
        Segment(mode: 'car', label: 'Uber', lineColor: '#000000', iconId: 'car', time: 10),
        Segment(mode: 'train', label: 'Train', lineColor: '#000000', iconId: 'train', time: 50),
      ],
    );

    final mainLeg = Leg(
      id: 'main',
      label: 'Main',
      time: 0,
      cost: 0,
      distance: 0,
      riskScore: 0,
      riskReason: null,
      iconId: 'train',
      lineColor: '#000000',
      segments: [],
    );

    final leg3 = Leg(
      id: 'walk',
      label: 'Walk',
      time: 5,
      cost: 0,
      distance: 0.1,
      riskScore: 0,
      riskReason: null,
      iconId: 'footprints',
      lineColor: '#000000',
      segments: [],
    );

    final result = JourneyResult(
      id: 'j1',
      leg1: leg1,
      leg3: leg3,
      cost: 10,
      time: 65,
      buffer: 0,
      risk: 1, // 1 + 0 + 0
      emissions: Emissions(val: 0, percent: 0),
    );

    // Execute
    final breakdown = calculateRiskBreakdown(result, mainLeg, 'route2');

    // Verify
    expect(breakdown.firstMileScore, 0);
    expect(breakdown.firstMileReason, 'Most reliable');
    expect(breakdown.mainLegScore, 1);
    expect(breakdown.mainLegReason, 'Connection risk');
    expect(breakdown.totalScore, 1);
  });

  test('calculateRiskBreakdown splits risk for Bus + Train', () {
    // Setup
    final leg1 = Leg(
      id: 'bus_train',
      label: 'Bus to Brough + Train',
      time: 60,
      cost: 10,
      distance: 10,
      riskScore: 2,
      riskReason: 'Bus risk (+1) + Connection risk (+1)',
      iconId: 'bus',
      lineColor: '#000000',
      segments: [
        Segment(mode: 'bus', label: 'Bus', lineColor: '#000000', iconId: 'bus', time: 20),
        Segment(mode: 'train', label: 'Train', lineColor: '#000000', iconId: 'train', time: 40),
      ],
    );

    final mainLeg = Leg(
      id: 'main',
      label: 'Main',
      time: 0,
      cost: 0,
      distance: 0,
      riskScore: 0,
      riskReason: null,
      iconId: 'train',
      lineColor: '#000000',
      segments: [],
    );

    final leg3 = Leg(
      id: 'walk',
      label: 'Walk',
      time: 5,
      cost: 0,
      distance: 0.1,
      riskScore: 0,
      riskReason: null,
      iconId: 'footprints',
      lineColor: '#000000',
      segments: [],
    );

    final result = JourneyResult(
      id: 'j2',
      leg1: leg1,
      leg3: leg3,
      cost: 10,
      time: 65,
      buffer: 0,
      risk: 2, // 2 + 0 + 0
      emissions: Emissions(val: 0, percent: 0),
    );

    // Execute
    final breakdown = calculateRiskBreakdown(result, mainLeg, 'route2');

    // Verify
    expect(breakdown.firstMileScore, 1);
    expect(breakdown.firstMileReason, 'Bus risk (+1)');
    expect(breakdown.mainLegScore, 1);
    expect(breakdown.mainLegReason, 'Connection risk');
    expect(breakdown.totalScore, 2);
  });

  test('calculateRiskBreakdown does nothing for normal route', () {
      // Setup
      final leg1 = Leg(
        id: 'uber',
        label: 'Uber',
        time: 10,
        cost: 10,
        distance: 2,
        riskScore: 0,
        riskReason: 'Reliable',
        iconId: 'car',
        lineColor: '#000000',
        segments: [
          Segment(mode: 'car', label: 'Uber', lineColor: '#000000', iconId: 'car', time: 10),
        ],
      );

      final mainLeg = Leg(
        id: 'main',
        label: 'Main',
        time: 50,
        cost: 20,
        distance: 50,
        riskScore: 1,
        riskReason: 'Delay risk',
        iconId: 'train',
        lineColor: '#000000',
        segments: [],
      );

      final leg3 = Leg(
        id: 'walk',
        label: 'Walk',
        time: 5,
        cost: 0,
        distance: 0.1,
        riskScore: 0,
        riskReason: null,
        iconId: 'footprints',
        lineColor: '#000000',
        segments: [],
      );

      final result = JourneyResult(
        id: 'j3',
        leg1: leg1,
        leg3: leg3,
        cost: 30,
        time: 65,
        buffer: 0,
        risk: 1, // 0 + 1 + 0
        emissions: Emissions(val: 0, percent: 0),
      );

      // Execute - route1
      final breakdown = calculateRiskBreakdown(result, mainLeg, 'route1');

      // Verify
      expect(breakdown.firstMileScore, 0);
      expect(breakdown.firstMileReason, 'Reliable');
      expect(breakdown.mainLegScore, 1);
      expect(breakdown.mainLegReason, 'Delay risk');
      expect(breakdown.totalScore, 1);
    });
}
