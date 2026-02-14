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

    final initData = parseRoutesJson(jsonString);

    expect(initData, isNotNull);

    // Validate Main Leg (Train)
    // Generalized logic: 5.00 + 0.30 * distance (90.8 miles) ~= 32.24
    expect(initData.segmentOptions.mainLeg.cost, closeTo(32.24, 1.0));

    // Validate Direct Drive
    // Distance ~90.8 miles. Cost 0.45 * 90.8 = 40.86
    expect(initData.directDrive.cost, closeTo(40.86, 2.0));

    // Validate "Drive" (Group 1) -> Drive & Park
    // Distance ~3.2 miles.
    // Generalized: 0.45 * 3.2 = 1.44.
    // If we assume "Drive" access includes parking, maybe higher?
    // But generalized logic uses pure mileage for 'drive' currently or 5.00 + mileage if 'train' leg access logic applies?
    // Actually Group 1 "Drive" is a Leg object.
    // _estimateCost called with "Drive".
    // My new logic: if (lower.contains('drive')...) return 0.45 * dist.
    // So 1.44.
    final driveLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Drive');
    expect(driveLeg.cost, closeTo(1.44, 0.5));

    // Validate Uber (Group 1) -> Leeds Station
    // Name "Uber". Distance ~3.2 miles.
    // New Logic: 2.50 + 2.00 * 3.2 = 8.9.
    final uberLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLeg.cost, closeTo(8.9, 0.5));

    // Validate Uber (Group 4) -> Loughborough to East Leake
    // Name "Uber". Distance ~4.5 miles.
    // New Logic: 2.50 + 2.00 * 4.5 = 11.5.
    final uberLegLast = initData.segmentOptions.lastMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLegLast.cost, closeTo(11.5, 0.5));

    // Validate Bus (Group 1) -> Line 24
    // Name "Bus". Dist ~2.8 miles (4.4 km).
    // Logic: 2.00 + 0.10 * 2.8 = 2.28.
    final busLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Bus');
    expect(busLeg.cost, closeTo(2.28, 0.5));

    // Validate Bus (Group 4) -> Line 1
    // Name "Bus". Dist ~3.9 miles (6.3 km).
    // Logic: 2.00 + 0.10 * 3.9 = 2.39.
    final busLegLast = initData.segmentOptions.lastMile.firstWhere((leg) => leg.label == 'Bus');
    expect(busLegLast.cost, closeTo(2.39, 0.5));

    // Validate "Uber + Train" (Group 2)
    // Name "Uber + Train".
    // Logic: contains 'train'.
    // trainCost = 5 + 0.3 * distance.
    // contains 'uber' -> trainCost + 8.00 + 4.50 = trainCost + 12.50.
    // Distance? "Uber + Train" leg distance in Group 2.
    // Legs: Uber (0.8 miles) + Train (3.1 miles) + Walk. Total ~ 4 miles.
    // trainCost = 5 + 0.3 * 4 = 6.2.
    // Total = 6.2 + 12.5 = 18.7.
    final uberTrainLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Uber + Train');
    expect(uberTrainLeg.cost, closeTo(18.7, 1.0));

    // Validate "Walk + Train" (Group 2)
    // Name "Walk + Train".
    // Logic: contains 'train'.
    // Not uber, drive, bus.
    // Returns trainCost = 5 + 0.3 * 4 = 6.2.
    final walkTrainLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Walk + Train');
    expect(walkTrainLeg.cost, closeTo(6.2, 0.5));

  });
}
