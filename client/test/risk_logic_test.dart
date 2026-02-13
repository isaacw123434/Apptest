import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';

void main() {
  test('Parses routes.json and verifies risk logic', () async {
    // Attempt to locate the file whether running from root or client/
    var file = File('assets/routes.json');
    if (!await file.exists()) {
       file = File('client/assets/routes.json');
    }

    if (!await file.exists()) {
        fail('Could not find routes.json');
    }

    final jsonString = await file.readAsString();

    final initData = parseRoutesJson(jsonString);

    expect(initData, isNotNull);

    // Group 1 (Leeds First Mile)
    // Cycle: Score 1, Reason: "Weather dependent, fitness required"
    final cycleLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Cycle'));
    expect(cycleLeg.riskScore, 1);
    expect(cycleLeg.riskReason, 'Weather dependent, fitness required');

    // Bus: Score 0, Reason: "Frequent, reliable"
    final busLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Bus'));
    expect(busLeg.riskScore, 0);
    expect(busLeg.riskReason, 'Frequent, reliable');

    // Uber: Score 0, Reason: "Most reliable"
    final uberLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Uber') && !leg.label.contains('Train'));
    expect(uberLeg.riskScore, 0);
    expect(uberLeg.riskReason, 'Most reliable');

    // Drive: Score 0, Reason: "Most reliable"
    final driveLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Drive'));
    expect(driveLeg.riskScore, 0);
    expect(driveLeg.riskReason, 'Most reliable');

    // Group 2 (Headingley First Mile)
    // Walk + Train: Score 2, Reason: "Timing risk (+1) + Connection risk (+1)"
    final walkTrainLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Walk + Train'));
    expect(walkTrainLeg.riskScore, 2);
    expect(walkTrainLeg.riskReason, 'Timing risk (+1) + Connection risk (+1)');

    // Uber + Train: Score 1, Reason: "Connection risk"
    final uberTrainLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Uber + Train'));
    expect(uberTrainLeg.riskScore, 1);
    expect(uberTrainLeg.riskReason, 'Connection risk');

    // Group 3 (Core Journey)
    // Train: Score 1, Reason: "Delay/timing risk"
    final mainLeg = initData.segmentOptions.mainLeg;
    expect(mainLeg.riskScore, 1);
    expect(mainLeg.riskReason, 'Delay/timing risk');

    // Group 4 (Final Mile)
    // Bus: Score 2, Reason: "Unfamiliar area, less frequent"
    final busLegLast = initData.segmentOptions.lastMile.firstWhere((leg) => leg.label.contains('Bus'));
    expect(busLegLast.riskScore, 2);
    expect(busLegLast.riskReason, 'Unfamiliar area, less frequent');

    // Uber: Score 0, Reason: "Most reliable"
    final uberLegLast = initData.segmentOptions.lastMile.firstWhere((leg) => leg.label.contains('Uber'));
    expect(uberLegLast.riskScore, 0);
    expect(uberLegLast.riskReason, 'Most reliable');

    // Cycle: Score 1, Reason: "Weather dependent, fitness required"
    final cycleLegLast = initData.segmentOptions.lastMile.firstWhere((leg) => leg.label.contains('Cycle'));
    expect(cycleLegLast.riskScore, 1);
    expect(cycleLegLast.riskReason, 'Weather dependent, fitness required');

  });
}
