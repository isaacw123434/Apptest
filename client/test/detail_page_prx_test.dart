import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';
import 'package:latlong2/latlong.dart';

class MockApiService extends ApiService {
  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    // This mock returns empty data for init, we will drive the test via journeyResult passed to constructor
    // or we can put the relevant leg in mainLeg if we want.
    // The logic runs on ALL legs.

    return InitData(
      segmentOptions: SegmentOptions(
        firstMile: [],
        mainLeg: Leg(
          id: 'main',
          label: 'Main Leg',
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
  testWidgets('DetailPage attaches parking cost to PRx bus instead of car', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = MockApiService();

    final carSeg = Segment(
      mode: 'car',
      label: 'Drive',
      lineColor: '#0000FF',
      iconId: 'car',
      time: 10,
      cost: 2.0,
    );

    final parkingSeg = Segment(
      mode: 'parking',
      label: 'Parking',
      lineColor: '#000000',
      iconId: 'parking',
      time: 0,
      cost: 5.0,
    );

    final walkSeg = Segment(
      mode: 'walk',
      label: 'Walk',
      lineColor: '#000000',
      iconId: 'footprints',
      time: 5,
      cost: 0.0,
    );

    final prxBusSeg = Segment(
      mode: 'bus',
      label: 'PR1 Bus',
      lineColor: '#FF0000',
      iconId: 'bus',
      time: 20,
      cost: 2.0,
    );

    // Leg 1 has the sequence
    final leg1 = Leg(
        id: 'first',
        label: 'First',
        time: 35,
        cost: 9.0, // Total cost
        distance: 1,
        riskScore: 0,
        iconId: 'car',
        lineColor: '#000000',
        segments: [carSeg, parkingSeg, walkSeg, prxBusSeg],
    );

    final leg3 = Leg(
        id: 'last',
        label: 'Last',
        time: 0,
        cost: 0,
        distance: 0,
        riskScore: 0,
        iconId: 'walk',
        lineColor: '#000000',
        segments: [],
    );

    final journeyResult = JourneyResult(
      id: 'prx_journey',
      leg1: leg1,
      leg3: leg3,
      cost: 9.0,
      time: 35,
      buffer: 0,
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

    // Verify 'Drive' segment exists
    expect(find.text('Drive'), findsOneWidget);
    // Verify 'PR1 Bus' segment exists
    expect(find.text('PR1 Bus'), findsOneWidget);

    // Check costs
    // Drive should remain £2.00
    // PR1 Bus should be £7.00 (£2.00 + £5.00)

    // We can find the widgets and check their descendants or look for text generally.
    // Finding specific text '£2.00' and '£7.00' is a good start.

    expect(find.text('£2.00'), findsOneWidget); // Car cost
    expect(find.text('£7.00'), findsOneWidget); // Bus cost

    // To be more robust, we should ensure £7.00 is associated with PR1 Bus.
    // We can find the PR1 Bus widget and look for £7.00 inside it.
    final prFinder = find.ancestor(of: find.text('£7.00'), matching: find.byType(Container));
    // This might be too generic.

    // Let's verify that £7.00 is present and £9.00 (total) is present in header.
    // Total cost in header is also £9.00.

    // But we are looking for segment costs.
    // If logic failed (merged to car), Car would be £7.00 and Bus £2.00.
    // So if we see £2.00 and £7.00, it confirms logic is likely correct (assuming they are swapped correctly).
    // If logic failed: Car = £7.00, Bus = £2.00.
    // If logic correct: Car = £2.00, Bus = £7.00.

    // We can disambiguate by checking order or association.
    // But simple check: do we see £2.00? Yes. Do we see £7.00? Yes.
    // If failed, we would also see £7.00 (Car) and £2.00 (Bus). Wait.
    // In both cases we have a 2 and a 7.
    // Fail case: Car(2+5=7), Bus(2).
    // Success case: Car(2), Bus(2+5=7).

    // Ah, so just checking for existence of 2 and 7 isn't enough.
    // I need to check which one is which.

    // I can iterate over all Text widgets and check proximity.
    // Or I can use `find.widgetWithText`? No, that's for specific widgets.

    // Let's try to find the row containing 'PR1 Bus' and check if it contains '£7.00'.

    final pr1Finder = find.text('PR1 Bus');
    final pr1Parent = find.ancestor(of: pr1Finder, matching: find.byType(Column));
    // The text 'PR1 Bus' is inside a Column.
    // And '£7.00' is inside the same Column.

    final pr1Column = tester.widget<Column>(pr1Parent.first);
    // Inspect children of this column?
    // This is getting complicated to query via finder.

    // Easier way:
    // Find the widget that contains both 'PR1 Bus' and '£7.00'.
    // The DetailPage uses `_buildSegmentConnection` which puts them in a Column.

    final pr1AndCostFinder = find.descendant(
      of: find.ancestor(of: find.text('PR1 Bus'), matching: find.byType(Column)),
      matching: find.text('£7.00')
    );

    expect(pr1AndCostFinder, findsOneWidget);

    final carAndCostFinder = find.descendant(
      of: find.ancestor(of: find.text('Drive'), matching: find.byType(Column)),
      matching: find.text('£2.00')
    );

    expect(carAndCostFinder, findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('DetailPage merges parking to car for non-PRx', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = MockApiService();

    final carSeg = Segment(
      mode: 'car',
      label: 'Drive',
      lineColor: '#0000FF',
      iconId: 'car',
      time: 10,
      cost: 2.0,
    );

    final parkingSeg = Segment(
      mode: 'parking',
      label: 'Parking',
      lineColor: '#000000',
      iconId: 'parking',
      time: 0,
      cost: 5.0,
    );

    final trainSeg = Segment(
      mode: 'train',
      label: 'Train',
      lineColor: '#FF0000',
      iconId: 'train',
      time: 20,
      cost: 10.0,
    );

    final leg1 = Leg(
        id: 'first',
        label: 'First',
        time: 30,
        cost: 17.0,
        distance: 1,
        riskScore: 0,
        iconId: 'car',
        lineColor: '#000000',
        segments: [carSeg, parkingSeg, trainSeg],
    );

    final leg3 = Leg(
        id: 'last',
        label: 'Last',
        time: 0,
        cost: 0,
        distance: 0,
        riskScore: 0,
        iconId: 'walk',
        lineColor: '#000000',
        segments: [],
    );

    final journeyResult = JourneyResult(
      id: 'normal_journey',
      leg1: leg1,
      leg3: leg3,
      cost: 17.0,
      time: 30,
      buffer: 0,
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

    // Car should have £7.00 (2+5)
    final carAndCostFinder = find.descendant(
      of: find.ancestor(of: find.text('Drive'), matching: find.byType(Column)),
      matching: find.text('£7.00')
    );
    expect(carAndCostFinder, findsOneWidget);

    // Train should have £10.00
    final trainAndCostFinder = find.descendant(
      of: find.ancestor(of: find.text('Train'), matching: find.byType(Column)),
      matching: find.text('£10.00')
    );
    expect(trainAndCostFinder, findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 1));
  });
}
