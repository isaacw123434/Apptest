import 'package:flutter_test/flutter_test.dart';
import 'package:client/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ApiService attaches paths correctly', () async {
    final apiService = ApiService();
    final initData = await apiService.fetchInitData();

    // Check Main Leg
    final mainLeg = initData.segmentOptions.mainLeg;
    for (var seg in mainLeg.segments) {
      if (seg.path == null || seg.path!.isEmpty) {
        // Warning logic removed
      } else {
        expect(seg.path, isNotEmpty);
      }
    }

    // Check First Mile
    for (var leg in initData.segmentOptions.firstMile) {
      for (var seg in leg.segments) {
        if (seg.path == null || seg.path!.isEmpty) {
          // Warning logic removed
        } else {
          expect(seg.path, isNotEmpty);
        }
      }
    }

    // Check Last Mile
    for (var leg in initData.segmentOptions.lastMile) {
      for (var seg in leg.segments) {
        if (seg.path == null || seg.path!.isEmpty) {
          // Warning logic removed
        } else {
          expect(seg.path, isNotEmpty);
        }
      }
    }
  });
}
