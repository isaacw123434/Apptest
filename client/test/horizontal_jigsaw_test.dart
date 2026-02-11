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
     // left: 20, right: 4
     final walkSegment = find.ancestor(
       of: find.text('Walk'),
       matching: find.byType(HorizontalJigsawSegment),
     );
     final walkPadding = tester.widget<Padding>(
       find.descendant(of: walkSegment, matching: find.byType(Padding))
     );
     expect(walkPadding.padding, const EdgeInsets.only(left: 20, right: 4, top: 1, bottom: 1));

     // 2. Bus: isFirst=false, isLast=true
     // left: 16, right: 20
     final busSegment = find.ancestor(
       of: find.text('Bus'),
       matching: find.byType(HorizontalJigsawSegment),
     );
     final busPadding = tester.widget<Padding>(
       find.descendant(of: busSegment, matching: find.byType(Padding))
     );
     expect(busPadding.padding, const EdgeInsets.only(left: 16, right: 20, top: 1, bottom: 1));
  });
}
