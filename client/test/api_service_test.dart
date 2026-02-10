
import 'package:flutter_test/flutter_test.dart';
import 'package:client/services/api_service.dart';

void main() {
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
}
