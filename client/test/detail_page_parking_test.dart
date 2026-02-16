import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';
import 'package:latlong2/latlong.dart';

class MockApiService extends ApiService {
  final double distance;
  final double totalCost;

  MockApiService({required this.distance, required this.totalCost});

  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    final driveSegment = Segment(
      mode: 'car',
      label: 'Drive',
      lineColor: '#000000',
      iconId: 'car',
      time: 10,
      path: <LatLng>[],
      cost: totalCost,
      distance: distance,
    );

    final firstMile = Leg(
        id: 'first',
        label: 'First',
        time: 10,
        cost: totalCost,
        distance: distance,
        riskScore: 0,
        iconId: 'car',
        lineColor: '#000000',
        segments: [driveSegment],
    );

    final mainLeg = Leg(
      id: 'main',
      label: 'Main Leg',
      time: 10,
      cost: 5.0,
      distance: 10.0,
      riskScore: 0,
      iconId: 'train',
      lineColor: '#000000',
      segments: [],
    );

    final lastMile = Leg(
        id: 'last',
        label: 'Last',
        time: 5,
        cost: 2,
        distance: 1,
        riskScore: 0,
        iconId: 'bus',
        lineColor: '#000000',
        segments: [],
    );

    return InitData(journeys: [],
      segmentOptions: SegmentOptions(
        firstMile: [firstMile],
        mainLeg: mainLeg,
        lastMile: [lastMile],
      ),
      directDrive: DirectDrive(time: 100, cost: 50, distance: 100),
      mockPath: [],
    );
  }
}

void main() {
  testWidgets('DetailPage shows "Free, but limited parking" when parking cost is 0', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    // drivingCost = distance * 0.45
    // parkingCost = totalCost - drivingCost
    // To make parkingCost = 0, totalCost must equal distance * 0.45
    double distance = 10.0;
    double totalCost = 4.5; // 10.0 * 0.45

    final mockApiService = MockApiService(distance: distance, totalCost: totalCost);

    final dummyLeg1 = Leg(
        id: 'first',
        label: 'First',
        time: 10,
        cost: totalCost,
        distance: distance,
        riskScore: 0,
        iconId: 'car',
        lineColor: '#000000',
        segments: [
            Segment(
              mode: 'car',
              label: 'Drive',
              lineColor: '#000000',
              iconId: 'car',
              time: 10,
              path: <LatLng>[],
              cost: totalCost,
              distance: distance,
            )
        ],
    );

    final dummyLeg3 = Leg(
        id: 'last',
        label: 'Last',
        time: 5,
        cost: 2,
        distance: 1,
        riskScore: 0,
        iconId: 'bus',
        lineColor: '#000000',
        segments: [],
    );

    final dummyResult = JourneyResult(
      id: 'dummy',
      leg1: dummyLeg1,
      leg3: dummyLeg3,
      cost: totalCost + 5 + 2,
      time: 25,
      buffer: 0,
      risk: 0,
      emissions: Emissions(val: 0, percent: 0),
    );

    await tester.pumpWidget(MaterialApp(
      home: DetailPage(
        journeyResult: dummyResult,
        apiService: mockApiService,
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Driving cost: £4.50'), findsOneWidget);
    expect(find.text('Parking cost: Free, but limited parking'), findsOneWidget);
    expect(find.textContaining('Parking cost (24 hours)'), findsNothing);

    // Clear timers
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('DetailPage shows parking cost when > 0', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    // drivingCost = 4.5
    // Want parkingCost = 1.0
    // totalCost = 5.5
    double distance = 10.0;
    double totalCost = 5.5;

    final mockApiService = MockApiService(distance: distance, totalCost: totalCost);

    final dummyLeg1 = Leg(
        id: 'first',
        label: 'First',
        time: 10,
        cost: totalCost,
        distance: distance,
        riskScore: 0,
        iconId: 'car',
        lineColor: '#000000',
        segments: [
             Segment(
              mode: 'car',
              label: 'Drive',
              lineColor: '#000000',
              iconId: 'car',
              time: 10,
              path: <LatLng>[],
              cost: totalCost,
              distance: distance,
            )
        ],
    );

     final dummyLeg3 = Leg(
        id: 'last',
        label: 'Last',
        time: 5,
        cost: 2,
        distance: 1,
        riskScore: 0,
        iconId: 'bus',
        lineColor: '#000000',
        segments: [],
    );

    final dummyResult = JourneyResult(
      id: 'dummy',
      leg1: dummyLeg1,
      leg3: dummyLeg3,
      cost: totalCost + 5 + 2,
      time: 25,
      buffer: 0,
      risk: 0,
      emissions: Emissions(val: 0, percent: 0),
    );

    await tester.pumpWidget(MaterialApp(
      home: DetailPage(
        journeyResult: dummyResult,
        apiService: mockApiService,
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Driving cost: £4.50'), findsOneWidget);
    expect(find.text('Parking cost (24 hours): £1.00'), findsOneWidget);
    expect(find.text('Free, but limited parking'), findsNothing);

    // Clear timers
    await tester.pump(const Duration(seconds: 1));
  });
}
