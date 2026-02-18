import 'package:client/widgets/timeline_summary_view.dart';
import 'package:client/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TimelineSummaryView displays duration text', (WidgetTester tester) async {
     final segments = [
       Segment(mode: 'walk', label: 'Walk', lineColor: '#000000', iconId: 'footprints', time: 5),
       Segment(mode: 'train', label: 'Train', lineColor: '#FF0000', iconId: 'train', time: 65),
     ];

     await tester.pumpWidget(MaterialApp(
       home: Scaffold(
         body: SizedBox(
            width: 500,
            height: 100,
            child: TimelineSummaryView(segments: segments, totalTime: 70)
         ),
       ),
     ));

     expect(find.byType(HorizontalJigsawSegment), findsNWidgets(2));

     // Check for duration text
     // 5 min
     expect(find.text('5'), findsOneWidget);
     // 65 min -> 1h 5m
     expect(find.text('1h 5m'), findsOneWidget);

     // Check that duration text is inside the segment (Column)
     final segmentsWidgets = tester.widgetList<HorizontalJigsawSegment>(find.byType(HorizontalJigsawSegment)).toList();

     // First segment
     final col1 = find.descendant(of: find.byWidget(segmentsWidgets[0]), matching: find.byType(Column));
     expect(col1, findsOneWidget);
     expect(find.descendant(of: col1, matching: find.text('5')), findsOneWidget);

     // Second segment
     final col2 = find.descendant(of: find.byWidget(segmentsWidgets[1]), matching: find.byType(Column));
     expect(col2, findsOneWidget);
     expect(find.descendant(of: col2, matching: find.text('1h 5m')), findsOneWidget);

     // Check font size
     final Text text1 = tester.widget(find.text('5'));
     expect(text1.style?.fontSize, 10.0);

     final Text text2 = tester.widget(find.text('1h 5m'));
     expect(text2.style?.fontSize, 10.0);
  });
}
