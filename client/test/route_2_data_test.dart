import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';

void main() {
  test('Route 2 Data Integrity Test', () {
    final file = File('assets/routes_2.json');
    if (!file.existsSync()) {
      // Fallback for different CWD
      final file2 = File('client/assets/routes_2.json');
      if (!file2.existsSync()) {
         throw Exception('assets/routes_2.json not found');
      }
    }

    String jsonString;
    try {
        jsonString = file.readAsStringSync();
    } catch (e) {
        jsonString = File('client/assets/routes_2.json').readAsStringSync();
    }

    final initData = parseRoutesJson(jsonString);

    // Check "Bus to Brough + Train"
    final busToBrough = initData.segmentOptions.firstMile.firstWhere(
      (leg) => leg.label == 'Bus to Brough + Train',
      orElse: () => throw Exception('Bus to Brough + Train not found'),
    );

    // It should have at least one segment that is a bus
    bool hasBus = busToBrough.segments.any((seg) => seg.mode.toLowerCase() == 'bus' || seg.iconId == 'bus');
    expect(hasBus, isTrue, reason: 'Bus to Brough + Train should contain a bus segment');

    // Check "Bus to Beverley + Train"
    final busToBeverley = initData.segmentOptions.firstMile.firstWhere(
      (leg) => leg.label == 'Bus to Beverley + Train',
      orElse: () => throw Exception('Bus to Beverley + Train not found'),
    );

    bool hasBusBeverley = busToBeverley.segments.any((seg) => seg.mode.toLowerCase() == 'bus' || seg.iconId == 'bus');
    expect(hasBusBeverley, isTrue, reason: 'Bus to Beverley + Train should contain a bus segment');

    // FIX CHECK: Bus to Beverley should use TRAIN from Beverley.
    bool usesTrainFromBeverley = busToBeverley.segments.any((seg) =>
        (seg.from?.contains('Beverley') ?? false) &&
        seg.mode.toLowerCase() == 'train'
    );
    expect(usesTrainFromBeverley, isTrue, reason: 'Bus to Beverley + Train should use a Train departing from Beverley');


    // Check "Bus to Hull + Train"
    final busToHull = initData.segmentOptions.firstMile.firstWhere(
      (leg) => leg.label == 'Bus to Hull + Train',
      orElse: () => throw Exception('Bus to Hull + Train not found'),
    );

    bool usesBusToHull = busToHull.segments.any((seg) =>
        (seg.to?.contains('Hull') ?? false) &&
        seg.mode.toLowerCase() == 'bus'
    );
    bool hasSubstantialBus = busToHull.segments.any((seg) => seg.mode.toLowerCase() == 'bus' && seg.time > 10);
    expect(usesBusToHull || hasSubstantialBus, isTrue, reason: 'Bus to Hull + Train should use a Bus to Hull');

    // Check "Bus to York + Train"
    final busToYork = initData.segmentOptions.firstMile.firstWhere(
      (leg) => leg.label == 'Bus to York + Train',
      orElse: () => throw Exception('Bus to York + Train not found'),
    );

    bool hasBusYork = busToYork.segments.any((seg) => seg.mode.toLowerCase() == 'bus' || seg.iconId == 'bus');
    expect(hasBusYork, isTrue, reason: 'Bus to York + Train should contain a bus segment');

    // Check Cycle options
    final cycleToBrough = initData.segmentOptions.firstMile.firstWhere(
        (leg) => leg.label == 'Cycle to Brough + Train',
        orElse: () => throw Exception('Cycle to Brough + Train not found'),
    );
    expect(cycleToBrough.segments.any((seg) => seg.mode.toLowerCase() == 'bike' || seg.iconId == 'bike'), isTrue);
  });
}
