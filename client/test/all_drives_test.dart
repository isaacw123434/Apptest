import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';

void main() {
  test('Check all Drive options in routes.json and routes_2.json', () async {
    final files = ['assets/routes.json', 'assets/routes_2.json'];

    for (var filePath in files) {
      print('Processing $filePath...');
      final file = File(filePath);
      if (!await file.exists()) {
        fail('File not found: $filePath. Run this test from the client/ directory.');
      }

      final jsonString = await file.readAsString();
      // Assume routeId based on filename
      final routeId = filePath.contains('routes_2.json') ? 'route2' : 'route1';
      final initData = parseRoutesJson(jsonString, routeId: routeId);

      print('  Direct Drive (Group 5):');
      final dd = initData.directDrive;
      print('    Distance: ${dd.distance} miles');
      print('    Cost: £${dd.cost.toStringAsFixed(2)}');
      print('    Time: ${dd.time} mins');

      // Verify Direct Drive cost logic (0.45 * distance)
      // Allow a small margin for float arithmetic or rounding differences
      // 28.80 / 0.45 = 64.0. If distance is 52.9, cost should be ~23.80.
      final expectedCost = dd.distance * 0.45;
      if ((dd.cost - expectedCost).abs() > 0.1) {
        print('    [WARNING] Direct Drive cost mismatch! Expected: £${expectedCost.toStringAsFixed(2)}, Actual: £${dd.cost.toStringAsFixed(2)}');
      } else {
        print('    [OK] Cost matches 0.45 * distance.');
      }

      print('  First Mile Options (containing "Drive" or "Car" or "P&R"):');
      for (var leg in initData.segmentOptions.firstMile) {
        if (leg.label.contains('Drive') || leg.label.contains('Car') || leg.label.contains('Uber') || leg.label.contains('P&R')) {
           print('    Option: "${leg.label}"');
           print('      Total Distance: ${leg.distance} miles');
           print('      Total Cost: £${leg.cost.toStringAsFixed(2)}');
           print('      Total Time: ${leg.time} mins');

           double calculatedCarCost = 0.0;
           double parkingCost = 0.0;
           double carDistance = 0.0;

           for (var seg in leg.segments) {
             if (seg.mode == 'car') {
               print('      - Segment Car: ${seg.distance} miles, Cost: £${seg.cost.toStringAsFixed(2)}');
               carDistance += seg.distance ?? 0;
               calculatedCarCost += seg.cost;
             }
             if (seg.mode == 'parking') {
               print('      - Segment Parking: Cost: £${seg.cost.toStringAsFixed(2)}');
               parkingCost += seg.cost;
             }
           }

           // Verify if this option matches the user's issue (28.80 cost)
           if ((leg.cost - 28.80).abs() < 0.1) {
             print('      *** MATCHES USER ISSUE COST (£28.80) ***');
             if ((carDistance - 52.9).abs() < 0.1) {
                print('      *** MATCHES USER ISSUE DISTANCE (52.9 miles) ***');
             }
           }
        }
      }
      print('--------------------------------------------------');
    }
  });
}
