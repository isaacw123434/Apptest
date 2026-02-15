import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';
import 'package:latlong2/latlong.dart';

class MockApiService extends ApiService {
  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    return InitData(
      segmentOptions: SegmentOptions(
        firstMile: [],
        mainLeg: Leg(
          id: 'main',
          label: 'Main',
          time: 10,
          cost: 10,
          distance: 10,
          riskScore: 0,
          iconId: 'train',
          lineColor: '#000000',
          segments: [],
        ),
        lastMile: [],
      ),
      directDrive: DirectDrive(time: 100, cost: 50, distance: 100),
      mockPath: [],
    );
  }
}

void main() {
  testWidgets('DetailPage shows Free for 0 parking cost', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = MockApiService();

    // drivingCost = distance * 0.45
    // 10 miles * 0.45 = 4.5
    // If total cost is 4.5, then parking cost is 0.
    final driveSegment = Segment(
      mode: 'car',
      label: 'Drive', // Triggers isDriveToStation
      lineColor: '#000000',
      iconId: 'car',
      time: 20,
      cost: 4.5,
      distance: 10.0,
      path: [LatLng(0, 0), LatLng(0.1, 0.1)],
    );

    final leg1 = Leg(
      id: 'leg1',
      label: 'Drive to Station',
      time: 20,
      cost: 4.5,
      distance: 10.0,
      riskScore: 0,
      iconId: 'car',
      lineColor: '#000000',
      segments: [driveSegment],
    );

     final leg3 = Leg(
      id: 'leg3',
      label: 'Last',
      time: 5,
      cost: 2,
      distance: 1,
      riskScore: 0,
      iconId: 'bus',
      lineColor: '#000000',
      segments: [],
    );

    final result = JourneyResult(
      id: 'result',
      leg1: leg1,
      leg3: leg3,
      cost: 10,
      time: 50,
      buffer: 10,
      risk: 0,
      emissions: Emissions(val: 0, percent: 0),
    );

    await tester.pumpWidget(MaterialApp(
      home: DetailPage(
        journeyResult: result,
        apiService: mockApiService,
      ),
    ));

    await tester.pumpAndSettle();

    // We expect "Parking cost (24 hours): Free"
    expect(find.textContaining('Parking cost (24 hours): Free'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 1));
  });
}
