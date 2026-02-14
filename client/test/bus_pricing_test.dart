import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';

void main() {
  test('Bus pricing logic correct for X1, X46, PRx and others', () {
    String createJson(String lineName) {
      return '''
      {
        "groups": [
          {
            "name": "Test Group",
            "options": [
              {
                "name": "Bus Option",
                "legs": [
                  {
                    "mode": "transit",
                    "distance_value": 1000,
                    "duration_value": 600,
                    "polyline": "encoded_polyline",
                    "transit_details": {
                      "line_name": "$lineName",
                      "vehicle_type": "BUS",
                      "line": {
                        "short_name": "$lineName"
                      }
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
      ''';
    }

    void verifyCost(String lineName, double expectedCost) {
      final json = createJson(lineName);
      final initData = parseRoutesJson(json);
      final option = initData.segmentOptions.firstMile.first; // Or check where it ends up.

      // Since there is only one group, it goes to firstMile by default logic?
      // Group logic: "Group 1" or "Group 2" -> firstMile.
      // "Group 3" -> mainLeg.
      // "Group 4" -> lastMile.
      // My createJson uses "Test Group".
      // routes_parser.dart logic:
      /*
        if (name.contains('Group 1') || name.contains('Group 2')) { ... }
        else if (name.contains('Group 3')) { ... }
        else if (name.contains('Group 4')) { ... }
        else if (name.contains('Group 5')) { ... }
      */
      // It seems it requires specific Group names.
      // I should name the group "Group 1: Test" so it goes to firstMile.
    }

    String createJsonGroup1(String lineName) {
      return '''
      {
        "groups": [
          {
            "name": "Group 1: Test",
            "options": [
              {
                "name": "Bus Option",
                "legs": [
                  {
                    "mode": "transit",
                    "distance_value": 1000,
                    "duration_value": 600,
                    "polyline": "abc",
                    "transit_details": {
                      "line_name": "$lineName",
                      "vehicle_type": "BUS",
                      "line": {
                        "short_name": "$lineName"
                      }
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
      ''';
    }

    void verify(String lineName, double expected) {
      final json = createJsonGroup1(lineName);
      final initData = parseRoutesJson(json);
      // firstMile should have one leg
      expect(initData.segmentOptions.firstMile.length, 1, reason: 'Should have 1 option for $lineName');
      final leg = initData.segmentOptions.firstMile.first;
      // Leg cost is sum of segments.
      expect(leg.cost, closeTo(expected, 0.01), reason: 'Cost for $lineName should be $expected');
    }

    verify("24", 2.00);
    verify("1", 2.00);
    verify("10", 2.00);

    verify("X1", 3.00);
    verify("x1", 3.00);
    verify("X46", 3.00);
    verify("x46", 3.00);

    verify("PR1", 5.00);
    verify("PR2", 5.00);
    verify("PR3 Park & Ride", 5.00);
    verify("pr1", 5.00);

    // Edge cases
    verify("Bus X1", 3.00); // Should match \bx1\b
    verify("Bus 24", 2.00);
  });
}
