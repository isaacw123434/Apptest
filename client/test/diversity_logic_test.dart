import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/utils/route_selector.dart';

// Helper to create JourneyResult
JourneyResult createJourneyResult(String id, String label, int time, double cost, int risk) {
  return JourneyResult(
    id: id,
    leg1: Leg(
      id: 'leg1',
      label: label,
      time: 0, cost: 0, distance: 0, riskScore: 0, iconId: '', lineColor: '', segments: []
    ),
    leg3: Leg(
      id: 'leg3',
      label: 'leg3',
      time: 0, cost: 0, distance: 0, riskScore: 0, iconId: '', lineColor: '', segments: []
    ),
    time: time,
    cost: cost,
    risk: risk,
    buffer: 0,
    emissions: Emissions(val: 0, percent: 0)
  );
}

void main() {
  test('Diversity First, Depth Second Algorithm', () {
    // Setup Mock Data
    final results = [
      createJourneyResult('brough_0700', 'Drive to Brough Station', 65, 10, 0),
      createJourneyResult('brough_0730', 'Drive to Brough Station', 65, 10, 0),
      createJourneyResult('brough_0800', 'Drive to Brough Station', 65, 10, 0),
      createJourneyResult('beverley_0715', 'Drive to Beverley Station', 85, 10, 0),
      createJourneyResult('beverley_0815', 'Drive to Beverley Station', 85, 10, 0),
    ];

    // Call Selector
    final finalResults = RouteSelector.selectJourneys(results, 'fastest');

    // Verification
    expect(finalResults.length, 3);
    expect(finalResults[0].id, 'brough_0700'); // Best Brough
    expect(finalResults[1].id, 'beverley_0715'); // Best Beverley (Alternative)
    expect(finalResults[2].id, 'brough_0730'); // Next Best Brough (Fallback)
  });

  test('Anchor Extraction Case Insensitivity', () {
    final r1 = createJourneyResult('1', 'Drive to Brough Station', 10, 10, 0);
    final r2 = createJourneyResult('2', 'Drive TO Brough STATION', 10, 10, 0);

    expect(r1.anchor, 'Brough');
    expect(r2.anchor, 'Brough');
  });
}
