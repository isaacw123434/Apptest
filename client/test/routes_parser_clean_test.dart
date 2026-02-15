import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';
import 'package:client/models.dart';

void main() {
  test('Routes Parser cleans short walks', () {
    // Mock JSON with short walks
    final json = '''
    {
      "groups": [
        {
          "name": "Group 1: Test",
          "options": [
            {
              "name": "Short Walk Test",
              "legs": [
                {
                  "mode": "walking",
                  "duration_value": 60,
                  "distance_value": 100,
                  "polyline": ""
                },
                {
                  "mode": "walking",
                  "duration_value": 180,
                  "distance_value": 300,
                  "polyline": ""
                }
              ]
            },
            {
              "name": "Long Walk Test",
              "legs": [
                {
                  "mode": "walking",
                  "duration_value": 400,
                  "distance_value": 500,
                  "polyline": ""
                }
              ]
            }
          ]
        },
        {
          "name": "Group 3: Main",
          "options": [
            {
              "name": "Train Test",
              "legs": [
                {
                  "mode": "transit",
                  "duration_value": 600,
                  "distance_value": 1000,
                  "polyline": "",
                  "transit_details": { "vehicle_type": "TRAIN" }
                },
                {
                  "mode": "walking",
                  "duration_value": 240,
                  "distance_value": 400,
                  "polyline": ""
                },
                {
                  "mode": "transit",
                  "duration_value": 600,
                  "distance_value": 1000,
                  "polyline": "",
                  "transit_details": { "vehicle_type": "TRAIN" }
                }
              ]
            }
          ]
        }
      ]
    }
    ''';

    final initData = parseRoutesJson(json);

    // "Short Walk Test" (Group 1)
    // Walk 1m + Walk 3m = Walk 4m.
    // It is First Mile. It is last segment. 4 <= 5.
    // Heuristic removes it.
    final shortWalkLeg = initData.segmentOptions.firstMile.firstWhere((l) => l.label == 'Short Walk Test');
    expect(shortWalkLeg.segments.length, 0);

    // "Long Walk Test" (Group 1)
    // Walk 6.6 mins (400s).
    // > 5 mins. Should be kept.
    final longWalkLeg = initData.segmentOptions.firstMile.firstWhere((l) => l.label == 'Long Walk Test');
    expect(longWalkLeg.segments.length, 1);
    expect(longWalkLeg.segments.first.time, 7); // 400/60 rounded

    // Group 3:
    // Train 10 mins
    // Walk 4 mins (240s) -> "Between trains". 4 <= 5. Should be removed.
    // Train 10 mins

    final mainLeg = initData.segmentOptions.mainLeg;
    // Should have 2 segments (Train, Train).
    expect(mainLeg.segments.length, 2);
    expect(mainLeg.segments[0].iconId, IconIds.train);
    expect(mainLeg.segments[1].iconId, IconIds.train);
  });

  test('Routes Parser cleans leg boundary walks', () {
     final json = '''
    {
      "groups": [
        {
          "name": "Group 1: Test",
          "options": [
            {
              "name": "Boundary Test",
              "legs": [
                {
                  "mode": "bicycling",
                  "duration_value": 600,
                  "distance_value": 2000,
                  "polyline": ""
                },
                {
                  "mode": "walking",
                  "duration_value": 240,
                  "distance_value": 400,
                  "polyline": ""
                }
              ]
            }
          ]
        }
      ]
    }
    ''';

    final initData = parseRoutesJson(json);
    final firstMile = initData.segmentOptions.firstMile.first;

    // Bike 10 mins.
    // Walk 4 mins.
    // Group 1 "First Mile". Ends with Walk 4 mins.
    // Heuristic: remove it.

    expect(firstMile.segments.length, 1);
    expect(firstMile.segments.first.iconId, IconIds.bike);
  });
}
