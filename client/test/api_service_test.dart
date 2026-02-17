
import 'package:flutter_test/flutter_test.dart';
import 'package:client/services/api_service.dart';
import 'package:client/models.dart';

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

    // Check if sorted by updated logic (Diversity First)
    // 1. Group by anchor
    Map<String, List<JourneyResult>> grouped = {};
    for (var res in results) {
        if (!grouped.containsKey(res.anchor)) {
          grouped[res.anchor] = [];
        }
        grouped[res.anchor]!.add(res);
    }

    // 2. Verify within-group sorting
    grouped.forEach((anchor, group) {
        for (int i = 0; i < group.length - 1; i++) {
            double scoreA = group[i].cost + (group[i].time * 0.3) + (group[i].risk * 20.0);
            double scoreB = group[i+1].cost + (group[i+1].time * 0.3) + (group[i+1].risk * 20.0);
            expect(scoreA <= scoreB, isTrue, reason: 'Group $anchor not sorted');
        }
    });

    // 3. Verify anchor ordering (Round 1 diversity)
    // The first appearance of each anchor in 'results' should be sorted by score.
    List<JourneyResult> firsts = [];
    Set<String> seen = {};
    for (var res in results) {
        if (!seen.contains(res.anchor)) {
            firsts.add(res);
            seen.add(res.anchor);
        }
    }

    for (int i = 0; i < firsts.length - 1; i++) {
        double scoreA = firsts[i].cost + (firsts[i].time * 0.3) + (firsts[i].risk * 20.0);
        double scoreB = firsts[i+1].cost + (firsts[i+1].time * 0.3) + (firsts[i+1].risk * 20.0);
        expect(scoreA <= scoreB, isTrue, reason: 'Anchors not sorted by best option');
    }
  });
}
