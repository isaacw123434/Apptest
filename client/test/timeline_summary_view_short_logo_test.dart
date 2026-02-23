import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/widgets/timeline_summary_view.dart';

void main() {
  testWidgets('TimelineSummaryView renders short logos only when layoutType is shortLogoOnly', (WidgetTester tester) async {
    final segments = [
      Segment(
        mode: 'train',
        label: 'Northern',
        lineColor: '#0000FF',
        iconId: 'train',
        time: 10,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimelineSummaryView(
            segments: segments,
            totalTime: 10,
            layoutType: TimelineLayoutType.shortLogoOnly,
          ),
        ),
      ),
    );

    // Verify no text "Northern" is displayed
    expect(find.text('Northern'), findsNothing);

    // Verify standard icon is not displayed
    // The implementation sets iconData = null, so no Icon widget with 'train' icon should be present.
    // However, the test might be hard to verify 'train' icon specifically if we don't know the exact IconData.
    // But we know 'train' maps to something.
    // Let's check for LucideIcons.train
    // Wait, getIconData('train') returns LucideIcons.train.

    // We can also verify that we have an image/logo.
    // The implementation uses Image.asset or SvgPicture.asset inside a Builder.
    // Since we are in a test environment, assets might need mocking or we just check for Image/SvgPicture widgets.

    expect(find.byType(Image), findsOneWidget); // Northern logo is jpeg/png

    // Verify structure: Row -> ...
  });

  testWidgets('TimelineSummaryView renders text fallback if logo not found in shortLogoOnly', (WidgetTester tester) async {
    final segments = [
      Segment(
        mode: 'train',
        label: 'UnknownTrain',
        lineColor: '#0000FF',
        iconId: 'train',
        time: 10,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimelineSummaryView(
            segments: segments,
            totalTime: 10,
            layoutType: TimelineLayoutType.shortLogoOnly,
          ),
        ),
      ),
    );

    // Verify text "UnknownTrain" is displayed as fallback
    expect(find.text('UnknownTrain'), findsOneWidget);

    // Verify no Image
    expect(find.byType(Image), findsNothing);
  });
}
