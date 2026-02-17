
import 'package:flutter_test/flutter_test.dart';
import 'package:client/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetchInitData returns InitData with paths', () async {
    final apiService = ApiService();
    final initData = await apiService.fetchInitData();

    // Check First Mile (Bus)
    final firstMile = initData.segmentOptions.firstMile;
    final busLeg = firstMile.firstWhere((leg) => leg.id == 'bus');
    final busSegment = busLeg.segments.first;

    expect(busSegment.path, isNotNull);
    expect(busSegment.path!.isNotEmpty, isTrue);

    // Check Main Leg (Train)
    final mainLeg = initData.segmentOptions.mainLeg;
    final mainSegment = mainLeg.segments.first;

    expect(mainSegment.path, isNotNull);
    expect(mainSegment.path!.isNotEmpty, isTrue);
  });

  test('searchJourneys smart tab sorting', () async {
    final apiService = ApiService();
    final selectedModes = {
      'train': true,
      'bus': true,
      'car': true,
      'taxi': true,
      'bike': true,
    };

    final results = await apiService.searchJourneys(
      tab: 'smart',
      selectedModes: selectedModes,
    );

    expect(results, isNotEmpty);

    // Helper to calc score
    double getScore(r) => r.cost + (r.time * 0.3) + (r.risk * 20.0);

    // 1. Verify the first result is the absolute best (lowest score)
    // Because Diversity First picks the best of the best group first.
    if (results.isNotEmpty) {
      double bestScore = getScore(results.first);
      for (var r in results) {
        expect(bestScore <= getScore(r), isTrue,
          reason: 'First result should have the best score');
      }
    }

    // 2. Verify that WITHIN the same anchor, results are sorted by score
    // Diversity logic interleaves anchors, but shouldn't reorder within an anchor
    Map<String, double> lastScoreByAnchor = {};

    for (var r in results) {
      double score = getScore(r);
      if (lastScoreByAnchor.containsKey(r.anchor)) {
        expect(score >= lastScoreByAnchor[r.anchor]!, isTrue,
          reason: 'Results with same anchor (${r.anchor}) should be sorted by score');
      }
      lastScoreByAnchor[r.anchor] = score;
    }
  });
}
