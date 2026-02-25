import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/screens/icon_comparison_page.dart';
import 'package:table_sticky_headers/table_sticky_headers.dart';

void main() {
  testWidgets('IconComparisonPage renders correctly', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(home: IconComparisonPage()));

    // Verify that the title is present
    expect(find.text('Icon Comparison'), findsOneWidget);

    // Verify that the StickyHeadersTable is present
    expect(find.byType(StickyHeadersTable), findsOneWidget);

    // Verify some column headers
    expect(find.text('Material (Default)'), findsOneWidget);
    expect(find.text('MDI'), findsOneWidget);

    // Verify some row headers
    expect(find.text('Bus'), findsOneWidget);
    expect(find.text('Train / Railway'), findsOneWidget);
  });
}
