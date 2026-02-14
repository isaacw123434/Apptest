import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';

void main() {
  test('Parses routes.json correctly', () async {
    // Attempt to locate the file whether running from root or client/
    var file = File('assets/routes.json');
    if (!await file.exists()) {
       file = File('client/assets/routes.json');
    }

    if (!await file.exists()) {
        fail('Could not find routes.json');
    }

    final jsonString = await file.readAsString();

    // Use route1 to verify overridden prices as formulas are removed
    final initData = parseRoutesJson(jsonString, routeId: 'route1');

    expect(initData, isNotNull);

    // Validate Main Leg (Train)
    // Override: 25.70
    expect(initData.segmentOptions.mainLeg.cost, closeTo(25.70, 0.1));

    // Validate Direct Drive
    // Distance ~90.8 miles. Cost 0.45 * 90.8 = 40.86
    expect(initData.directDrive.cost, closeTo(40.86, 2.0));

    // Validate "Drive" (Group 1) -> Drive & Park
    // Distance ~3.2 miles. Cost 0.45 * 3.2 = 1.44. PLUS Parking 23.00 (Route 1 Override)
    final driveLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Drive');
    expect(driveLeg.cost, closeTo(24.44, 0.5));

    // Validate Uber (Group 1) -> Leeds Station
    // Override: 8.97
    final uberLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLeg.cost, closeTo(8.97, 0.1));

    // Validate Uber (Group 4) -> Loughborough to East Leake
    // Override: 14.89
    final uberLegLast = initData.segmentOptions.lastMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLegLast.cost, closeTo(14.89, 0.1));

    // Validate Bus (Group 1) -> Line 24
    // Override: 2.00
    final busLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Bus');
    expect(busLeg.cost, closeTo(2.00, 0.1));

    // Validate Bus (Group 4) -> Line 1
    // Override: 2.00 (Updated rule: anything else is £2)
    final busLegLast = initData.segmentOptions.lastMile.firstWhere((leg) => leg.label == 'Bus');
    expect(busLegLast.cost, closeTo(2.00, 0.1));

    // Validate "Uber + Train" (Group 2)
    // Override: Uber 5.92 + Train 3.40 = 9.32
    final uberTrainLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Uber + Train');
    expect(uberTrainLeg.cost, closeTo(9.32, 0.1));

    // Validate "Walk + Train" (Group 2)
    // Override: 3.40
    final walkTrainLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Walk + Train');
    expect(walkTrainLeg.cost, closeTo(3.40, 0.1));

  });
}
