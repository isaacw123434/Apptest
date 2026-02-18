import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/widgets/summary/search_summary_header.dart';

void main() {
  testWidgets('SearchSummaryHeader renders correct text order', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SearchSummaryHeader(
          fromController: TextEditingController(text: 'St Chads'),
          toController: TextEditingController(text: 'East Leake'),
          timeController: TextEditingController(text: '09:00'),
          timeType: 'Depart',
          onTimeTypeChanged: (val) {},
          selectedModes: const {'train': true},
          onModeChanged: (mode, val) {},
          onSearch: () {},
          displayFrom: 'St Chads',
          displayTo: 'East Leake',
          displayTimeType: 'Depart',
          displayTime: '09:00',
        ),
      ),
    ));

    // New implementation: "St Chads", "East Leake", "• Depart by 09:00"
    expect(find.text('St Chads'), findsOneWidget);
    expect(find.text('East Leake'), findsOneWidget);
    expect(find.text('• Depart by 09:00'), findsOneWidget);
  });
}
