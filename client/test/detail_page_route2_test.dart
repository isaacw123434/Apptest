import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';

class MockRoute2ApiService extends ApiService {
  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    // Replicating the 'bus' leg from routes_2_clean.json
    final walk1 = Segment(
      mode: 'walk',
      label: 'Walk',
      lineColor: '#475569',
      iconId: 'footprints',
      time: 11,
      distance: 0.5,
      cost: 0.0,
      path: [],
    );

    final bus = Segment(
      mode: 'bus',
      label: 'X46',
      lineColor: '#002663',
      iconId: 'bus',
      time: 85,
      distance: 32.3,
      cost: 3.0,
      path: [],
      from: 'Beverley York Road',
      to: 'Rail Station',
    );

    final walk2 = Segment(
      mode: 'walk',
      label: 'Walk',
      lineColor: '#475569',
      iconId: 'footprints',
      time: 8,
      distance: 0.4,
      cost: 0.0,
      path: [],
    );

    final firstMile = Leg(
      id: 'bus',
      label: 'Bus (X46)',
      time: 104,
      cost: 3.0,
      distance: 32.8,
      riskScore: 1,
      iconId: 'bus',
      lineColor: '#002663',
      segments: [walk1, bus, walk2],
    );

    // Empty last mile for Route 2 logic (though strictly not required for rendering first mile)
    final lastMile = Leg(
      id: 'empty_last_mile',
      label: 'Arrived',
      time: 0,
      cost: 0,
      distance: 0,
      riskScore: 0,
      iconId: 'footprints',
      lineColor: '#000000',
      segments: [],
    );

    final mainLeg = Leg(
      id: 'main_placeholder',
      label: 'Main',
      time: 0,
      cost: 0,
      distance: 0,
      riskScore: 0,
      iconId: 'train',
      lineColor: '#000000',
      segments: [],
    );

    return InitData(
      segmentOptions: SegmentOptions(
        firstMile: [firstMile],
        mainLeg: mainLeg,
        lastMile: [lastMile],
      ),
      directDrive: DirectDrive(time: 73, cost: 25.64, distance: 56.98),
      mockPath: [],
    );
  }
}

void main() {
  testWidgets('DetailPage merges Route 2 Bus X46 leg', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = MockRoute2ApiService();
    final initData = await mockApiService.fetchInitData();

    final journeyResult = JourneyResult(
      id: 'test_journey',
      leg1: initData.segmentOptions.firstMile.first,
      leg3: initData.segmentOptions.lastMile.first,
      cost: 3.00,
      time: 104,
      buffer: 0,
      risk: 1,
      emissions: Emissions(val: 0, percent: 0),
    );

    await tester.pumpWidget(MaterialApp(
      home: DetailPage(
        journeyResult: journeyResult,
        apiService: mockApiService,
      ),
    ));

    await tester.pumpAndSettle();

    // Debug output of all text widgets
    // final textWidgets = find.byType(Text);
    // for (var widget in textWidgets.evaluate()) {
    //   print((widget.widget as Text).data);
    // }

    // 1. Should show segments in the merged box
    expect(find.text('Walk'), findsNWidgets(2));
    expect(find.text('X46'), findsOneWidget);

    // 2. Should NOT show intermediate nodes like "Beverley York Road" as main nodes
    // The "Beverley York Road" text might appear as 'from' in segment details?
    // In the mock data above, I set 'from' on the bus segment.
    // In `_buildMultiSegmentConnection`, we show `seg.detail`.
    // We do NOT show `from`/`to` explicitly in the merged box rows currently.
    // But `_buildVerticalNodeTimeline` loop adds `_buildNode` which uses `to` for title.

    // If merged, `_buildMultiSegmentConnection` is used.
    // It DOES NOT render the intermediate nodes.
    // So "Beverley York Road" should NOT be visible as a bold node title if strictly following current `_buildMultiSegmentConnection`.
    // However, if the user sees it, maybe it is not merging.

    // Let's verify if "Edit" appears exactly once.
    expect(find.text('Edit'), findsOneWidget);

    // If merged, we should NOT see intermediate nodes like "Rail Station" (which is the 'to' of the middle segment)
    // as separate timeline nodes. They are hidden inside the merged block (and not currently displayed in text).
    // If unmerged, 'Rail Station' would be a node title.
    expect(find.text('Rail Station'), findsNothing);

    // Clear pending timers
    await tester.pump(const Duration(seconds: 1));
  });
}
