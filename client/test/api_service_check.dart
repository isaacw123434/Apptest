import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import '../lib/services/api_service.dart';

void main() {
  test('ApiService attaches paths correctly', () async {
    final apiService = ApiService();
    final initData = await apiService.fetchInitData();

    // Check Main Leg
    print('Checking Main Leg...');
    final mainLeg = initData.segmentOptions.mainLeg;
    for (var seg in mainLeg.segments) {
      print('  Segment: ${seg.label}, Path points: ${seg.path?.length ?? 0}');
      if (seg.path == null || seg.path!.isEmpty) {
        print('    WARNING: No path!');
      } else {
        expect(seg.path, isNotEmpty);
      }
    }

    // Check First Mile
    print('Checking First Mile...');
    for (var leg in initData.segmentOptions.firstMile) {
      print('  Leg: ${leg.id}');
      for (var seg in leg.segments) {
        print('    Segment: ${seg.label}, Mode: ${seg.mode}, Path points: ${seg.path?.length ?? 0}');
        if (seg.path == null || seg.path!.isEmpty) {
          print('      WARNING: No path!');
        } else {
           expect(seg.path, isNotEmpty);
        }
      }
    }

    // Check Last Mile
    print('Checking Last Mile...');
    for (var leg in initData.segmentOptions.lastMile) {
      print('  Leg: ${leg.id}');
      for (var seg in leg.segments) {
        print('    Segment: ${seg.label}, Mode: ${seg.mode}, Path points: ${seg.path?.length ?? 0}');
        if (seg.path == null || seg.path!.isEmpty) {
           print('      WARNING: No path!');
        } else {
           expect(seg.path, isNotEmpty);
        }
      }
    }
  });
}
