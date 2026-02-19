import 'package:client/widgets/timeline_summary_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimelineSummaryView Logo Logic', () {
    test('shouldUseLongLogo returns true if space available for Northern', () {
      // Northern: Long=68.0, Short=20.0. Cost=48.0.
      expect(TimelineSummaryView.shouldUseLongLogo('Northern', 50.0, 20.0), true);
      expect(TimelineSummaryView.shouldUseLongLogo('Northern', 48.0, 20.0), true);
    });

    test('shouldUseLongLogo returns false if not enough space for Northern', () {
      // Cost=48.0.
      expect(TimelineSummaryView.shouldUseLongLogo('Northern', 47.9, 20.0), false);
    });

    test('shouldUseLongLogo returns false for unknown brand', () {
      expect(TimelineSummaryView.shouldUseLongLogo('Unknown', 100.0, 20.0), false);
    });

    test('shouldUseLongLogo returns false for brand without long logo', () {
      // CrossCountry doesn't have a long logo defined in longTrainLogos map
      expect(TimelineSummaryView.shouldUseLongLogo('CrossCountry', 100.0, 20.0), false);
    });

    test('shouldUseLongLogo logic for Transpennine Express', () {
       // Long=28.0, Short=20.0. Cost=8.0.
       expect(TimelineSummaryView.shouldUseLongLogo('Transpennine Express', 10.0, 20.0), true);
       expect(TimelineSummaryView.shouldUseLongLogo('Transpennine Express', 7.9, 20.0), false);
    });
  });
}
