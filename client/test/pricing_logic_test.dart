import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/utils/routes_parser.dart';

void main() {
  test('Pricing verification for default route (no overrides)', () async {
    var file = File('client/assets/routes.json');
    if (!await file.exists()) {
       file = File('assets/routes.json');
    }
    final jsonString = await file.readAsString();

    final initData = parseRoutesJson(jsonString);

    // Check Group 1 (Access to Leeds Station) - Drive
    final driveLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Drive');
    // Drive cost should be around 1.54 (0.45 * miles)
    expect(driveLeg.cost, closeTo(1.54, 0.1));

    // Check Group 1 - Uber
    // Previously 0.0, now should be around 1.20 * miles
    // Distance is same as Drive ~3.4 miles. 1.20 * 3.4 = 4.08
    final uberLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLeg.cost, greaterThan(0.0));
    expect(uberLeg.cost, closeTo(4.10, 0.1));

    // Check Group 3 - Train (Main Leg)
    // Previously 0.0, now should be around 0.30 * miles
    // Distance ~90 miles?
    // In reproduction test it was 27.24.
    expect(initData.segmentOptions.mainLeg.cost, greaterThan(0.0));
    expect(initData.segmentOptions.mainLeg.cost, closeTo(27.24, 0.5));
  });

  test('Pricing logic with Brough location from Group Name', () async {
    var file = File('client/assets/routes.json');
    if (!await file.exists()) {
       file = File('assets/routes.json');
    }
    final jsonString = await file.readAsString();

    // Modify the JSON to simulate Access to Brough
    Map<String, dynamic> data = jsonDecode(jsonString);
    var groups = data['groups'] as List;
    var group1 = groups.firstWhere((g) => g['name'].contains('Group 1'));
    group1['name'] = 'Group 1: Access to Brough Station';

    final modifiedJson = jsonEncode(data);

    final initData = parseRoutesJson(modifiedJson);

    // Check Uber Cost for Brough
    // Pricing for brough uber is 22.58 (Fixed price in pricing map)
    final uberLeg = initData.segmentOptions.firstMile.firstWhere((leg) => leg.label == 'Uber');
    expect(uberLeg.cost, equals(22.58));
  });
}
