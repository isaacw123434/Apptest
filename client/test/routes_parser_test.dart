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

    // Route 1 Checks

    // Validate Uber (Group 1) -> Leeds Station
    // Name "Uber". Distance ~3.42 miles. User specified 8.97.
    final uberLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLeg.cost, closeTo(8.97, 0.1));

    // Validate Uber (Group 4) -> Loughborough to East Leake
    // Name "Uber". Distance ~4.5 miles. User specified 14.89.
    final uberLegLast = initData.segmentOptions.lastMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLegLast.cost, closeTo(14.89, 0.1));
  });

  test('Parses routes_2.json correctly', () async {
    var file = File('assets/routes_2.json');
    if (!await file.exists()) {
       file = File('client/assets/routes_2.json');
    }

    if (!await file.exists()) {
        // Skip if file doesn't exist (might not be in test env if not committed?)
        // But it was in `ls`.
        fail('Could not find routes_2.json');
    }

    final jsonString = await file.readAsString();
    final initData = parseRoutesJson(jsonString, routeId: 'route2');

    // Route 2 Checks (Access Options)

    // Brough: Uber cost £22.58 + Train £8.10 = £30.68
    final uberBrough = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Uber') && leg.label.contains('Brough'));
    expect(uberBrough.cost, closeTo(30.68, 0.1));

    // York: Uber cost £46.24 + Train £5.20 = £51.44
    final uberYork = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Uber') && leg.label.contains('York'));
    expect(uberYork.cost, closeTo(51.44, 0.1));

    // Beverley: Uber cost £4.62 + Train £12.10 = £16.72
    final uberBeverley = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Uber') && leg.label.contains('Beverley'));
    expect(uberBeverley.cost, closeTo(16.72, 0.1));

    // Hull: Uber cost £20.63 + Train £9.60 = £30.23
    final uberHull = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Uber') && leg.label.contains('Hull'));
    expect(uberHull.cost, closeTo(30.23, 0.1));

    // Eastrington: Uber cost £34.75 + Train £7.00 = £41.75
    final uberEastrington = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label.contains('Uber') && leg.label.contains('Eastrington'));
    expect(uberEastrington.cost, closeTo(41.75, 0.1));
  });
}
