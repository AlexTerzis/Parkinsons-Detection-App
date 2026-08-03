import '../../models/landmark_point.dart';
import '../hand_metrics.dart';
import '../parkinson_config.dart';
import 'camera_recording.dart';
import 'camera_scorer.dart';

/// The original scoring formula, behind the [CameraScorer] interface.
///
/// This exists so the old and new scorers can be run on the same recording and
/// compared term by term. It changes nothing: it uses the untouched
/// [ParkinsonConfig] weights and the same [HandMetrics] calls, over the same
/// inputs (movement tasks only, rest excluded) that
/// `CameraTestViewModel._analyzeFrames` uses.
///
/// That formula therefore now exists in two places, which is a real risk of
/// divergence. It is pinned by a test asserting this scorer reproduces
/// `_analyzeFrames`'s `parkinson_probability` exactly on the same recording.
/// The ViewModel remains the source of truth for the stored legacy values; this
/// class is only a lens onto the same arithmetic.
class LegacyWeightedScorer implements CameraScorer {
  const LegacyWeightedScorer({HandMetrics metrics = const HandMetrics()})
      : _metrics = metrics;

  final HandMetrics _metrics;

  @override
  String get id => 'legacy_weighted';

  @override
  CameraScore score(CameraRecording recording) {
    final left = _metricsFor(recording, 'Left');
    final right = _metricsFor(recording, 'Right');

    final double speedVarL = left['speed']!;
    final double speedVarR = right['speed']!;
    final double asymmetry = (speedVarL - speedVarR).abs();

    double avg(double a, double b) => (a + b) / 2;

    // Identical to the original formula, weights included.
    final terms = <String, ({double raw, double weight})>{
      'speed_variance': (
        raw: avg(speedVarL, speedVarR),
        weight: ParkinsonConfig.wSpeed,
      ),
      'tremor': (
        raw: avg(left['tremor']!, right['tremor']!),
        weight: ParkinsonConfig.wTremor,
      ),
      'accel_variance': (
        raw: avg(left['accel']!, right['accel']!),
        weight: ParkinsonConfig.wAccel,
      ),
      'jerk_variance': (
        raw: avg(left['jerk']!, right['jerk']!),
        weight: ParkinsonConfig.wJerk,
      ),
      'finger_spread': (
        raw: avg(left['spread']!, right['spread']!),
        weight: ParkinsonConfig.wSpread,
      ),
      'asymmetry': (raw: asymmetry, weight: ParkinsonConfig.wAsym),
    };

    double probability = 0;
    for (final term in terms.values) {
      probability += term.weight * term.raw;
    }

    return CameraScore(
      scorerId: id,
      likelihood: probability.clamp(0.0, 1.0),
      // The original formula has no notion of data quality; reporting a
      // confidence it never computed would be inventing one. Stated as 1.0 and
      // called out, rather than silently omitted.
      confidence: 1.0,
      features: terms.entries
          .map((e) => FeatureContribution(
                name: e.key,
                raw: e.value.raw,
                // These metrics are already scaled toward 0-1 by HandMetrics
                // rather than normalized against a documented range, so raw and
                // normalized are the same number here. That is exactly the
                // weakness the enhanced scorer addresses.
                normalized: e.value.raw.clamp(0.0, 1.0),
                weight: e.value.weight,
              ))
          .toList(growable: false),
      notes: const <String>[
        'Original formula, unchanged. Reports no data-quality confidence; the '
            'value 1.0 is a placeholder, not a measurement.',
      ],
    );
  }

  /// The five per-hand metrics, over movement tasks only — matching what
  /// `_analyzeFrames` feeds the formula.
  Map<String, double> _metricsFor(CameraRecording recording, String hand) {
    final merged = List.generate(21, (_) => <LandmarkPoint>[]);
    for (final task in recording.movementTasks) {
      if (task.hand != hand) continue;
      final trajectories = task.toPointTrajectories();
      for (int i = 0; i < 21; i++) {
        merged[i].addAll(trajectories[i]);
      }
    }

    return <String, double>{
      'speed': _metrics.speedVarianceAll(merged),
      'accel': _metrics.accelerationVarianceAll(merged),
      'jerk': _metrics.jerkVarianceAll(merged),
      'spread': _metrics.fingerSpread(merged),
      'tremor': _metrics.tremorAll(merged),
    };
  }
}
