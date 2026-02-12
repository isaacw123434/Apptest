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

    // Validate SegmentOptions
    expect(initData.segmentOptions, isNotNull);
    expect(initData.segmentOptions.firstMile, isNotEmpty);
    expect(initData.segmentOptions.mainLeg, isNotNull);
    expect(initData.segmentOptions.lastMile, isNotEmpty);

    // Group 1 (4 options) + Group 2 (2 options) = 6 options
    expect(initData.segmentOptions.firstMile.length, 6);

    // Validate Bus option in firstMile
    // Find leg with label "Bus"
    final busLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Bus');
    expect(busLeg, isNotNull);
    // Bus option has 3 legs in JSON: Walk, Transit (Bus), Walk.
    expect(busLeg.segments.length, 3);
    // Check modes
    // Note: parser logic maps "walking" -> "walk", "transit" (BUS) -> "bus"
    expect(busLeg.segments[0].mode, anyOf('walk', 'walking'));
    expect(busLeg.segments[1].mode, 'bus');
    expect(busLeg.segments[2].mode, anyOf('walk', 'walking'));

    // Validate Main Leg
    // Group 3 -> Option "Train" -> Legs: Walk, Transit (CrossCountry), Walk, Transit (EMR).
    expect(initData.segmentOptions.mainLeg.segments.length, 4);
    expect(initData.segmentOptions.mainLeg.segments[1].mode, 'train');
    expect(initData.segmentOptions.mainLeg.segments[3].mode, 'train');

    // Validate Direct Drive
    expect(initData.directDrive, isNotNull);
    // Distance in miles. 87.31 in mock.
    // JSON direct drive has many legs. Sum them up.
    // Total distance should be reasonable.
    expect(initData.directDrive.distance, greaterThan(50));
    expect(initData.mockPath, isNotEmpty);
    expect(initData.mockPath.length, greaterThan(10)); // Should have many points
  });
}
