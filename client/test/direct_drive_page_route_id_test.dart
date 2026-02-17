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
      journeys: [],
      segmentOptions: SegmentOptions(
        firstMile: [],
        mainLeg: Leg(
          id: 'main',
          label: 'main',
          segments: [],
          time: 0,
          cost: 0,
          distance: 0,
          riskScore: 0,
          iconId: IconIds.train,
          lineColor: '',
        ),
        lastMile: [],
      ),
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
  testWidgets('DirectDrivePage passes routeId to ApiService', (
    WidgetTester tester,
  ) async {
    final mockApiService = MockApiService();

    // Verify default behavior (null routeId)
    await tester.pumpWidget(
      MaterialApp(home: DirectDrivePage(apiService: mockApiService)),
    );
    await tester.pumpAndSettle();
    expect(mockApiService.lastRouteId, null);

    await tester.pumpWidget(const SizedBox());

    // Verify with routeId
    final mockApiService2 = MockApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: DirectDrivePage(apiService: mockApiService2, routeId: 'route2'),
      ),
    );
    await tester.pumpAndSettle();
    expect(mockApiService2.lastRouteId, 'route2');
  });
}
