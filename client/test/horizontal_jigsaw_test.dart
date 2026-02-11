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
     // left: 20, right: 20.
     // top: 1, bottom: 1.
     expect(paddingWidget.padding, const EdgeInsets.only(left: 20, right: 20, top: 1, bottom: 1));
  });
}
