import 'package:client/screens/horizontal_jigsaw_schematic.dart';
import 'package:client/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HorizontalJigsawSchematic has correct padding', (WidgetTester tester) async {
     final segments = [
       Segment(mode: 'walk', label: 'Walk', lineColor: '#000000', iconId: 'footprints', time: 5),
     ];

     await tester.pumpWidget(MaterialApp(
       home: Scaffold(
         body: HorizontalJigsawSchematic(segments: segments, totalTime: 10),
       ),
     ));

     // Find HorizontalJigsawSegment
     final segmentFinder = find.byType(HorizontalJigsawSegment);
     expect(segmentFinder, findsOneWidget);

     // Verify padding
     // HorizontalJigsawSegment builds a CustomPaint with a child Padding.
     // So we look for Padding inside HorizontalJigsawSegment.
     final paddingFinder = find.descendant(of: segmentFinder, matching: find.byType(Padding));
     expect(paddingFinder, findsOneWidget);

     final Padding paddingWidget = tester.widget(paddingFinder);
     // Since there is only one segment, isFirst=true, isLast=true.
     // left: 6, right: 6.
     // top: 1, bottom: 1.
     expect(paddingWidget.padding, const EdgeInsets.only(left: 6, right: 6, top: 1, bottom: 1));

     // Check internal spacing between Icon and Text
     final rowFinder = find.descendant(of: segmentFinder, matching: find.byType(Row));
     final sizedBoxFinder = find.descendant(of: rowFinder, matching: find.byType(SizedBox));
     // The Row contains [Icon, SizedBox(width: 4), Flexible(Text)]
     // However, `find.byType(SizedBox)` might find other SizedBoxes if any.
     // The first SizedBox is likely the Icon (size 16). The second one is the spacer (size 2).
     final sizedBoxes = sizedBoxFinder.evaluate().map((e) => e.widget as SizedBox).toList();
     // We expect to find a SizedBox with width 2.0
     expect(sizedBoxes.any((box) => box.width == 2.0), isTrue, reason: 'Expected to find a SizedBox with width 2.0');
  });

  testWidgets('HorizontalJigsawSchematic layouts multiple segments', (WidgetTester tester) async {
     final segments = [
       Segment(mode: 'walk', label: 'Walk', lineColor: '#000000', iconId: 'footprints', time: 5),
       Segment(mode: 'bus', label: 'Bus', lineColor: '#FF0000', iconId: 'bus', time: 20),
     ];

     await tester.pumpWidget(MaterialApp(
       home: Scaffold(
         body: SizedBox(
            width: 500,
            height: 100,
            child: HorizontalJigsawSchematic(segments: segments, totalTime: 25)
         ),
       ),
     ));

     expect(find.byType(HorizontalJigsawSegment), findsNWidgets(2));
     expect(find.text('Walk'), findsOneWidget);
     expect(find.text('Bus'), findsOneWidget);

     // Verify paddings for multi-segment
     // 1. Walk: isFirst=true, isLast=false
     // left: 6, right: 2
     final walkSegment = find.ancestor(
       of: find.text('Walk'),
       matching: find.byType(HorizontalJigsawSegment),
     );
     final walkPadding = tester.widget<Padding>(
       find.descendant(of: walkSegment, matching: find.byType(Padding))
     );
     expect(walkPadding.padding, const EdgeInsets.only(left: 6, right: 2, top: 1, bottom: 1));

     // 2. Bus: isFirst=false, isLast=true
     // left: 16, right: 6
     final busSegment = find.ancestor(
       of: find.text('Bus'),
       matching: find.byType(HorizontalJigsawSegment),
     );
     final busPadding = tester.widget<Padding>(
       find.descendant(of: busSegment, matching: find.byType(Padding))
     );
     expect(busPadding.padding, const EdgeInsets.only(left: 16, right: 6, top: 1, bottom: 1));
  });
}
