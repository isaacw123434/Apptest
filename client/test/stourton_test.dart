import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';

class StourtonMockApiService extends ApiService {
  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    // 1. Stourton (Car -> Walk -> Bus)
    final stourtonLeg = Leg(
      id: 'drive_stourton_pr',
      label: 'Drive to Stourton P&R',
      time: 94,
      cost: 28.8,
      distance: 56.65,
      riskScore: 1,
      iconId: 'car',
      lineColor: '#262262',
      segments: [
        Segment(
          mode: 'car',
          label: 'Drive',
          lineColor: '#0000FF',
          iconId: 'car',
          time: 64,
          to: 'Stourton Park & Ride',
        ),
        Segment(
          mode: 'walk',
          label: 'Walk',
          lineColor: '#000000',
          iconId: 'footprints',
          time: 3,
          to: 'Stourton Park and Ride',
        ),
        Segment(
          mode: 'bus',
          label: 'PR3 Park & Ride',
          lineColor: '#000000',
          iconId: 'bus',
          time: 10,
          from: 'Stourton Park and Ride',
          to: 'Trinity K',
        ),
        Segment(
          mode: 'walk',
          label: 'Walk',
          lineColor: '#000000',
          iconId: 'footprints',
          time: 10,
          to: 'Dest',
        ),
      ],
    );

    // 2. Temple Green (Car -> Bus)
    final templeGreenLeg = Leg(
      id: 'drive_temple_green_pr',
      label: 'Drive to Temple Green P&R',
      time: 105,
      cost: 29.8,
      distance: 60.1,
      riskScore: 1,
      iconId: 'car',
      lineColor: '#e0603a',
      segments: [
        Segment(
          mode: 'car',
          label: 'Drive',
          lineColor: '#0000FF',
          iconId: 'car',
          time: 66,
          to: 'Temple Green Park & Ride',
        ),
        Segment(
          mode: 'bus',
          label: 'PR2 Park & Ride',
          lineColor: '#e0603a',
          iconId: 'bus',
          time: 15,
          from: 'Temple Green Park and Ride',
          to: 'Cultural C',
        ),
      ],
    );

    // 3. Brough (Car -> Wait -> Train)
    final broughLeg = Leg(
      id: 'train_drive_brough',
      label: 'Drive to Brough',
      time: 99,
      cost: 20.3,
      distance: 55.4,
      riskScore: 1,
      iconId: 'car',
      lineColor: '#262262',
      segments: [
        Segment(
          mode: 'car',
          label: 'Drive',
          lineColor: '#0000FF',
          iconId: 'car',
          time: 26,
          to: 'Brough Station',
        ),
        Segment(
          mode: 'wait',
          label: 'Transfer',
          lineColor: '#000000',
          iconId: 'clock',
          time: 10,
        ),
        Segment(
          mode: 'train',
          label: 'Northern',
          lineColor: '#262262',
          iconId: 'train',
          time: 63,
          from: 'Brough Station',
          to: 'Leeds Station',
        ),
      ],
    );

    return InitData(
      journeys: [],
      segmentOptions: SegmentOptions(
        firstMile: [stourtonLeg, templeGreenLeg, broughLeg],
        mainLeg: Leg(
          id: 'main',
          label: 'Main',
          time: 0,
          cost: 0,
          distance: 0,
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
  testWidgets('Stourton P&R Edit shows all options', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = StourtonMockApiService();
    final initData = await mockApiService.fetchInitData();
    final stourtonLeg = initData.segmentOptions.firstMile[0];

    final dummyResult = JourneyResult(
      id: 'dummy',
      leg1: stourtonLeg,
      leg3: Leg(
        id: 'empty',
        label: '',
        time: 0,
        cost: 0,
        distance: 0,
        riskScore: 0,
        iconId: '',
        lineColor: '',
        segments: [],
      ),
      cost: stourtonLeg.cost,
      time: stourtonLeg.time,
      buffer: 0,
      risk: 0,
      emissions: Emissions(val: 0, percent: 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailPage(
          journeyResult: dummyResult,
          apiService: mockApiService,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Stourton bus is present
    expect(find.text('PR3 Park & Ride'), findsOneWidget);

    // Find edit button for Stourton Bus
    // Segments: Car (Edit), Walk, Bus (Edit), Walk.
    // There should be 2 Edit buttons.
    final editButtons = find.text('Edit');
    expect(editButtons, findsNWidgets(2));

    // Tap the bus edit button (second one)
    await tester.tap(editButtons.last);
    await tester.pumpAndSettle();

    // Verify modal title
    expect(find.text('Choose Route'), findsOneWidget);

    // Verify options
    // Should see Stourton, Temple Green, Brough
    expect(find.text('Drive to Stourton P&R'), findsOneWidget);
    expect(find.text('Drive to Temple Green P&R'), findsOneWidget);

    // Brough might be labeled "Brough Station to Leeds Station" due to labelBuilder in _showTrainEdit
    // labelBuilder logic:
    // Finds train segment. from -> to.
    // Brough train segment: from Brough Station, to Leeds Station.
    // So label should be "Brough Station to Leeds Station".
    expect(find.text('Brough Station to Leeds Station'), findsOneWidget);
  });
}
