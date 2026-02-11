import 'package:flutter_test/flutter_test.dart';
import 'package:client/services/mock_data.dart';
import 'package:client/utils/polyline.dart';

void main() {
  group('Mock Data Validity', () {
    test('All polylines in mock_data.dart decode correctly', () {
      for (var route in rawRoutesData) {
        final id = route['id'];
        final polyline = route['polyline'];

        final points = decodePolyline(polyline);
        expect(points, isNotEmpty, reason: 'Route $id decoded to empty list');

        for (var p in points) {
          expect(p.latitude, isNot(isNaN), reason: 'Route $id has NaN latitude');
          expect(p.longitude, isNot(isNaN), reason: 'Route $id has NaN longitude');
          expect(p.latitude, inInclusiveRange(-90, 90), reason: 'Route $id has invalid latitude: ${p.latitude}');
          expect(p.longitude, inInclusiveRange(-180, 180), reason: 'Route $id has invalid longitude: ${p.longitude}');
        }
      }
    });
  });
}
