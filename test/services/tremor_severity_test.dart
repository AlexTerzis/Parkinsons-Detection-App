import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/services/tremor_severity.dart';

/// The tremor score used to be `dominantFrequencyHz / 20`, so it rose with
/// frequency rather than with tremor. These tests pin the property that
/// replaced it: prominence decides the score, frequency only decides how much
/// of it counts.
void main() {
  group('tremorSeverityScore', () {
    test('a clear 5 Hz tremor outscores stronger-looking 12 Hz noise', () {
      // The exact case the old formula got backwards: 12 / 20 = 0.6 for noise
      // against 5 / 20 = 0.25 for a textbook rest tremor.
      final tremor = tremorSeverityScore(
        prominence: 0.8,
        dominantFrequencyHz: 5,
      );
      final noise = tremorSeverityScore(
        prominence: 0.3,
        dominantFrequencyHz: 12,
      );

      expect(tremor, greaterThan(noise));
      expect(tremor, closeTo(0.8, 1e-9), reason: 'full weight inside the band');
      expect(noise, 0.0, reason: '12 Hz is beyond the taper');
    });

    test('rises with prominence at a fixed frequency', () {
      double at(double prominence) => tremorSeverityScore(
            prominence: prominence,
            dominantFrequencyHz: 5,
          );

      expect(at(0.1), lessThan(at(0.5)));
      expect(at(0.5), lessThan(at(0.9)));
    });

    test('does not rise with frequency at a fixed prominence', () {
      double at(double hz) =>
          tremorSeverityScore(prominence: 0.7, dominantFrequencyHz: hz);

      // Inside the band the score is flat, and it only falls outside it. The
      // old formula made this sequence strictly increasing.
      expect(at(4), closeTo(at(6), 1e-9));
      expect(at(9), lessThan(at(6)));
      expect(at(12), lessThanOrEqualTo(at(9)));
    });

    test('gives full weight across the whole tremor band', () {
      for (final hz in <double>[3.5, 4, 5, 6, 7, 7.5]) {
        expect(
          tremorBandWeight(hz),
          1.0,
          reason: '$hz Hz is inside the 3.5-7.5 Hz band',
        );
      }
    });

    test('tapers to nothing outside the band rather than cutting off', () {
      // Half a taper width past each edge is worth half.
      expect(tremorBandWeight(tremorBandLowHz - tremorBandTaperHz / 2),
          closeTo(0.5, 1e-9));
      expect(tremorBandWeight(tremorBandHighHz + tremorBandTaperHz / 2),
          closeTo(0.5, 1e-9));

      // A full taper width past it is worth nothing, and never negative.
      expect(tremorBandWeight(tremorBandLowHz - tremorBandTaperHz), 0.0);
      expect(tremorBandWeight(tremorBandHighHz + tremorBandTaperHz), 0.0);
      expect(tremorBandWeight(0), 0.0);
      expect(tremorBandWeight(50), 0.0);
    });

    test('scores nothing when no frequency could be measured', () {
      // `_dominantPeak` returns (0, 0) when the spectrum carries no usable
      // peak, which must not read as a 0 Hz tremor.
      expect(
        tremorSeverityScore(prominence: 0.9, dominantFrequencyHz: 0),
        0.0,
      );
    });

    test('stays within 0-1', () {
      expect(
        tremorSeverityScore(prominence: 1, dominantFrequencyHz: 5),
        inInclusiveRange(0, 1),
      );
      // Defensive: a prominence above 1 must not produce a score above 1.
      expect(
        tremorSeverityScore(prominence: 2.5, dominantFrequencyHz: 5),
        1.0,
      );
    });
  });
}
