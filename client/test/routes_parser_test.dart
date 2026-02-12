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

    // Group 3 -> Option "Train" -> Legs: Walk, Transit (CrossCountry), Walk, Transit (EMR).
    // Short walk between trains should be removed. So 3 segments.
    expect(initData.segmentOptions.mainLeg.segments.length, 3);

    // Verify Cost calculation for Main Leg (Train)
    // Distance is ~90.88 miles.
    // Price should be forced to 25.70
    expect(initData.segmentOptions.mainLeg.cost, 25.70);

    // Validate Drive option merging and labeling
    final driveLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Drive');
    // Should be merged into 1 segment
    expect(driveLeg.segments.length, 1);
    expect(driveLeg.segments[0].mode, 'car');
    expect(driveLeg.segments[0].label, 'Drive');

    // Drive cost ~3.2 miles * 0.45 + 15.00 (parking) = ~16.44
    // Wait, the 'Drive' option in Group 1 is 'Drive' not 'Drive & Park' in name.
    // Let's check logic. _estimateCost checks if name contains 'park'.
    // In routes.json, name is "Drive".
    // So cost is 3.22 * 0.45 = ~1.45.
    // The user asked to use 45p/mile for "driving costs".
    // If it's "Drive" it means driving yourself? Or Drive & Park?
    // In mock_data, there is a 'drive_park' option.
    // Let's assume 'Drive' in Group 1 implies driving to station -> parking.
    // But the name in JSON is just "Drive".
    // If parking is involved, maybe it's not handled in JSON name.
    // But if we stick to 45p/mile, it's cheap.
    // Let's just verify it uses 0.45 * dist.
    expect(driveLeg.cost, closeTo(3.22 * 0.45, 0.5));

    // Validate Uber option
    final uberLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLeg.segments.length, 1);
    expect(uberLeg.segments[0].label, 'Uber'); // Should be "Uber"
    expect(uberLeg.segments[0].lineColor, '#000000'); // Black

    // Validate Direct Drive
    expect(initData.directDrive, isNotNull);
    // 87.31 miles * 0.45 = ~39.29
    expect(initData.directDrive.cost, closeTo(87.31 * 0.45, 1.0));
  });
}
