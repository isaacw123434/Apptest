import 'package:flutter_test/flutter_test.dart';
import 'package:client/services/api_service.dart';

void main() {
  test('train_walk_headingley walk segment has no path', () async {
    final apiService = ApiService();
    final initData = await apiService.fetchInitData();
    final leg = initData.segmentOptions.firstMile.firstWhere((l) => l.id == 'train_walk_headingley');
    final walkSegment = leg.segments.firstWhere((s) => s.mode == 'walk');

    // We expect the path to be null because the original path was incorrect (Start -> Leeds)
    // and we want to remove it to avoid double lines.
    expect(walkSegment.path, isNull);
  });

  test('train_uber_headingley taxi segment has no path', () async {
    final apiService = ApiService();
    final initData = await apiService.fetchInitData();
    final leg = initData.segmentOptions.firstMile.firstWhere((l) => l.id == 'train_uber_headingley');
    final taxiSegment = leg.segments.firstWhere((s) => s.mode == 'taxi');

    // Similar to above, we expect no path for the taxi segment.
    expect(taxiSegment.path, isNull);
  });
}
