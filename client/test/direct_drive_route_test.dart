import 'package:client/screens/direct_drive_page.dart';
import 'package:client/services/api_service.dart';
import 'package:client/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class MockApiService extends ApiService {
  String? lastRouteId;

  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    lastRouteId = routeId;
    return InitData(
      segmentOptions: SegmentOptions(
        firstMile: [],
        mainLeg: Leg(
          id: 'main',
          label: 'main',
          time: 0,
          cost: 0,
          distance: 0,
          riskScore: 0,
          iconId: IconIds.train,
          lineColor: '',
          segments: [],
        ),
        lastMile: [],
      ),
      directDrive: DirectDrive(
        time: 100,
        cost: 10.0,
        distance: 20.0,
      ),
      mockPath: [LatLng(0, 0), LatLng(1, 1)],
    );
  }
}

void main() {
  testWidgets('DirectDrivePage passes routeId to ApiService', (WidgetTester tester) async {
    final mockApiService = MockApiService();
    const testRouteId = 'route2';

    // Verify initial state
    expect(mockApiService.lastRouteId, isNull);

    await tester.pumpWidget(MaterialApp(
      home: DirectDrivePage(
        apiService: mockApiService,
        routeId: testRouteId,
      ),
    ));

    // Trigger frame
    await tester.pumpAndSettle();

    // Verify
    expect(mockApiService.lastRouteId, equals(testRouteId));
  });
}
