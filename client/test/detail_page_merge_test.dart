import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';

class MockApiService extends ApiService {
  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    final trainLeg1 = Segment(
      mode: 'train',
      label: 'Train to Leeds',
      lineColor: '#FF0000',
      iconId: 'train',
      time: 10,
      to: 'Leeds',
      path: [],
      cost: 5.0,
    );

    final walkBetween = Segment(
      mode: 'walk',
      label: 'Walk to Platform',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 4, // Should be hidden and trigger merge
      path: [],
    );

    final trainLeg2 = Segment(
      mode: 'train',
      label: 'Train to London',
      lineColor: '#0000FF',
      iconId: 'train',
      time: 50,
      from: 'Leeds',
      path: [],
      cost: 20.0,
    );

    final mainLeg = Leg(
      id: 'main',
      label: 'Main Leg',
      time: 64,
      cost: 25.0,
      distance: 50.0,
      riskScore: 0,
      iconId: 'train',
      lineColor: '#000000',
      segments: [trainLeg1, walkBetween, trainLeg2],
    );

    final firstMile = Leg(
        id: 'first',
        label: 'First',
        time: 5,
        cost: 2,
        distance: 1,
        riskScore: 0,
        iconId: 'bus',
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

    return InitData(
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
  testWidgets('DetailPage merges train segments correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = MockApiService();

    final dummyLeg1 = Leg(
        id: 'first',
        label: 'First',
        time: 5,
        cost: 2,
        distance: 1,
        riskScore: 0,
        iconId: 'bus',
        lineColor: '#000000',
        segments: [],
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
      cost: 0,
      time: 0,
      buffer: 0,
      risk: 0,
      emissions: Emissions(val: 0, percent: 0),
    );

    // Setup initial data via API
    await tester.pumpWidget(MaterialApp(
      home: DetailPage(
        journeyResult: dummyResult,
        apiService: mockApiService,
      ),
    ));

    await tester.pumpAndSettle();

    // Verify both trains are visible (inside the merged box)
    expect(find.text('Train to Leeds'), findsOneWidget);
    expect(find.text('Train to London'), findsOneWidget);

    // Verify "Change at Leeds" is present with wait time
    expect(find.textContaining('Change at Leeds (4 mins)'), findsOneWidget);

    // Verify ONE Total Cost (£25.00)
    expect(find.text('£25.00'), findsOneWidget);

    // Verify individual costs are NOT present
    expect(find.text('£5.00'), findsNothing);
    expect(find.text('£20.00'), findsNothing);

    // Clear timers
    await tester.pump(const Duration(seconds: 1));
  });
}
