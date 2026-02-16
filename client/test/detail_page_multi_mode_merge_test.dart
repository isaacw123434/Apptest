import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';

class MockApiService extends ApiService {
  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    // Drive -> Train -> Walk
    final drive = Segment(
      mode: 'driving',
      label: 'Drive to Station',
      lineColor: '#000000',
      iconId: 'car',
      time: 10,
      path: [],
      cost: 1.50,
    );

    final train = Segment(
      mode: 'train',
      label: 'Train to Leeds',
      lineColor: '#FF0000',
      iconId: 'train',
      time: 20,
      path: [],
      cost: 5.00,
      waitTime: 5,
    );

    final walk = Segment(
      mode: 'walk',
      label: 'Walk to Interchange',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 2,
      path: [],
    );

    final firstMile = Leg(
        id: 'first',
        label: 'Drive + Train',
        time: 37,
        cost: 6.50,
        distance: 10.0,
        riskScore: 0,
        iconId: 'car',
        lineColor: '#FF0000',
        segments: [drive, train, walk],
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
  testWidgets('DetailPage merges Drive -> Train -> Walk segments correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = MockApiService();

    final drive = Segment(
      mode: 'driving',
      label: 'Drive to Station',
      lineColor: '#000000',
      iconId: 'car',
      time: 10,
      path: [],
      cost: 1.50,
    );

    final train = Segment(
      mode: 'train',
      label: 'Train to Leeds',
      lineColor: '#FF0000',
      iconId: 'train',
      time: 20,
      path: [],
      cost: 5.00,
      waitTime: 5,
    );

    final walk = Segment(
      mode: 'walk',
      label: 'Walk to Interchange',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 2,
      path: [],
    );

    final leg1 = Leg(
        id: 'first',
        label: 'Drive + Train',
        time: 37,
        cost: 6.50,
        distance: 10.0,
        riskScore: 0,
        iconId: 'car',
        lineColor: '#FF0000',
        segments: [drive, train, walk],
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
      cost: 26.50,
      time: 102,
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

    // Resolve timers
    await tester.pump(const Duration(seconds: 1));

    // Verify all 3 segments are visible
    expect(find.text('Drive to Station'), findsOneWidget);
    expect(find.text('Train to Leeds'), findsOneWidget);
    expect(find.text('Walk to Interchange'), findsOneWidget);

    // Verify wait time (5 mins)
    expect(find.textContaining('Wait 5 mins'), findsOneWidget);

    // Verify Total Cost for the merged block (£6.50)
    // We expect text '£6.50'.
    expect(find.text('£6.50'), findsOneWidget);

    // Verify "Edit" is present (merged block)
    // We expect exactly one "Edit" in the list if merged properly.
    // However, there might be other edits? No, leg3 is empty.
    // Actually, "Edit" button logic:
    // If not merged: Drive (First) gets Edit. Train (Train) gets Edit. Walk (Last) might not.
    // If merged: Only one Edit button for the block.
    // So if we see 2 Edits, it failed. If 1, it passed.
    // But 'Edit' text appears in the button label.
    // Let's check finding 'Edit'.
    expect(find.text('Edit'), findsOneWidget);
  });
}
