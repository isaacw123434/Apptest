import 'package:client/widgets/timeline_summary_view.dart';
import 'package:client/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TimelineSummaryView simplifies text on overflow', (WidgetTester tester) async {
    // Define segments that are long enough to cause overflow on a narrow screen
    final segments = [
      Segment(
        mode: 'walk',
        label: 'Walk',
        lineColor: '#000000',
        iconId: 'footprints',
        time: 5,
      ),
      Segment(
        mode: 'bus',
        label: 'Bus 123',
        lineColor: '#FF0000',
        iconId: 'bus',
        time: 15,
      ),
      Segment(
        mode: 'train',
        label: 'Thameslink',
        lineColor: '#0000FF',
        iconId: 'train',
        time: 20,
      ),
      Segment(
        mode: 'walk',
        label: 'Walk',
        lineColor: '#000000',
        iconId: 'footprints',
        time: 5,
      ),
    ];

    // Constrain width to force overflow
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 250,
            height: 100,
            child: TimelineSummaryView(segments: segments, totalTime: 45),
          ),
        ),
      ),
    ));

    // New behavior: Should NOT scroll if it fits with simplification
    expect(find.byType(SingleChildScrollView), findsNothing);

    // Verify text IS simplified
    expect(find.text('Bus 123'), findsNothing);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('Thameslink'), findsNothing);
    expect(find.text('Train'), findsOneWidget);
  });
}
