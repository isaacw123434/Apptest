import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';

void main() {
  group('Leg Model', () {
    test('copyWith creates a new instance with updated fields', () {
      final leg = Leg(
        id: '1',
        label: 'Route 1',
        time: 10,
        cost: 5.0,
        distance: 100.0,
        riskScore: 1,
        iconId: 'bus',
        lineColor: '#000000',
        segments: [],
      );

      final newLeg = leg.copyWith(
        id: '2',
        label: 'Route 2',
        time: 20,
        cost: 10.0,
        distance: 200.0,
        riskScore: 2,
        iconId: 'train',
        lineColor: '#FFFFFF',
      );

      expect(newLeg.id, '2');
      expect(newLeg.label, 'Route 2');
      expect(newLeg.time, 20);
      expect(newLeg.cost, 10.0);
      expect(newLeg.distance, 200.0);
      expect(newLeg.riskScore, 2);
      expect(newLeg.iconId, 'train');
      expect(newLeg.lineColor, '#FFFFFF');

      // Unchanged fields check (though here we changed all required fields except segments)
      expect(newLeg.segments, leg.segments);
    });

    test('copyWith preserves existing fields when null is passed', () {
      final leg = Leg(
        id: '1',
        label: 'Route 1',
        time: 10,
        cost: 5.0,
        distance: 100.0,
        riskScore: 1,
        iconId: 'bus',
        lineColor: '#000000',
        segments: [],
        detail: 'Details',
      );

      final newLeg = leg.copyWith(
        id: '2',
        // label is null, should keep 'Route 1'
      );

      expect(newLeg.id, '2');
      expect(newLeg.label, 'Route 1');
      expect(newLeg.detail, 'Details');
      expect(newLeg.time, 10);
    });

    test('copyWith handles optional fields correctly', () {
      final leg = Leg(
        id: '1',
        label: 'Route 1',
        time: 10,
        cost: 5.0,
        distance: 100.0,
        riskScore: 1,
        iconId: 'bus',
        lineColor: '#000000',
        segments: [],
        detail: 'Old Detail',
        co2: 1.5,
      );

      final newLeg = leg.copyWith(
        detail: 'New Detail',
        co2: 2.5,
      );

      expect(newLeg.detail, 'New Detail');
      expect(newLeg.co2, 2.5);
      expect(newLeg.id, '1');
    });
  });
}
