import 'package:flutter_test/flutter_test.dart';
import 'package:client/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('train_walk_headingley walk segment has path', () async {
    final apiService = ApiService();
    final initData = await apiService.fetchInitData();
    final leg = initData.segmentOptions.firstMile.firstWhere(
      (l) => l.id == 'train_walk_headingley',
    );

    var segments = leg.segments;
    // Handle access group if present (new logic in process_routes.py groups walk+wait+ride)
    if (segments.isNotEmpty && segments.first.mode == 'access_group') {
      segments = segments.first.subSegments ?? [];
    }

    final walkSegment = segments.firstWhere((s) => s.mode == 'walk');

    // We expect the path to be present as routes.json is the source of truth
    expect(walkSegment.path, isNotNull);
    expect(walkSegment.path, isNotEmpty);
  });

  test('train_uber_headingley taxi segment has path', () async {
    final apiService = ApiService();
    final initData = await apiService.fetchInitData();
    final leg = initData.segmentOptions.firstMile.firstWhere(
      (l) => l.id == 'train_uber_headingley',
    );
    // Note: parser maps "driving" to "car" (not "taxi")

    var segments = leg.segments;
    if (segments.isNotEmpty && segments.first.mode == 'access_group') {
      segments = segments.first.subSegments ?? [];
    }

    final taxiSegment = segments.firstWhere((s) => s.mode == 'car');

    // We expect the path to be present as routes.json is the source of truth
    expect(taxiSegment.path, isNotNull);
    expect(taxiSegment.path, isNotEmpty);
  });
}
