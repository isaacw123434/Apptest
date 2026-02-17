import 'package:client/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Segment', () {
    test('copyWith creates a copy with updated values', () {
      final segment = Segment(
        mode: 'walk',
        label: 'Walk to station',
        lineColor: '#000000',
        iconId: 'footprints',
        time: 10,
        cost: 5.0,
      );

      final updatedSegment = segment.copyWith(
        mode: 'bike',
        time: 5,
      );

      expect(updatedSegment.mode, 'bike');
      expect(updatedSegment.time, 5);
      expect(updatedSegment.label, 'Walk to station'); // Should remain same
      expect(updatedSegment.cost, 5.0); // Should remain same
    });

    test('copyWith handles nullable fields correctly', () {
       final segment = Segment(
        mode: 'walk',
        label: 'Walk to station',
        lineColor: '#000000',
        iconId: 'footprints',
        time: 10,
        from: 'Home',
      );

      final updatedSegment = segment.copyWith(from: 'Office');
      expect(updatedSegment.from, 'Office');

      final sameSegment = segment.copyWith();
      expect(sameSegment.from, 'Home');
    });

    test('copyWith handles lists correctly', () {
      final path = [LatLng(1.0, 1.0), LatLng(2.0, 2.0)];
      final segment = Segment(
        mode: 'walk',
        label: 'Walk to station',
        lineColor: '#000000',
        iconId: 'footprints',
        time: 10,
        path: path,
      );

      final newPath = [LatLng(3.0, 3.0)];
      final updatedSegment = segment.copyWith(path: newPath);

      expect(updatedSegment.path, newPath);
      expect(updatedSegment.path!.length, 1);

      final sameSegment = segment.copyWith();
      expect(sameSegment.path, path);
    });
  });
}
