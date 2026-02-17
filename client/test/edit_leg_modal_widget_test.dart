import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';

void main() {
  testWidgets('LegSelectorModal displays options and handles selection', (
    WidgetTester tester,
  ) async {
    final option1 = Leg(
      id: 'opt1',
      label: 'Option 1',
      time: 20,
      cost: 5.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'footprints',
      lineColor: '#000000',
      segments: [],
    );
    final option2 = Leg(
      id: 'opt2',
      label: 'Option 2',
      time: 10,
      cost: 10.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'car',
      lineColor: '#000000',
      segments: [],
    );

    final options = [option1, option2];
    Leg? selectedLeg;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LegSelectorModal(
            options: options,
            currentLeg: option1,
            title: 'Test Modal',
            onSelect: (leg) {
              selectedLeg = leg;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Test Modal'), findsOneWidget);

    // Verify Options
    expect(find.text('Option 1'), findsOneWidget);
    expect(find.text('Option 2'), findsOneWidget);

    // Tap Option 2
    await tester.tap(find.text('Option 2'));
    await tester.pumpAndSettle();

    // Verify selection
    expect(selectedLeg, isNotNull);
    expect(selectedLeg!.id, 'opt2');
  });

  testWidgets('LegSelectorModal sorting works', (WidgetTester tester) async {
    // Create options with distinct costs and times
    final cheapSlow = Leg(
      id: 'cheap',
      label: 'Cheap',
      time: 60,
      cost: 1.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'bus',
      lineColor: '#000000',
      segments: [],
    );
    final expensiveFast = Leg(
      id: 'fast',
      label: 'Fast',
      time: 10,
      cost: 100.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'car',
      lineColor: '#000000',
      segments: [],
    );

    final options = [expensiveFast, cheapSlow]; // Initial order: Fast, Cheap

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LegSelectorModal(
            options: options,
            currentLeg: cheapSlow,
            title: 'Sort Test',
            onSelect: (_) {},
          ),
        ),
      ),
    );

    // Default sort is Best Value: (1 + 60*0.15 = 10) vs (100 + 10*0.15 = 101.5). Cheap comes first.
    // Verify order by finding widgets location
    final cheapFinder = find.text('Cheap');
    final fastFinder = find.text('Fast');

    // We expect 'Cheap' to appear before 'Fast' (visually higher = lower Y)
    expect(
      tester.getTopLeft(cheapFinder).dy,
      lessThan(tester.getTopLeft(fastFinder).dy),
    );

    // Change Sort to Lowest Time
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lowest Time').last); // Dropdown menu item
    await tester.pumpAndSettle();

    // Now Fast (10m) should be first
    expect(
      tester.getTopLeft(fastFinder).dy,
      lessThan(tester.getTopLeft(cheapFinder).dy),
    );

    // Change Sort to Lowest Cost
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lowest Cost').last);
    await tester.pumpAndSettle();

    // Now Cheap (£1) should be first
    expect(
      tester.getTopLeft(cheapFinder).dy,
      lessThan(tester.getTopLeft(fastFinder).dy),
    );
  });

  testWidgets('LegSelectorModal uses labelBuilder', (
    WidgetTester tester,
  ) async {
    final option1 = Leg(
      id: 'opt1',
      label: 'Drive to Eastrington + Train',
      time: 20,
      cost: 5.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'footprints',
      lineColor: '#000000',
      segments: [],
    );

    final options = [option1];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LegSelectorModal(
            options: options,
            currentLeg: option1,
            title: 'Label Builder Test',
            onSelect: (_) {},
            labelBuilder: (leg) {
              if (leg.label.contains('Eastrington')) {
                return 'Eastrington to Leeds';
              }
              return leg.label;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify modified label is displayed
    expect(find.text('Eastrington to Leeds'), findsOneWidget);
    // Verify original label is NOT displayed
    expect(find.text('Drive to Eastrington + Train'), findsNothing);
  });
}
