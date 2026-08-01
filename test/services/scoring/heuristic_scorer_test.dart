import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/services/scoring/camera_recording.dart';
import 'package:parkinsondetetion/services/scoring/camera_scorer.dart';
import 'package:parkinsondetetion/services/scoring/enhanced_scoring_config.dart';
import 'package:parkinsondetetion/services/scoring/heuristic_scorer.dart';

import 'synthetic_recording.dart';

void main() {
  const scorer = HeuristicScorer();

  double featureNormalized(CameraScore score, String name) =>
      score.features.firstWhere((f) => f.name == name).normalized;

  FeatureContribution feature(CameraScore score, String name) =>
      score.features.firstWhere((f) => f.name == name);

  group('EnhancedScoringConfig -', () {
    test('weights sum to 1', () {
      final total = EnhancedScoringConfig.weights.values
          .reduce((a, b) => a + b);
      expect(total, closeTo(1.0, 1e-9));
    });

    test('inverted ranges map low raw values to high scores', () {
      // Slow tapping is the parkinsonian end, so it must normalize high.
      expect(EnhancedScoringConfig.tapRate.normalize(1.0), closeTo(1.0, 1e-9));
      expect(EnhancedScoringConfig.tapRate.normalize(6.0), closeTo(0.0, 1e-9));
      // Fast rhythm variability is the parkinsonian end of a normal range.
      expect(EnhancedScoringConfig.rhythmVariability.normalize(0.5),
          closeTo(1.0, 1e-9));
    });

    test('ranges clamp outside their bounds', () {
      expect(EnhancedScoringConfig.tapRate.normalize(20), 0.0);
      expect(EnhancedScoringConfig.tapRate.normalize(-5), 1.0);
    });

    test('defaults to the existing scorer', () {
      // The whole point of the flag: nothing changes until it is deliberately
      // flipped, after the ranges have been calibrated.
      expect(EnhancedScoringConfig.useEnhancedScoring, isFalse);
    });
  });

  group('HeuristicScorer - separation -', () {
    test('scores a parkinsonian recording far above a healthy one', () {
      final healthy = scorer.score(Synthetic.healthy());
      final parkinsonian = scorer.score(Synthetic.parkinsonian());

      expect(healthy.likelihood, lessThan(0.25));
      expect(parkinsonian.likelihood, greaterThan(0.45));
      expect(parkinsonian.likelihood - healthy.likelihood, greaterThan(0.3));
    });

    test('every feature moves in the expected direction', () {
      final healthy = scorer.score(Synthetic.healthy());
      final pd = scorer.score(Synthetic.parkinsonian());

      for (final name in <String>[
        'tremor',
        'tap_rate',
        'rhythm_variability',
        'amplitude_decrement',
        'speed_decrement',
        'mean_speed',
        'initiation_delay',
        'pause_burden',
        'smoothness',
        'asymmetry',
      ]) {
        expect(
          featureNormalized(pd, name),
          greaterThan(featureNormalized(healthy, name)),
          reason: '$name should score higher for the parkinsonian recording',
        );
      }
    });

    test('contributions sum to the likelihood', () {
      final score = scorer.score(Synthetic.parkinsonian());
      final total = score.features
          .fold<double>(0, (sum, f) => sum + f.contribution);

      expect(total, closeTo(score.likelihood, 1e-9));
    });

    test('effective weights sum to 1 when every feature is measured', () {
      final score = scorer.score(Synthetic.parkinsonian());
      expect(score.features.every((f) => f.measured), isTrue);

      final total = score.features.fold<double>(0, (sum, f) => sum + f.weight);
      expect(total, closeTo(1.0, 1e-9));
    });
  });

  group('HeuristicScorer - individual signs -', () {
    test('decrement alone raises the score', () {
      final steady = scorer.score(Synthetic.recording(rateHz: 4));
      final decrementing =
          scorer.score(Synthetic.recording(rateHz: 4, decrement: 0.45));

      expect(featureNormalized(decrementing, 'amplitude_decrement'),
          greaterThan(featureNormalized(steady, 'amplitude_decrement')));
      expect(decrementing.likelihood, greaterThan(steady.likelihood));
    });

    test('tremor is read from the rest tasks, not the movement tasks', () {
      // Fast voluntary tapping sits at 5 Hz, inside the parkinsonian tremor
      // band. Measuring tremor during movement would score this hand as
      // severely tremulous; measuring it at rest must not.
      final fastButSteady = scorer.score(Synthetic.recording(
        rateHz: 5.0,
        amplitude: 1.2,
        tremorAmplitude: 0,
      ));

      expect(featureNormalized(fastButSteady, 'tremor'), lessThan(0.05));
    });

    test('rest tremor is detected when it is genuinely present', () {
      final tremulous = scorer.score(Synthetic.recording(
        rateHz: 4,
        tremorAmplitude: 0.15,
        tremorHz: 5,
      ));

      expect(featureNormalized(tremulous, 'tremor'), greaterThan(0.3));
    });

    test('one slow hand and one fast hand reads as asymmetry', () {
      final symmetric = scorer.score(Synthetic.recording(rateHz: 4));
      final asymmetric =
          scorer.score(Synthetic.recording(rateHz: 2, leftRateHz: 5));

      expect(featureNormalized(asymmetric, 'asymmetry'),
          greaterThan(featureNormalized(symmetric, 'asymmetry')));
    });
  });

  group('HeuristicScorer - confidence -', () {
    test('a clean full recording is scored confidently', () {
      expect(scorer.score(Synthetic.healthy()).confidence, greaterThan(0.9));
    });

    test('a low frame rate lowers confidence', () {
      final good = scorer.score(Synthetic.recording(fps: 30, rateHz: 3));
      final poor = scorer.score(Synthetic.recording(fps: 12, rateHz: 3));

      expect(poor.confidence, lessThan(good.confidence));
    });

    test('the hand leaving frame lowers confidence', () {
      final seen = scorer.score(Synthetic.recording(rateHz: 4));
      // As many frames missed as captured: the hand was visible half the time.
      final halfSeen =
          scorer.score(Synthetic.recording(rateHz: 4, missedFrames: 300));

      expect(halfSeen.confidence, lessThan(seen.confidence * 0.8));
    });

    test('missing tasks lower confidence', () {
      final full = Synthetic.recording(rateHz: 4);
      final partial = CameraRecording(
        // Only one hand's worth of tasks completed.
        tasks: full.tasks.where((t) => t.hand == 'Right').toList(),
        mode: CameraTestMode.full,
      );

      expect(scorer.score(partial).confidence,
          lessThan(scorer.score(full).confidence));
    });

    test('too few cycles lowers confidence', () {
      // A very slow movement yields only a handful of cycles, so rhythm and
      // decrement rest on almost nothing.
      final many = scorer.score(Synthetic.recording(rateHz: 4));
      final few = scorer.score(Synthetic.recording(rateHz: 0.4));

      expect(few.confidence, lessThan(many.confidence));
    });
  });

  group('HeuristicScorer - unmeasurable features -', () {
    test('a single-handed recording reports asymmetry as unmeasured', () {
      final full = Synthetic.recording(rateHz: 4);
      final oneHand = CameraRecording(
        tasks: full.tasks.where((t) => t.hand == 'Right').toList(),
        mode: CameraTestMode.full,
      );

      final score = scorer.score(oneHand);
      final asymmetry = feature(score, 'asymmetry');

      expect(asymmetry.measured, isFalse);
      expect(asymmetry.raw, isNull);
      expect(asymmetry.note, isNotNull);
      expect(score.notes.join(' '), contains('asymmetry'));
    });

    test('redistributes weight so a partial recording stays on the same scale',
        () {
      final full = Synthetic.recording(rateHz: 4);
      final oneHand = CameraRecording(
        tasks: full.tasks.where((t) => t.hand == 'Right').toList(),
        mode: CameraTestMode.full,
      );

      final score = scorer.score(oneHand);
      final measuredWeight = score.features
          .where((f) => f.measured)
          .fold<double>(0, (sum, f) => sum + f.weight);

      // Weight from the unmeasured feature has been shared out, so the
      // measured ones still span the full 0-1 scale rather than capping below
      // it and looking artificially healthy.
      expect(measuredWeight, closeTo(1.0, 1e-9));
      expect(
        score.features
            .fold<double>(0, (sum, f) => sum + f.contribution),
        closeTo(score.likelihood, 1e-9),
      );
    });

    test('an empty recording scores zero with zero confidence', () {
      final score = scorer.score(
        const CameraRecording(tasks: [], mode: CameraTestMode.full),
      );

      expect(score.likelihood, 0);
      expect(score.confidence, 0);
      expect(score.features.every((f) => !f.measured), isTrue);
      expect(score.notes, isNotEmpty);
    });
  });

  group('HeuristicScorer - contract -', () {
    test('is deterministic', () {
      final recording = Synthetic.parkinsonian();
      expect(scorer.score(recording).likelihood,
          scorer.score(recording).likelihood);
    });

    test('serializes with its breakdown intact', () {
      final json = scorer.score(Synthetic.parkinsonian()).toJson();

      expect(json['scorer_id'], 'heuristic_v1');
      expect(json['likelihood'], isA<double>());
      expect(json['confidence'], isA<double>());
      expect((json['features'] as List).length,
          EnhancedScoringConfig.weights.length);

      final first = (json['features'] as List).first as Map<String, dynamic>;
      expect(first.keys,
          containsAll(<String>['name', 'raw', 'normalized', 'weight']));
    });

    test('likelihood stays within 0-1 for extreme input', () {
      final extreme = scorer.score(Synthetic.recording(
        rateHz: 0.2,
        amplitude: 0.1,
        decrement: 0.9,
        jitterFraction: 0.9,
        tremorAmplitude: 2.0,
        startDelay: 8,
        pauseAt: 2,
        pauseDuration: 4,
      ));

      expect(extreme.likelihood, inInclusiveRange(0.0, 1.0));
      expect(extreme.confidence, inInclusiveRange(0.0, 1.0));
    });
  });
}
