import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/services/tap_model_features.dart';

/// The tapping model is only meaningful when fed what it was trained on, so
/// these expectations are not hand-derived: they are the output of
/// `extract_features` in `Parkinsons_ML/simulate_tapping_data.py`, run on the
/// same tap sequence and transcribed here at full precision.
///
/// The app used to send average/variance/max/min/range/stddev in seconds,
/// which matched the training vector in length and nothing else.
void main() {
  // Spans the 10 s run on both sides of the 5 s halfway mark.
  const taps = <double>[
    160, 330, 495, 670, 845, 1020, 4900, 5100, 7300, 9800,
  ];
  const tenSeconds = 10000.0;

  group('tapModelFeatures', () {
    test('matches extract_features from the training script', () {
      final features = tapModelFeatures(taps, testDurationMs: tenSeconds)!;

      expect(features, hasLength(7));
      // tap_count, then mean/std/var of the inter-tap intervals in ms,
      // frequency, and the two half-counts.
      expect(features[0], 10.0);
      expect(features[1], closeTo(1071.111111111111, 1e-9));
      expect(features[2], closeTo(1333.620339480672, 1e-9));
      expect(features[3], closeTo(1778543.2098765431, 1e-6));
      expect(features[4], closeTo(0.9336099585062241, 1e-12));
      expect(features[5], 7.0);
      expect(features[6], 3.0);
    });

    test('derives frequency from the mean interval, not the tap rate', () {
      // Nine taps 200 ms apart, all inside the first second of a 10 s run.
      // Tap-count-over-duration would give 0.9 Hz; the training script's
      // 1000 / mean_interval gives 5 Hz.
      final taps = <double>[
        for (var i = 0; i < 9; i++) 200.0 * (i + 1),
      ];
      final features = tapModelFeatures(taps, testDurationMs: tenSeconds)!;

      expect(features[1], closeTo(200, 1e-9));
      expect(features[4], closeTo(5, 1e-9));
      expect(features[5], 9.0, reason: 'all nine taps precede the halfway mark');
      expect(features[6], 0.0);
    });

    test('reports population spread, as numpy does', () {
      // Intervals of 100 and 300 ms: population variance is 10000 (mean 200,
      // deviations ±100), where the sample variance would be 20000.
      final features = tapModelFeatures(
        const [100, 200, 500],
        testDurationMs: tenSeconds,
      )!;

      expect(features[1], closeTo(200, 1e-9));
      expect(features[3], closeTo(10000, 1e-9));
      expect(features[2], closeTo(100, 1e-9));
    });

    test('counts taps rather than intervals', () {
      final features =
          tapModelFeatures(const [100, 200], testDurationMs: tenSeconds)!;

      expect(features[0], 2.0, reason: 'two taps, one interval');
      expect(features[5] + features[6], 2.0);
    });

    test('declines a run it cannot describe', () {
      // Fewer than two taps leaves no interval to measure. The training
      // script returns seven zeros; the app must return null so the caller
      // skips the prediction instead of saving a score of 0.
      expect(tapModelFeatures(const [], testDurationMs: tenSeconds), isNull);
      expect(tapModelFeatures(const [500], testDurationMs: tenSeconds), isNull);

      // Identical timestamps give a zero mean interval, and 1000 / 0 would be
      // infinity in the feature vector.
      expect(
        tapModelFeatures(const [500, 500], testDurationMs: tenSeconds),
        isNull,
      );
    });

    test('splits the halves at the midpoint of the run', () {
      // A tap exactly on the mark belongs to the second half, matching the
      // training script's strict `taps < TEST_DURATION_MS / 2`.
      final features = tapModelFeatures(
        const [4999, 5000, 5001],
        testDurationMs: tenSeconds,
      )!;

      expect(features[5], 1.0);
      expect(features[6], 2.0);
    });
  });
}
