import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/services/hand_metrics.dart';
import 'package:parkinsondetetion/services/parkinson_config.dart';
import 'package:parkinsondetetion/services/scoring/camera_recording.dart';
import 'package:parkinsondetetion/services/scoring/camera_scoring_service.dart';
import 'package:parkinsondetetion/services/scoring/enhanced_scoring_config.dart';
import 'package:parkinsondetetion/services/scoring/legacy_weighted_scorer.dart';

import 'synthetic_recording.dart';

void main() {
  const service = CameraScoringService();
  const legacyScorer = LegacyWeightedScorer();

  /// Recomputes the original formula independently of [LegacyWeightedScorer],
  /// transcribed from `CameraTestViewModel._analyzeFrames`: the same
  /// [HandMetrics] calls over movement-task trajectories only, combined with
  /// the untouched [ParkinsonConfig] weights.
  ///
  /// This is what pins the scorer to the formula. The two now exist separately,
  /// and this test fails the moment they diverge.
  double legacyProbabilityFromFormula(CameraRecording recording) {
    const metrics = HandMetrics();

    Map<String, double> forHand(String hand) {
      final merged = List.generate(21, (_) => <LandmarkPoint>[]);
      for (final task in recording.movementTasks) {
        if (task.hand != hand) continue;
        final trajectories = task.toPointTrajectories();
        for (int i = 0; i < 21; i++) {
          merged[i].addAll(trajectories[i]);
        }
      }
      return <String, double>{
        'speed': metrics.speedVarianceAll(merged),
        'accel': metrics.accelerationVarianceAll(merged),
        'jerk': metrics.jerkVarianceAll(merged),
        'spread': metrics.fingerSpread(merged),
        'tremor': metrics.tremorAll(merged),
      };
    }

    final left = forHand('Left');
    final right = forHand('Right');
    final double asymmetry = (left['speed']! - right['speed']!).abs();
    double avg(double a, double b) => (a + b) / 2;

    final double probability =
        ParkinsonConfig.wSpeed * avg(left['speed']!, right['speed']!) +
            ParkinsonConfig.wTremor * avg(left['tremor']!, right['tremor']!) +
            ParkinsonConfig.wAccel * avg(left['accel']!, right['accel']!) +
            ParkinsonConfig.wJerk * avg(left['jerk']!, right['jerk']!) +
            ParkinsonConfig.wSpread * avg(left['spread']!, right['spread']!) +
            ParkinsonConfig.wAsym * asymmetry;

    return probability.clamp(0.0, 1.0);
  }

  group('CameraScoringService - runs both scorers -', () {
    test('reports a result from each on the same recording', () {
      final comparison = service.scoreAll(Synthetic.parkinsonian());

      expect(comparison.legacy.scorerId, 'legacy_weighted');
      expect(comparison.enhanced.scorerId, 'heuristic_v1');
      expect(comparison.legacy.likelihood, inInclusiveRange(0.0, 1.0));
      expect(comparison.enhanced.likelihood, inInclusiveRange(0.0, 1.0));
    });

    test('lists the scorers that ran', () {
      expect(service.scorerIds, <String>['legacy_weighted', 'heuristic_v1']);
    });

    test('serializes both results side by side for comparison', () {
      final json = service.scoreAll(Synthetic.parkinsonian()).toJson();

      expect(json.keys, containsAll(<String>['selected', 'legacy', 'enhanced']));
      expect((json['legacy'] as Map)['scorer_id'], 'legacy_weighted');
      expect((json['enhanced'] as Map)['scorer_id'], 'heuristic_v1');
      // Both breakdowns survive, which is the point of storing them.
      expect((json['legacy'] as Map)['features'], isNotEmpty);
      expect((json['enhanced'] as Map)['features'], isNotEmpty);
    });

    test('the two scorers disagree, which is why both are stored', () {
      // Not an assertion about which is right — just that they are genuinely
      // different reads, so the stored comparison carries information.
      final healthy = service.scoreAll(Synthetic.healthy());
      final pd = service.scoreAll(Synthetic.parkinsonian());

      final legacyGap = pd.legacy.likelihood - healthy.legacy.likelihood;
      final enhancedGap = pd.enhanced.likelihood - healthy.enhanced.likelihood;

      expect(enhancedGap, greaterThan(legacyGap));
    });
  });

  group('CameraScoringService - flag -', () {
    test('selects the legacy scorer by default', () {
      final comparison = service.scoreAll(Synthetic.parkinsonian());

      expect(EnhancedScoringConfig.useEnhancedScoring, isFalse);
      expect(comparison.selected.scorerId, 'legacy_weighted');
      expect(comparison.likelihood, comparison.legacy.likelihood);
    });

    test('the selected score is whichever the flag names', () {
      final comparison = service.scoreAll(Synthetic.parkinsonian());
      final expected = EnhancedScoringConfig.useEnhancedScoring
          ? comparison.enhanced
          : comparison.legacy;

      expect(comparison.selected.scorerId, expected.scorerId);
      expect(comparison.likelihood, expected.likelihood);
    });
  });

  group('LegacyWeightedScorer - unchanged behaviour -', () {
    test('reproduces the original formula exactly', () {
      for (final recording in <CameraRecording>[
        Synthetic.healthy(),
        Synthetic.parkinsonian(),
        Synthetic.recording(rateHz: 3, amplitude: 0.8),
      ]) {
        expect(
          legacyScorer.score(recording).likelihood,
          legacyProbabilityFromFormula(recording),
          reason: 'the scorer must not drift from the original formula',
        );
      }
    });

    test('uses the untouched ParkinsonConfig weights', () {
      final features = legacyScorer.score(Synthetic.parkinsonian()).features;
      final weights = <String, double>{
        for (final f in features) f.name: f.weight,
      };

      expect(weights['speed_variance'], ParkinsonConfig.wSpeed);
      expect(weights['tremor'], ParkinsonConfig.wTremor);
      expect(weights['accel_variance'], ParkinsonConfig.wAccel);
      expect(weights['jerk_variance'], ParkinsonConfig.wJerk);
      expect(weights['finger_spread'], ParkinsonConfig.wSpread);
      expect(weights['asymmetry'], ParkinsonConfig.wAsym);
    });

    test('excludes rest tasks, matching the existing scoring path', () {
      final withRest = Synthetic.recording(rateHz: 4);
      final withoutRest = Synthetic.recording(rateHz: 4, includeRest: false);

      expect(legacyScorer.score(withRest).likelihood,
          legacyScorer.score(withoutRest).likelihood);
    });

    test('says plainly that its confidence is not measured', () {
      final score = legacyScorer.score(Synthetic.healthy());

      expect(score.confidence, 1.0);
      expect(score.notes.join(' '), contains('placeholder'));
    });
  });

  group('CameraScoringService - robustness -', () {
    test('handles an empty recording without throwing', () {
      final comparison = service.scoreAll(
        const CameraRecording(tasks: [], mode: CameraTestMode.full),
      );

      expect(comparison.legacy.likelihood, 0);
      expect(comparison.enhanced.likelihood, 0);
      expect(comparison.enhanced.confidence, 0);
    });

    test('handles a recording of rest only', () {
      final full = Synthetic.recording(rateHz: 4);
      final restOnly = CameraRecording(
        tasks: full.tasks.where((t) => !t.isScored).toList(),
        mode: CameraTestMode.full,
      );

      final comparison = service.scoreAll(restOnly);
      expect(comparison.legacy.likelihood, inInclusiveRange(0.0, 1.0));
      expect(comparison.enhanced.likelihood, inInclusiveRange(0.0, 1.0));
    });
  });
}
