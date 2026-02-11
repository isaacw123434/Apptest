import 'package:client/screens/direct_drive_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DirectDrivePage renders info boxes without overflow on narrow screen', (WidgetTester tester) async {
    // Set screen size to narrow width (e.g. 320 logical pixels)
    tester.view.physicalSize = const Size(320 * 3, 800 * 3); // 3x pixel ratio
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(const MaterialApp(
      home: DirectDrivePage(),
    ));

    // Wait for the mock API delay (500ms) plus a bit
    await tester.pump(const Duration(milliseconds: 600));

    // Verify that the info boxes are present
    expect(find.text('COST'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('DISTANCE'), findsOneWidget);
    expect(find.text('CO₂'), findsOneWidget);

    // Verify that the value texts are present (based on mock data)
    // Cost: 39.15
    expect(find.text('£39.15'), findsOneWidget);
    // Time: 110 min -> 1hr 50m
    expect(find.text('1hr 50m'), findsOneWidget);
    // Distance: 87.31
    expect(find.text('87.31 mi'), findsOneWidget);
    // CO2: 23.89
    expect(find.text('23.89 kg'), findsOneWidget);

    // Check for overflow errors (Flutter test framework catches render overflows as exceptions usually,
    // or prints them to console. takeException() might not catch layout overflows unless configured)

    // Reset window size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
