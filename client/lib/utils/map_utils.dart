import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models.dart';

class MapUtils {
  /// Calculates bounds for a list of LatLng points.
  /// Returns null if points list is empty.
  static LatLngBounds? calculateBounds(List<LatLng> points) {
    if (points.isEmpty) return null;
    return LatLngBounds.fromPoints(points);
  }

  /// Calculates bounds for a list of segments.
  /// Returns null if no valid points found in segments.
  static LatLngBounds? calculateBoundsFromSegments(List<Segment> segments) {
    final points = <LatLng>[];
    for (final segment in segments) {
      if (segment.path != null) {
        points.addAll(segment.path!);
      }
    }
    return calculateBounds(points);
  }
}
