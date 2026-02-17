import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';
import 'package:client/utils/segment_utils.dart';

void main() {
  test('Two consecutive Northern trains should be merged and labeled Northern + Northern', () {
    final segments = [
      Segment(
        mode: 'train',
        label: 'Northern',
        lineColor: '#000000',
        iconId: 'train',
        time: 10,
      ),
      Segment(
        mode: 'train',
        label: 'Northern',
        lineColor: '#000000',
        iconId: 'train',
        time: 10,
      ),
    ];

    final processed = processSegments(segments);

    expect(processed.length, 1);
    expect(processed[0].label, 'Northern + Northern');
    expect(processed[0].time, 20);
  });
}
