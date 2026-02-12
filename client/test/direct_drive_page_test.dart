import 'package:client/screens/direct_drive_page.dart';
import 'package:client/services/api_service.dart';
import 'package:client/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class MockApiService extends ApiService {
  @override
  Future<InitData> fetchInitData() async {
    return InitData(
      segmentOptions: SegmentOptions(firstMile: [], mainLeg: Leg(id: 'main', label: 'main', segments: [], time: 0, cost: 0, distance: 0, riskScore: 0, iconId: IconIds.train, lineColor: ''), lastMile: []),
      directDrive: DirectDrive(
        time: 110,
        cost: 39.15,
        distance: 87.31,
        co2: 23.89,
      ),
      mockPath: [LatLng(0, 0), LatLng(1, 1)],
    );
  }
}

void main() {
  testWidgets('DirectDrivePage renders info boxes without overflow on narrow screen', (WidgetTester tester) async {
    // Set screen size to narrow width (e.g. 320 logical pixels)
    tester.view.physicalSize = const Size(320 * 3, 800 * 3); // 3x pixel ratio
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(MaterialApp(
      home: DirectDrivePage(apiService: MockApiService()),
    ));

    // Pump to allow FutureBuilder/setState to settle
    await tester.pumpAndSettle();

    // Verify that the info boxes are present
    expect(find.text('COST'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('DISTANCE'), findsOneWidget);
    expect(find.text('CO₂'), findsOneWidget);

    // Verify that the value texts are present
    expect(find.text('£39.15'), findsOneWidget);
    expect(find.text('1hr 50m'), findsOneWidget);
    expect(find.text('87.31 mi'), findsOneWidget);
    expect(find.text('23.89 kg'), findsOneWidget);

    // Check for overflow errors

    // Reset window size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
