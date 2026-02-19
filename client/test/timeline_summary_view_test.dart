import 'package:client/widgets/timeline_summary_view.dart';
import 'package:client/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TimelineSummaryView has correct padding', (WidgetTester tester) async {
     final segments = [
       Segment(mode: 'walk', label: 'Walk', lineColor: '#000000', iconId: 'footprints', time: 5),
     ];

     await tester.pumpWidget(MaterialApp(
       home: Scaffold(
         body: TimelineSummaryView(segments: segments, totalTime: 10),
       ),
     ));

     // Find HorizontalJigsawSegment
     final segmentFinder = find.byType(HorizontalJigsawSegment);
     expect(segmentFinder, findsOneWidget);

     // Verify padding
     // HorizontalJigsawSegment builds a CustomPaint with a child Padding.
     // But now it has another inner Padding.
     // We want the outermost Padding inside HorizontalJigsawSegment which handles the jigsaw offsets.

     // Find all Padding widgets inside the segment
     final paddingFinder = find.descendant(of: segmentFinder, matching: find.byType(Padding));
     // We expect 2 paddings now (outer offset + inner vertical padding)
     expect(paddingFinder, findsNWidgets(2));

     // The first one found by descendant should be the outer one (closest to parent in tree traversal usually, but let's be safe)
     // Actually, verifying the one that matches our expected EdgeInsets is safer or taking the first if we know structure.
     // In HorizontalJigsawSegment build: CustomPaint -> Padding (outer) -> Padding (inner/vertical) -> Column

     final Padding outerPadding = tester.widget(paddingFinder.first);
     // Since there is only one segment, isFirst=true, isLast=true.
     // left: 6, right: 6.
     // top: 1, bottom: 1.
     expect(outerPadding.padding, const EdgeInsets.only(left: 6, right: 6, top: 1, bottom: 1));
  });

  testWidgets('TimelineSummaryView layouts multiple segments', (WidgetTester tester) async {
     final segments = [
       Segment(mode: 'walk', label: 'Walk', lineColor: '#000000', iconId: 'footprints', time: 5),
       Segment(mode: 'bus', label: 'Bus', lineColor: '#FF0000', iconId: 'bus', time: 20),
     ];

     await tester.pumpWidget(MaterialApp(
       home: Scaffold(
         body: SizedBox(
            width: 500,
            height: 100,
            child: TimelineSummaryView(segments: segments, totalTime: 25)
         ),
       ),
     ));

     expect(find.byType(HorizontalJigsawSegment), findsNWidgets(2));
     expect(find.text('Walk'), findsNothing); // Walk label is now hidden
     expect(find.text('Bus'), findsOneWidget);

     // Verify paddings for multi-segment
     // 1. Walk: isFirst=true, isLast=false
     // left: 6, right: 2.0
     final segmentsWidgets = tester.widgetList<HorizontalJigsawSegment>(find.byType(HorizontalJigsawSegment)).toList();

     // Find paddings for first segment
     final walkPaddings = find.descendant(of: find.byWidget(segmentsWidgets[0]), matching: find.byType(Padding));
     final Padding walkOuterPadding = tester.widget(walkPaddings.first);

     expect(walkOuterPadding.padding, const EdgeInsets.only(left: 6, right: 4.0, top: 1, bottom: 1));

     // 2. Bus: isFirst=false, isLast=true
     // left: 8.25 ((overlap + 1) * 0.75) where overlap is 10.0, right: 6
     final busSegment = find.ancestor(
       of: find.text('Bus'),
       matching: find.byType(HorizontalJigsawSegment),
     );

     final busPaddings = find.descendant(of: busSegment, matching: find.byType(Padding));
     final Padding busOuterPadding = tester.widget(busPaddings.first);

     expect(busOuterPadding.padding, const EdgeInsets.only(left: 8.25, right: 6, top: 1, bottom: 1));
  });

  testWidgets('TimelineSummaryView hides all walk labels', (WidgetTester tester) async {
     final segments = [
       Segment(mode: 'walk', label: 'Walk', lineColor: '#000000', iconId: 'footprints', time: 5),
       Segment(mode: 'train', label: 'Train', lineColor: '#FF0000', iconId: 'train', time: 20),
       Segment(mode: 'walk', label: 'Walk', lineColor: '#000000', iconId: 'footprints', time: 5),
     ];

     await tester.pumpWidget(MaterialApp(
       home: Scaffold(
         body: SizedBox(
            width: 500,
            height: 100,
            child: TimelineSummaryView(segments: segments, totalTime: 30)
         ),
       ),
     ));

     expect(find.byType(HorizontalJigsawSegment), findsNWidgets(3));

     // Should find NO 'Walk' text (even for the first one)
     expect(find.text('Walk'), findsNothing);

     // Should find 'Train'
     expect(find.text('Train'), findsOneWidget);

     // Verify segments have icons but no text
     final segmentsWidgets = tester.widgetList<HorizontalJigsawSegment>(find.byType(HorizontalJigsawSegment)).toList();
     expect(segmentsWidgets.length, 3);

     // First segment (Walk)
     final row1 = find.descendant(of: find.byWidget(segmentsWidgets[0]), matching: find.byType(Row));
     expect(find.descendant(of: row1, matching: find.text('Walk')), findsNothing);
     expect(find.descendant(of: row1, matching: find.byType(Icon)), findsOneWidget);

     // Third segment (Walk 2)
     final row3 = find.descendant(of: find.byWidget(segmentsWidgets[2]), matching: find.byType(Row));
     expect(find.descendant(of: row3, matching: find.text('Walk')), findsNothing);
     // Should still have icon
     expect(find.descendant(of: row3, matching: find.byType(Icon)), findsOneWidget);
  });
}
