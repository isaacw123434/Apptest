import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/widgets/detail/leg_selector_modal.dart';

void main() {
  testWidgets('LegSelectorModal displays groups and handles selection', (WidgetTester tester) async {
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

    Leg? selectedLeg;

    final groups = [
      LegOptionGroup(
        title: 'Option 1',
        icon: Icons.directions_walk,
        options: [option1],
      ),
      LegOptionGroup(
        title: 'Option 2',
        icon: Icons.directions_car,
        options: [option2],
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LegSelectorModal(
          groups: groups,
          currentLeg: option1,
          title: 'Test Modal',
          onSelect: (leg) {
            selectedLeg = leg;
          },
        ),
      ),
    ));
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

  testWidgets('LegSelectorModal grouped options expand and select', (WidgetTester tester) async {
    final driveOpt = Leg(
      id: 'train_drive_brough',
      label: 'Drive to Brough Station',
      time: 60,
      cost: 12.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'car',
      lineColor: '#000000',
      segments: [],
    );
    final cycleOpt = Leg(
      id: 'train_cycle_brough',
      label: 'Cycle to Brough Station',
      time: 80,
      cost: 5.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'bike',
      lineColor: '#000000',
      segments: [],
    );

    Leg? selectedLeg;

    final groups = [
      LegOptionGroup(
        title: 'Via Brough',
        subtitle: 'Train to Leeds',
        icon: Icons.train,
        options: [driveOpt, cycleOpt],
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LegSelectorModal(
          groups: groups,
          currentLeg: driveOpt,
          title: 'Choose Route',
          onSelect: (leg) {
            selectedLeg = leg;
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Group title visible
    expect(find.text('Via Brough'), findsOneWidget);

    // Since driveOpt is current, group auto-expands - access mode chips visible
    expect(find.text('Drive'), findsOneWidget);
    expect(find.text('Cycle'), findsOneWidget);

    // Tap cycle chip
    await tester.tap(find.text('Cycle'));
    await tester.pumpAndSettle();

    expect(selectedLeg, isNotNull);
    expect(selectedLeg!.id, 'train_cycle_brough');
  });

  testWidgets('LegSelectorModal single option card shows diff', (WidgetTester tester) async {
    final current = Leg(
      id: 'opt1',
      label: 'Current',
      time: 20,
      cost: 5.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'footprints',
      lineColor: '#000000',
      segments: [],
    );
    final other = Leg(
      id: 'opt2',
      label: 'Other',
      time: 30,
      cost: 8.0,
      distance: 1.0,
      riskScore: 0,
      iconId: 'car',
      lineColor: '#000000',
      segments: [],
    );

    final groups = [
      LegOptionGroup(title: 'Current', icon: Icons.circle, options: [current]),
      LegOptionGroup(title: 'Other', icon: Icons.circle, options: [other]),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LegSelectorModal(
          groups: groups,
          currentLeg: current,
          title: 'Test',
          onSelect: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Other option should show price diff
    expect(find.text('+£3.00'), findsOneWidget);
  });
}
