import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';

void main() {
  test('Regression Test: Route 1 pricing correct with routeId, 0 if null', () async {
    // Load routes.json (Route 1 data)
    var file = File('client/assets/routes.json');
    if (!await file.exists()) {
       file = File('assets/routes.json');
    }
    final jsonString = await file.readAsString();

    // 1. Parse with routeId = null (Current behavior in HomePage for Route 1)
    final initDataNull = parseRoutesJson(jsonString, routeId: null);

    // Verify Uber (Group 1) cost is 0
    final uberLegNull = initDataNull.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLegNull.cost, equals(0.0), reason: "Uber cost should be 0 when routeId is null");

    // Verify Main Leg (Train) cost is 0
    expect(initDataNull.segmentOptions.mainLeg.cost, equals(0.0), reason: "Train cost should be 0 when routeId is null");


    // 2. Parse with routeId = 'route1' (Expected fix)
    final initDataRoute1 = parseRoutesJson(jsonString, routeId: 'route1');

    // Verify Uber (Group 1) cost is correct
    final uberLegRoute1 = initDataRoute1.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLegRoute1.cost, closeTo(8.97, 0.01), reason: "Uber cost should be 8.97 when routeId is 'route1'");

    // Verify Main Leg (Train) cost is correct
    expect(initDataRoute1.segmentOptions.mainLeg.cost, closeTo(25.70, 0.01), reason: "Train cost should be 25.70 when routeId is 'route1'");
  });
}
