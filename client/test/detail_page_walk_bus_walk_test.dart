import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';
import 'package:latlong2/latlong.dart';

class MockApiService extends ApiService {
  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    final walk1 = Segment(
      mode: 'walk',
      label: 'Walk to Stop',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 5,
      path: [],
    );

    final bus = Segment(
      mode: 'bus',
      label: 'Bus 123',
      lineColor: '#FF0000',
      iconId: 'bus',
      time: 15,
      path: [],
      cost: 2.50,
      waitTime: 2,
    );

    final walk2 = Segment(
      mode: 'walk',
      label: 'Walk to Station',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 5,
      path: [],
    );

    final firstMile = Leg(
        id: 'first',
        label: 'First Mile Bus',
        time: 27,
        cost: 2.50,
        distance: 2.0,
        riskScore: 0,
        iconId: 'bus',
        lineColor: '#FF0000',
        segments: [walk1, bus, walk2],
    );

    final mainLeg = Leg(
      id: 'main',
      label: 'Main Leg',
      time: 60,
      cost: 20.0,
      distance: 50.0,
      riskScore: 0,
      iconId: 'train',
      lineColor: '#000000',
      segments: [],
    );

    final lastMile = Leg(
        id: 'last',
        label: 'Last',
        time: 5,
        cost: 0,
        distance: 0.5,
        riskScore: 0,
        iconId: 'walk',
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
  testWidgets('DetailPage merges Walk -> Bus -> Walk segments correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = MockApiService();

    final walk1 = Segment(
      mode: 'walk',
      label: 'Walk to Stop',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 5,
      path: [],
    );

    final bus = Segment(
      mode: 'bus',
      label: 'Bus 123',
      lineColor: '#FF0000',
      iconId: 'bus',
      time: 15,
      path: [],
      cost: 2.50,
      waitTime: 2,
    );

    final walk2 = Segment(
      mode: 'walk',
      label: 'Walk to Station',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 5,
      path: [],
    );

    final leg1 = Leg(
        id: 'first',
        label: 'First Mile Bus',
        time: 27,
        cost: 2.50,
        distance: 2.0,
        riskScore: 0,
        iconId: 'bus',
        lineColor: '#FF0000',
        segments: [walk1, bus, walk2],
    );

    final leg3 = Leg(
        id: 'last',
        label: 'Last',
        time: 5,
        cost: 0,
        distance: 0.5,
        riskScore: 0,
        iconId: 'walk',
        lineColor: '#000000',
        segments: [],
    );

    final dummyResult = JourneyResult(
      id: 'dummy',
      leg1: leg1,
      leg3: leg3,
      cost: 22.50,
      time: 90,
      buffer: 10,
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

    // Resolve any pending timers from DetailPage (e.g. map zoom delay)
    await tester.pump(const Duration(seconds: 1));

    // Verify all 3 segments are visible
    expect(find.text('Walk to Stop'), findsOneWidget);
    expect(find.text('Bus 123'), findsOneWidget);
    expect(find.text('Walk to Station'), findsOneWidget);

    // Verify wait time is visible.
    // In _buildMultiSegmentConnection we will add 'Wait 2 mins'
    // Before merge, it might be in extraDetails or not visible in same format.
    expect(find.textContaining('Wait 2 mins'), findsOneWidget);

    // Verify Total Cost for the merged block is visible
    // We expect 2.50 (cost of bus).
    // Note: The main header has total cost 22.50.
    // The merged block should show £2.50.
    // We can look for text '£2.50'.
    expect(find.text('£2.50'), findsOneWidget);

    // Verify Edit button is present
    expect(find.text('Edit'), findsOneWidget);
  });
}
