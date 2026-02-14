import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';

void main() {
  test('Bus pricing logic correct for X1, X46, PRx and others', () {

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
