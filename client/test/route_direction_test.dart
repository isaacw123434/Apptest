// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Route Direction Tests', () {
    test('Check Eastrington routes do not go backwards to Brough', () {
      var file = File('assets/routes_2.json');
      if (!file.existsSync()) {
        file = File('client/assets/routes_2.json');
        if (!file.existsSync()) {
             fail('assets/routes_2.json not found in current directory or client/ directory. CWD: ${Directory.current.path}');
        }
      }

      final jsonString = file.readAsStringSync();
      final initData = parseRoutesJson(jsonString);

      // Find options involving Eastrington
      final eastringtonOptions = initData.segmentOptions.firstMile.where(
        (leg) => leg.label.toLowerCase().contains('eastrington')
      ).toList();

      expect(eastringtonOptions, isNotEmpty, reason: 'No Eastrington options found');

      for (var option in eastringtonOptions) {
        print('Checking route: ${option.label}');

        List<LatLng> fullPath = [];
        for (var seg in option.segments) {
          if (seg.path != null) {
            fullPath.addAll(seg.path!);
          }
        }

        // Check for the zig-zag pattern: West -> East -> West
        // Beverley (~ -0.42) -> Eastrington (~ -0.78) -> Brough (~ -0.57) -> Leeds (~ -1.54)

        bool reachedEastrington = false;
        bool wentBackToBrough = false;

        for (var point in fullPath) {
          // Check if we are near Eastrington (approx -0.78)
          // Let's say if longitude < -0.75
          if (point.longitude < -0.75) {
            reachedEastrington = true;
          }

          // If we reached Eastrington, check if we go back East towards Brough (-0.57)
          // Let's say if longitude > -0.60
          if (reachedEastrington && point.longitude > -0.60) {
            wentBackToBrough = true;
            break;
          }
        }

        if (wentBackToBrough) {
             fail('Route ${option.label} goes backwards to Brough (East) after reaching Eastrington.');
        }
      }
    });

    test('Check routes.json for similar issues (sanity check)', () {
       var file = File('assets/routes.json');
       if (!file.existsSync()) {
         file = File('client/assets/routes.json');
         if (!file.existsSync()) {
            return; // Optional
         }
       }
       final jsonString = file.readAsStringSync();
       final initData = parseRoutesJson(jsonString);

       // Just ensuring no errors in parsing
       expect(initData.segmentOptions.firstMile, isNotNull);
    });
  });
}
