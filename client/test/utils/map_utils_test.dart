import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:client/utils/map_utils.dart';
import 'package:client/models.dart';

void main() {
  group('MapUtils', () {
    group('calculateBounds', () {
      test('returns null for empty list', () {
        expect(MapUtils.calculateBounds([]), isNull);
      });

      test('returns bounds for single point', () {
        final point = LatLng(10, 20);
        final bounds = MapUtils.calculateBounds([point]);
        expect(bounds, isNotNull);
        expect(bounds!.southWest, equals(point));
        expect(bounds.northEast, equals(point));
      });

      test('returns correct bounds for multiple points', () {
        final points = [
          LatLng(10, 20),
          LatLng(30, 40),
          LatLng(0, 0),
        ];
        final bounds = MapUtils.calculateBounds(points);
        expect(bounds, isNotNull);
        expect(bounds!.southWest.latitude, equals(0));
        expect(bounds.southWest.longitude, equals(0));
        expect(bounds.northEast.latitude, equals(30));
        expect(bounds.northEast.longitude, equals(40));
      });
    });

    group('calculateBoundsFromSegments', () {
      test('returns null for empty segments list', () {
        expect(MapUtils.calculateBoundsFromSegments([]), isNull);
      });

      test('returns null for segments with no path', () {
        final segments = [
          Segment(
            mode: 'walk',
            label: 'Walk',
            lineColor: '000000',
            iconId: 'walk',
            time: 10,
            path: null,
          ),
        ];
        expect(MapUtils.calculateBoundsFromSegments(segments), isNull);
      });

      test('returns correct bounds for valid segments', () {
        final segments = [
          Segment(
            mode: 'walk',
            label: 'Walk',
            lineColor: '000000',
            iconId: 'walk',
            time: 10,
            path: [LatLng(0, 0), LatLng(10, 10)],
          ),
          Segment(
            mode: 'walk',
            label: 'Walk',
            lineColor: '000000',
            iconId: 'walk',
            time: 10,
            path: [LatLng(20, 20)],
          ),
        ];
        final bounds = MapUtils.calculateBoundsFromSegments(segments);
        expect(bounds, isNotNull);
        expect(bounds!.southWest.latitude, equals(0));
        expect(bounds.southWest.longitude, equals(0));
        expect(bounds.northEast.latitude, equals(20));
        expect(bounds.northEast.longitude, equals(20));
      });
    });
  });
}
