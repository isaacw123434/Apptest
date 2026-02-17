import 'package:client/widgets/horizontal_jigsaw_schematic.dart';
import 'package:client/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HorizontalJigsawSchematic minWidth calculation avoids clipping for "CrossCountry + EMR"', (WidgetTester tester) async {
     final segments = [
       Segment(mode: 'train', label: 'CrossCountry + EMR', lineColor: '#FF0000', iconId: 'train', time: 10),
     ];

     // We constrain the parent width to be very small to force the widget to use its calculated minWidth
     // and enable scrolling.
     await tester.pumpWidget(MaterialApp(
       home: Scaffold(
         body: SizedBox(
           width: 10,
           child: HorizontalJigsawSchematic(segments: segments, totalTime: 10),
         ),
       ),
     ));

     // Find the SizedBox wrapping the segment (inside the Row)
     final segmentFinder = find.byType(HorizontalJigsawSegment);
     final sizedBoxFinder = find.ancestor(of: segmentFinder, matching: find.byType(SizedBox));
     final SizedBox sizedBox = tester.widget(sizedBoxFinder.first);

     // Find the Text widget
     final textFinder = find.text('CrossCountry + EMR');
     expect(textFinder, findsOneWidget);

     // We can try to measure the text width using TextPainter with the same style as in the widget
     final textScaler = tester.binding.platformDispatcher.textScaleFactor; // Deprecated but accessible via context
     // In test, usually 1.0.

     const double fontSize = 10.0;
     final textPainter = TextPainter(
        text: const TextSpan(
          text: 'CrossCountry + EMR',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.linear(1.0),
        maxLines: 1,
      )..layout();

      // Calculate expected minWidth based on the formula in the code
      // isFirst=true, isLast=true
      // paddingLeft = 6.0
      // paddingRight = 6.0
      // contentBase = 16.0 (Icon) + 2.0 (Spacing) = 18.0
      // maxContentWidth = 18.0 + textPainter.width
      // minW = (6.0 + maxContentWidth + 6.0 + 0.5).ceilToDouble() + 2.0;

      double contentBase = 18.0;
      double maxContentWidth = contentBase + textPainter.width;
      double expectedMinW = (6.0 + maxContentWidth + 6.0 + 0.5).ceilToDouble() + 4.0;

      // We expect the actual width to match the logic
      expect(sizedBox.width, expectedMinW);
  });
}
