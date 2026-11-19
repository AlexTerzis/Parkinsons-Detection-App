import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/services/hand_metrics.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';

void main() {
  final metrics = HandMetrics();
  group('HandMetrics', () {
    test('speed variance near zero for stationary trajectory', () {
      final frames = [
        [
          const LandmarkPoint(x: 0, y: 0, z: 0),
          const LandmarkPoint(x: 0, y: 0, z: 0),
          const LandmarkPoint(x: 0, y: 0, z: 0),
        ]
      ];
      final result = metrics.speedVarianceAll(frames);
      expect(result, closeTo(0, 1e-6));
    });

    test('tremor dilutes a single-axis oscillation across x, y and z', () {
      // A full-amplitude square wave on x alone, which is as strong as a
      // one-directional shake can be.
      final points = List<LandmarkPoint>.generate(20, (i) {
        final x = (i % 2 == 0) ? 0.0 : 1.0;
        return LandmarkPoint(x: x, y: 0, z: 0);
      });

      // `tremorAll` takes the standard deviation of each axis and averages the
      // three. Here that is (0.5 + 0 + 0) / 3: the two motionless axes drag
      // the result down, so no single-axis shake can ever exceed 1/6 — this
      // assertion used to ask for > 0.2, which the metric cannot produce.
      //
      // Recorded rather than corrected. `tremorAll` is superseded by
      // TremorAnalysisService (see CHANGELOG section 3) but is still read by
      // LegacyWeightedScorer and by the camera test's rest_tremor_* fields, so
      // changing the metric would move scores already stored in Firestore and
      // break comparability with earlier results.
      expect(metrics.tremorAll([points]), closeTo(1 / 6, 1e-9));
    });
  });
}
