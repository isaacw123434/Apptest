import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/screens/detail_page.dart';

void main() {
  testWidgets('EditLegModal merges Headingley options and handles interaction', (WidgetTester tester) async {
    // Setup Mock Data
    final walkLeg = Leg(
      id: 'train_walk_headingley',
      label: 'Walk + Train',
      time: 20,
      cost: 5.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'footprints',
      lineColor: '#000000',
      segments: [
        Segment(mode: 'walk', label: 'Walk', lineColor: '#000000', iconId: 'footprints', time: 10),
        Segment(mode: 'train', label: 'Headingley Station', lineColor: '#000000', iconId: 'train', time: 10),
      ],
    );
    final uberLeg = Leg(
      id: 'train_uber_headingley',
      label: 'Uber + Train',
      time: 10,
      cost: 10.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'car',
      lineColor: '#000000',
      segments: [
        Segment(mode: 'car', label: 'Uber', lineColor: '#000000', iconId: 'car', time: 5),
        Segment(mode: 'train', label: 'Headingley Station', lineColor: '#000000', iconId: 'train', time: 5),
      ],
    );
    final otherLeg = Leg(
      id: 'bus_option',
      label: 'Bus',
      time: 30,
      cost: 2.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'bus',
      lineColor: '#000000',
      segments: [],
    );

    final options = [walkLeg, uberLeg, otherLeg];
    Leg? selectedLeg;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditLegModal(
          options: options,
          currentLeg: walkLeg,
          legType: 'firstMile',
          onSelect: (leg) {
            selectedLeg = leg;
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Verify "To Headingley Station" exists
    expect(find.text('To Headingley Station'), findsOneWidget);
    // Verify "Bus" exists
    expect(find.text('Bus'), findsOneWidget);
    // Verify original separate options are NOT visible directly (they should be merged)
    expect(find.text('Walk + Train'), findsNothing);
    expect(find.text('Uber + Train'), findsNothing);

    // Tap "To Headingley Station"
    await tester.tap(find.text('To Headingley Station'));
    await tester.pumpAndSettle();

    // Verify Dialog appears with "Walk" and "Uber" options
    expect(find.text('To Headingley Station'), findsWidgets);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text('Uber'), findsOneWidget);

    // Tap "Uber"
    await tester.tap(find.text('Uber'));
    await tester.pumpAndSettle();

    // Verify selection
    expect(selectedLeg, isNotNull);
    expect(selectedLeg!.id, 'train_uber_headingley');
  });

  testWidgets('EditLegModal sorting works', (WidgetTester tester) async {
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

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EditLegModal(
            options: options,
            currentLeg: cheapSlow,
            legType: 'firstMile',
            onSelect: (_) {},
          ),
        ),
      ));

      // Default sort is Best Value: (1 + 60*0.15 = 10) vs (100 + 10*0.15 = 101.5). Cheap comes first.
      // Verify order by finding widgets location
      final cheapFinder = find.text('Cheap');
      final fastFinder = find.text('Fast');

      // We expect 'Cheap' to appear before 'Fast' (visually higher = lower Y)
      expect(tester.getTopLeft(cheapFinder).dy, lessThan(tester.getTopLeft(fastFinder).dy));

      // Change Sort to Lowest Time
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lowest Time').last); // Dropdown menu item
      await tester.pumpAndSettle();

      // Now Fast (10m) should be first
      expect(tester.getTopLeft(fastFinder).dy, lessThan(tester.getTopLeft(cheapFinder).dy));

      // Change Sort to Lowest Cost
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lowest Cost').last);
      await tester.pumpAndSettle();

      // Now Cheap (£1) should be first
      expect(tester.getTopLeft(cheapFinder).dy, lessThan(tester.getTopLeft(fastFinder).dy));
  });
}
