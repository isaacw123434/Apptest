import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';
import 'package:latlong2/latlong.dart';

class MockApiService extends ApiService {
  final double distance;
  final double totalCost;
  final String destination;

  MockApiService({required this.distance, required this.totalCost, required this.destination});

  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    // Need dummy legs for edit modal
    final leg1 = Leg(
        id: 'opt1',
        label: 'Drive to Elland Road P&R',
        time: 10,
        cost: 5,
        distance: 10,
        riskScore: 0,
        iconId: 'car',
        lineColor: '#000000',
        segments: [
             Segment(mode: 'car', label: 'Drive', lineColor: '#000000', iconId: 'car', time: 10, cost: 5, distance: 10, to: 'Elland Road Park & Ride'),
             Segment(mode: 'bus', label: 'PR1 Park & Ride', lineColor: '#000000', iconId: 'bus', time: 10, cost: 2, to: 'Leeds'),
        ],
    );
    final leg2 = Leg(
        id: 'opt2',
        label: 'Drive to Temple Green P&R',
        time: 12,
        cost: 6,
        distance: 12,
        riskScore: 0,
        iconId: 'car',
        lineColor: '#000000',
        segments: [
             Segment(mode: 'car', label: 'Drive', lineColor: '#000000', iconId: 'car', time: 12, cost: 6, distance: 12, to: 'Temple Green Park and Ride'),
             Segment(mode: 'bus', label: 'PR2 Park & Ride', lineColor: '#000000', iconId: 'bus', time: 12, cost: 2, to: 'Leeds'),
        ],
    );

    return InitData(journeys: [],
      segmentOptions: SegmentOptions(
        firstMile: [leg1, leg2],
        mainLeg: Leg(id: 'main', label: 'Main', time: 0, cost: 0, distance: 0, riskScore: 0, iconId: 'train', lineColor: '#000000', segments: []),
        lastMile: [],
      ),
      directDrive: DirectDrive(time: 100, cost: 50, distance: 100),
      mockPath: [],
    );
  }
}

void main() {
  testWidgets('DetailPage handles Park and Ride correctly (no parking split)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    double distance = 10.0;
    double totalCost = 4.5; // distance * 0.45, so usually would show free parking
    String destination = "Elland Road Park & Ride";

    final mockApiService = MockApiService(distance: distance, totalCost: totalCost, destination: destination);

    final dummyLeg1 = Leg(
        id: 'first',
        label: 'Drive to Elland Road P&R',
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
              to: destination
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
      cost: totalCost + 2,
      time: 15,
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

    // Should NOT show "Driving cost" or "Parking cost" breakdown
    expect(find.text('Driving cost: £4.50'), findsNothing);
    expect(find.text('Parking cost: Free, but limited parking'), findsNothing);
    expect(find.textContaining('Parking cost'), findsNothing);

    // Should show simple cost
    expect(find.text('£4.50'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('DetailPage allows editing P&R bus segment', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = MockApiService(distance: 10, totalCost: 5, destination: "Elland Road");

    final dummyLeg1 = Leg(
        id: 'first',
        label: 'Drive to Elland Road P&R',
        time: 20,
        cost: 10,
        distance: 10,
        riskScore: 0,
        iconId: 'car',
        lineColor: '#000000',
        segments: [
            Segment(mode: 'car', label: 'Drive', lineColor: '#000000', iconId: 'car', time: 10, cost: 5, distance: 10, to: 'Elland Road Park & Ride'),
            Segment(mode: 'bus', label: 'PR1 Park & Ride', lineColor: '#000000', iconId: 'bus', time: 10, cost: 5, to: 'Leeds'),
        ],
    );

    final dummyLeg3 = Leg(id: 'last', label: 'Last', time: 0, cost: 0, distance: 0, riskScore: 0, iconId: 'walk', lineColor: '#000000', segments: []);

    final dummyResult = JourneyResult(
      id: 'dummy',
      leg1: dummyLeg1,
      leg3: dummyLeg3,
      cost: 10,
      time: 20,
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

    // Find the edit button for the bus segment
    // We expect an "Edit" button next to "PR1 Park & Ride"
    // Since there are two segments, both might be editable.
    // The Drive segment is editable (isFirst).
    // The Bus segment is editable (isParkAndRideBus).

    final editButtons = find.text('Edit');
    expect(editButtons, findsNWidgets(2));

    // Tap the second edit button (for the bus)
    await tester.tap(editButtons.last);
    await tester.pumpAndSettle();

    // Verify "Choose Route" modal appears (which comes from _showTrainEdit)
    expect(find.text('Choose Route'), findsOneWidget);

    // Verify both options are present
    expect(find.text('Drive to Elland Road P&R'), findsOneWidget);
    expect(find.text('Drive to Temple Green P&R'), findsOneWidget);
  });
}
