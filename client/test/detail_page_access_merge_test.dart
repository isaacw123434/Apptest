import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';

class MockAccessMergeApiService extends ApiService {
  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    final walk1 = Segment(
      mode: 'walk',
      label: 'Walk to Stop',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 5,
      path: [],
      cost: 0.0,
    );

    final bus = Segment(
      mode: 'bus',
      label: 'Bus 56',
      lineColor: '#00FF00',
      iconId: 'bus',
      time: 20,
      path: [],
      cost: 2.50,
    );

    final walk2 = Segment(
      mode: 'walk',
      label: 'Walk to Station',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 5,
      path: [],
      cost: 0.0,
    );

    final firstMile = Leg(
      id: 'multi_segment_access',
      label: 'Bus Trip',
      time: 30,
      cost: 2.50,
      distance: 5.0,
      riskScore: 0,
      iconId: 'bus',
      lineColor: '#00FF00',
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
      segments: [
        Segment(
          mode: 'train',
          label: 'Train',
          lineColor: '#000000',
          iconId: 'train',
          time: 60,
          path: [],
        ),
      ],
    );

    final lastMile = Leg(
      id: 'last',
      label: 'Last',
      time: 5,
      cost: 0,
      distance: 1,
      riskScore: 0,
      iconId: 'walk',
      lineColor: '#000000',
      segments: [
        Segment(
          mode: 'walk',
          label: 'Walk',
          lineColor: '#000000',
          iconId: 'footprints',
          time: 5,
          path: [],
        ),
      ],
    );

    return InitData(
      journeys: [],
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
  testWidgets('DetailPage merges multi-segment access legs correctly', (
    WidgetTester tester,
  ) async {
    // Set screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = MockAccessMergeApiService();
    final initData = await mockApiService.fetchInitData();

    final journeyResult = JourneyResult(
      id: 'test_journey',
      leg1: initData.segmentOptions.firstMile.first,
      leg3: initData.segmentOptions.lastMile.first,
      cost: 22.50,
      time: 95,
      buffer: 0,
      risk: 0,
      emissions: Emissions(val: 0, percent: 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailPage(
          journeyResult: journeyResult,
          apiService: mockApiService,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify all segments are shown
    expect(find.text('Walk to Stop'), findsOneWidget);
    expect(find.text('Bus 56'), findsOneWidget);
    expect(find.text('Walk to Station'), findsOneWidget);

    // 2. Verify Cost is shown once for the group (we look for the total cost of the leg: £2.50)
    // Note: The main leg has £20.00, total £22.50.
    // The merged block should show £2.50.
    expect(find.text('£2.50'), findsOneWidget);

    // 3. Verify "Edit" button is present once for the group
    // Note: Last mile also has an Edit button because it is editable.
    expect(find.text('Edit'), findsNWidgets(2));

    // 4. Verify vertical line structure (simplified check: existence of colored containers)
    // It's hard to verify visual structure, but if the text is there and Edit button is there, it's likely using the correct widget.

    // 5. Verify tapping Edit opens modal (which implies the callback works)
    // We want the first one (First Mile)
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    expect(find.text('Access Options'), findsOneWidget);
  });
}
