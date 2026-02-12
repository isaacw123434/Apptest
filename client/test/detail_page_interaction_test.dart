import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';

class MockApiService extends ApiService {
  @override
  Future<InitData> fetchInitData() async {
    final walk1Min = Segment(
      mode: 'walk',
      label: 'Walk 1 min',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 1,
      path: [],
    );

    final walk2Min = Segment(
      mode: 'walk',
      label: 'Walk 2 mins',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 2,
      path: [],
    );

    final walk10Min = Segment(
      mode: 'walk',
      label: 'Walk 10 mins',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 10,
      path: [],
    );

    final mainLeg = Leg(
      id: 'main',
      label: 'Main Leg',
      time: 13,
      cost: 10.0,
      distance: 5.0,
      riskScore: 0,
      iconId: 'train',
      lineColor: '#000000',
      segments: [walk1Min, walk2Min, walk10Min],
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
      directDrive: DirectDrive(time: 20, cost: 20, distance: 10),
      mockPath: [],
    );
  }
}

void main() {
  testWidgets('DetailPage has tap handlers on segments (copied setup)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockApiService = MockApiService();

    final dummySeg = Segment(
      mode: 'bus',
      label: 'Bus 1',
      lineColor: '#FF0000',
      iconId: 'bus',
      time: 5,
      path: [],
    );

    final leg1 = Leg(
        id: 'first',
        label: 'First',
        time: 5,
        cost: 2,
        distance: 1,
        riskScore: 0,
        iconId: 'bus',
        lineColor: '#000000',
        segments: [dummySeg],
    );

    final leg3 = Leg(
        id: 'last',
        label: 'Last',
        time: 5,
        cost: 2,
        distance: 1,
        riskScore: 0,
        iconId: 'bus',
        lineColor: '#000000',
        segments: [dummySeg],
    );

    final journeyResult = JourneyResult(
      id: 'first-last',
      leg1: leg1,
      leg3: leg3,
      cost: 14.0,
      time: 23,
      buffer: 10,
      risk: 0,
      emissions: Emissions(val: 0, percent: 0),
    );

    await tester.pumpWidget(MaterialApp(
      home: DetailPage(
        journeyResult: journeyResult,
        apiService: mockApiService,
      ),
    ));

    await tester.pumpAndSettle();

    final segmentFinder = find.text('Walk 10 mins');
    expect(segmentFinder, findsOneWidget);

    // Check for GestureDetector
    final gestureDetectorFinder = find.ancestor(
        of: segmentFinder,
        matching: find.byType(GestureDetector),
    );
    expect(gestureDetectorFinder, findsAtLeastNWidgets(1));

    // Tap it
    await tester.tap(segmentFinder);
    await tester.pump();
  });
}
