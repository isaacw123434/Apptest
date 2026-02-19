import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/screens/summary_page.dart';
import 'package:client/widgets/header.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:client/models.dart';
import 'package:client/services/api_service.dart';

class MockApiService implements ApiService {
  final InitData initData;
  final List<JourneyResult> journeys;

  MockApiService({required this.initData, required this.journeys});

  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    return Future.value(initData);
  }

  @override
  Future<List<JourneyResult>> searchJourneys({
    required String tab,
    required Map<String, bool> selectedModes,
    String? routeId,
  }) async {
    return Future.value(journeys);
  }
}

void main() {
  InitData createInitData() {
    return InitData(
       journeys: [],
       directDrive: DirectDrive(time: 10, distance: 10, cost: 10),
       segmentOptions: SegmentOptions(
         firstMile: [],
         mainLeg: Leg(id: 'main', label: 'main', time: 10, cost: 10, distance: 10, riskScore: 0, iconId: 'train', lineColor: 'red', segments: []),
         lastMile: []
       ),
       mockPath: []
    );
  }

  List<JourneyResult> createJourneyResults(int count) {
     return List.generate(count, (index) => JourneyResult(
       id: 'id_$index',
       leg1: Leg(id: 'l1', label: 'Short', time: 10, cost: 10, distance: 10, riskScore: 0, iconId: 'car', lineColor: 'red', segments: []),
       leg3: Leg(id: 'l3', label: 'Short', time: 10, cost: 10, distance: 10, riskScore: 0, iconId: 'walk', lineColor: 'red', segments: []),
       cost: 10,
       time: 10,
       buffer: 10,
       risk: 0,
       emissions: Emissions(val: 10, percent: 10, text: 'text')
     ));
  }

  testWidgets('SummaryPage shows "View all routes" button when more routes exist', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final journeys = createJourneyResults(10); // More than 3
    final apiService = MockApiService(initData: createInitData(), journeys: journeys);

    await tester.pumpWidget(MaterialApp(
      home: SummaryPage(
        from: 'A',
        to: 'B',
        timeType: 'Depart',
        time: '10:00',
        selectedModes: {},
        apiService: apiService,
      ),
    ));

    await tester.pump(); // trigger initState
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Scroll to bottom to ensure button is visible
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    // Verify "View all routes" is present
    expect(find.text('View all routes'), findsOneWidget);
  });

  testWidgets('Header shows back button on SummaryPage and navigates back', (WidgetTester tester) async {
    final journeys = createJourneyResults(1);
    final apiService = MockApiService(initData: createInitData(), journeys: journeys);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SummaryPage(
              from: 'A',
              to: 'B',
              timeType: 'Depart',
              time: '10:00',
              selectedModes: {},
              apiService: apiService,
            )));
          },
          child: const Text('Go'),
        ),
      ),
    ));

    // Tap to go to SummaryPage
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    // Now we are on SummaryPage
    expect(find.byType(SummaryPage), findsOneWidget);
    expect(find.byType(Header), findsOneWidget);

    // Check if back button exists in Header
    expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);

    // Tap the back button
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    // Check if we are back at the start
    expect(find.text('Go'), findsOneWidget);
  });
}
