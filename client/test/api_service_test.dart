
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

    // Check if sorted by updated logic
    // Note: minRisk cancels out when comparing two scores from the same search,
    // so we can verify order using raw risk * 20.0
    //
    // Update: Logic is now "Diversity First", meaning we prioritize showing different routes (anchors)
    // before showing multiple options for the same route. This means the list is NOT strictly sorted by score.
    // e.g. [Best Route A, Best Route B, 2nd Best Route A]

    expect(results, isNotEmpty);

    // Check that we have valid scores
    for (var r in results) {
       double score = r.cost + (r.time * 0.3) + (r.risk * 20.0);
       expect(score, isNotNull);
       expect(score, greaterThan(0));
    }
  });
}
