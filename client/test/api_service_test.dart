
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
    for (int i = 0; i < results.length - 1; i++) {
        double scoreA = results[i].cost + (results[i].time * 0.3) + (results[i].risk * 20.0);
        double scoreB = results[i+1].cost + (results[i+1].time * 0.3) + (results[i+1].risk * 20.0);
        expect(scoreA <= scoreB, isTrue, reason: 'Results should be sorted by score (Cost + 0.3*Time + 20*Risk)');
    }
  });
}
