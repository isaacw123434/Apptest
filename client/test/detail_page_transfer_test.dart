import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/services/api_service.dart';

class MockApiService extends ApiService {
  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    final transferSeg = Segment(
      mode: 'wait',
      label: 'Transfer',
      lineColor: '#000000',
      iconId: 'clock',
      time: 10,
      path: [],
    );

    final mainLeg = Leg(
      id: 'main',
      label: 'Main Leg',
      time: 10,
      cost: 0,
      distance: 0,
      riskScore: 0,
      iconId: 'train',
      lineColor: '#000000',
      segments: [transferSeg],
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
  testWidgets('DetailPage renders transfer segment with vertical line', (WidgetTester tester) async {
    // Set screen size to ensure visibility
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockApiService = MockApiService();

    final leg1 = Leg(
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

    final leg3 = Leg(
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

    final journeyResult = JourneyResult(
      id: 'first-last',
      leg1: leg1,
      leg3: leg3,
      cost: 4.0,
      time: 20,
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

    // Find the transfer text
    final transferFinder = find.text('10 mins transfer');
    expect(transferFinder, findsOneWidget);

    // In the NEW implementation, the transfer text is inside a Row, which is inside an Expanded,
    // which is inside a Row (the main row of the item), which has the vertical line as first child.

    // In the OLD implementation, the transfer text is inside a Row, which is inside a Padding.
    // The Padding does NOT have a sibling that is the vertical line (Stack).

    // Let's look for the vertical line structure specifically associated with this transfer.
    // The vertical line is a Stack containing two Containers.

    // We can find the Row that contains the text.

    // Check if we can find the vertical line in the ancestors.
    // We expect the structure: IntrinsicHeight -> Row -> [SizedBox(width: 24, child: Stack), SizedBox(width: 16), Expanded(...)]

    // Wait, find.ancestor might find the textRow itself if it matches.
    // But textRow is inside Expanded (in new impl) or Padding (in old impl).

    // Let's try to find the Stack (vertical line) near the transfer text.
    // We can search for a Stack that has a Container with width 12 and color grey[200].

    // This is a bit tricky to target exactly.
    // Let's assume the new structure and try to find it.

    // Iterate over stacks to find one that looks like a vertical line and is close to our transfer text.
    // But easier: check if the parent of the text row is Expanded.

    final parent = tester.widget(find.ancestor(of: transferFinder, matching: find.byType(Padding)).first);
    // In old impl: Padding(padding: EdgeInsets.only(left: 40...))
    // In new impl: Padding(padding: EdgeInsets.only(bottom: 8, top: 4)) inside Expanded.

    if (parent is Padding) {
       final padding = parent.padding as EdgeInsets;
       // Old impl has left: 40
       if (padding.left == 40.0) {
           fail('Found old implementation: Padding with left 40');
       }
    }

    // Verify vertical line existence
    // We can look for IntrinsicHeight which wraps the whole row
    final intrinsicHeightFinder = find.ancestor(of: transferFinder, matching: find.byType(IntrinsicHeight)).first;
    expect(intrinsicHeightFinder, findsOneWidget);

    // Inside this IntrinsicHeight, we should find a Stack (the line)
    final stackFinder = find.descendant(of: intrinsicHeightFinder, matching: find.byType(Stack));
    expect(stackFinder, findsWidgets); // Should find at least one stack (the vertical line)

    // Clear timers
    await tester.pump(const Duration(seconds: 1));
  });
}
