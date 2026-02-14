import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';
import 'package:client/models.dart';

void main() {
  test('Route 2 Data Integrity Test', () {
    final file = File('assets/routes_2.json');
    if (!file.existsSync()) {
      // Fallback for different CWD
      final file2 = File('client/assets/routes_2.json');
      if (file2.existsSync()) {
         print('Using client/assets/routes_2.json');
         // This is just to pass the file read, but the path below depends on it.
         // Actually I'll just read content here.
      } else {
         // Try finding it
         print('Current Directory: ${Directory.current.path}');
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

    // Debugging: Print segments
    print('Segments for ${busToBrough.label}:');
    for (var seg in busToBrough.segments) {
      print(' - ${seg.mode} (${seg.label})');
    }

    // It should have at least one segment that is a bus
    bool hasBus = busToBrough.segments.any((seg) => seg.mode.toLowerCase() == 'bus' || seg.iconId == 'bus');
    expect(hasBus, isTrue, reason: 'Bus to Brough + Train should contain a bus segment');

    // Check "Bus to Beverley + Train"
    final busToBeverley = initData.segmentOptions.firstMile.firstWhere(
      (leg) => leg.label == 'Bus to Beverley + Train',
      orElse: () => throw Exception('Bus to Beverley + Train not found'),
    );

    print('Segments for ${busToBeverley.label}:');
    for (var seg in busToBeverley.segments) {
      print(' - ${seg.mode} (${seg.label})');
    }

    bool hasBusBeverley = busToBeverley.segments.any((seg) => seg.mode.toLowerCase() == 'bus' || seg.iconId == 'bus');
    expect(hasBusBeverley, isTrue, reason: 'Bus to Beverley + Train should contain a bus segment');

    // Check "Bus to York + Train"
    final busToYork = initData.segmentOptions.firstMile.firstWhere(
      (leg) => leg.label == 'Bus to York + Train',
      orElse: () => throw Exception('Bus to York + Train not found'),
    );

    print('Segments for ${busToYork.label}:');
    for (var seg in busToYork.segments) {
      print(' - ${seg.mode} (${seg.label})');
    }

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
