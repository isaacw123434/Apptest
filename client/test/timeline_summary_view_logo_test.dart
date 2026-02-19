import 'package:client/widgets/timeline_summary_view.dart';
import 'package:client/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TimelineSummaryView does not clip EMR logo', (WidgetTester tester) async {
    final segments = [
      Segment(
        mode: 'train',
        label: 'EMR',
        lineColor: '#000000',
        iconId: 'train',
        time: 20
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimelineSummaryView(segments: segments, totalTime: 20, forceLogos: true),
      ),
    ));

    // Find the Image widget for EMR logo
    // The asset path is 'assets/EMR_Logo.png'
    final imageFinder = find.byWidgetPredicate((widget) {
      if (widget is Image) {
        final image = widget.image;
        if (image is AssetImage) {
          return image.assetName == 'assets/EMR_Logo.png';
        }
      }
      return false;
    });

    expect(imageFinder, findsOneWidget);

    // Check if the image is wrapped in a ClipOval
    final clipOvalFinder = find.ancestor(
      of: imageFinder,
      matching: find.byType(ClipOval),
    );

    // It should NOT be found after the fix.
    // For reproduction, I expect it to be found.
    expect(clipOvalFinder, findsNothing);
  });
}
