import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import '../lib/utils/polyline.dart';

void main() {
  group('Polyline Decoding', () {
    test('Decodes simple polyline', () {
      // Example from Google Polyline Algorithm docs
      // Points: (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
      // Encoded: _p~iF~ps|U_ulLnnqC_mqNvxq`@
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final points = decodePolyline(encoded);

      expect(points.length, 3);
      expect(points[0].latitude, closeTo(38.5, 0.00001));
      expect(points[0].longitude, closeTo(-120.2, 0.00001));
      expect(points[1].latitude, closeTo(40.7, 0.00001));
      expect(points[1].longitude, closeTo(-120.95, 0.00001));
      expect(points[2].latitude, closeTo(43.252, 0.00001));
      expect(points[2].longitude, closeTo(-126.453, 0.00001));
    });

    test('Decodes polyline with large coordinates (mock data sample)', () {
      // Using a segment from mock_data that was problematic if not escaped correctly
      // e.g. "srogInltHS~EpCvFjBd@fAAdCoD|B_HxDVrL}D_BeLjGyPvDsI~EkCnFi@pHlBbXgJtSLhEbBvHcP~GaSlO{f@hB..."
      // We just test that it decodes to something valid
      const encoded = r"srogInltHS~EpCvFjBd@fAAdCoD|B_HxDVrL}D_BeLjGyPvDsI~EkCnFi@pHlBbXgJtSLhEbBvHcP~GaSlO{f@hB";
      final points = decodePolyline(encoded);
      expect(points, isNotEmpty);
      for (var p in points) {
        expect(p.latitude, inInclusiveRange(-90, 90));
        expect(p.longitude, inInclusiveRange(-180, 180));
      }
    });
  });
}
