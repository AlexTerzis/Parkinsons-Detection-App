import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/test_result.dart';
import 'package:parkinsondetetion/models/test_score_interpretation.dart';
import 'package:parkinsondetetion/models/test_type.dart';

/// Every test in this file exists because `TestResult.score` used to mean two
/// opposite things. It now always means concern — 0 best, 1 worst — and old
/// documents are converted on read.
void main() {
  TestResult resultOf(TestType type, double score, {int? schema}) => TestResult(
        id: 'x',
        patientId: 'p',
        type: type,
        performedAt: DateTime(2026),
        score: score,
        scoreSchema: schema ?? TestResult.currentScoreSchema,
      );

  group('native score direction -', () {
    test('the batteries are performance scores, the sensors are likelihoods',
        () {
      for (final type in [TestType.neuro, TestType.fab]) {
        expect(TestScoreInterpretation.directionOf(type),
            ScoreDirection.higherIsBetter);
      }
      for (final type in [
        TestType.cameraDetection,
        TestType.drawing,
        TestType.voice,
        TestType.tremor,
        TestType.tap,
        TestType.questionnaire,
      ]) {
        expect(TestScoreInterpretation.directionOf(type),
            ScoreDirection.higherIsWorse);
      }
    });

    test('every type has a direction', () {
      for (final type in TestType.values) {
        expect(() => TestScoreInterpretation.directionOf(type), returnsNormally);
      }
    });

    test('concernFromNative inverts only the performance scores', () {
      // A perfect MoCA is zero concern; a high camera likelihood is high concern.
      expect(TestScoreInterpretation.concernFromNative(TestType.neuro, 1.0),
          closeTo(0, 1e-9));
      expect(
          TestScoreInterpretation.concernFromNative(TestType.cameraDetection, 1.0),
          closeTo(1, 1e-9));
    });
  });

  group('TestResult.concernScore -', () {
    test('current documents are already concern and pass through', () {
      expect(resultOf(TestType.neuro, 0.1).concernScore, closeTo(0.1, 1e-9));
      expect(resultOf(TestType.tremor, 0.8).concernScore, closeTo(0.8, 1e-9));
    });

    test('legacy battery documents are flipped on read', () {
      // Schema 1 stored 24/30 = 0.8 as "how well they did"; as concern that is
      // 0.2. Reading it raw would rank a good result as a bad one.
      expect(resultOf(TestType.neuro, 0.8, schema: 1).concernScore,
          closeTo(0.2, 1e-9));
      expect(resultOf(TestType.fab, 0.9, schema: 1).concernScore,
          closeTo(0.1, 1e-9));
    });

    test('legacy sensor documents are left alone', () {
      expect(resultOf(TestType.drawing, 0.7, schema: 1).concernScore,
          closeTo(0.7, 1e-9));
    });

    test('a document with no schema field is treated as legacy', () {
      final legacy = TestResult.fromJson(
        <String, dynamic>{'type': 'neuro', 'score': 0.9},
        'id',
      );
      expect(legacy.scoreSchema, 1);
      expect(legacy.concernScore, closeTo(0.1, 1e-9));
    });

    test('new documents record the schema so they are never re-flipped', () {
      final json = resultOf(TestType.neuro, 0.2).toJson();
      expect(json['scoreSchema'], TestResult.currentScoreSchema);

      final roundTripped = TestResult.fromJson(json, 'id');
      expect(roundTripped.concernScore, closeTo(0.2, 1e-9));
    });

    test('a good result ranks below a bad one across different tests', () {
      // The comparison that was broken: a strong MoCA against a strong
      // Parkinson's signal. Both stored as 0.9 under the old scheme.
      final goodCognitive = resultOf(TestType.neuro, 0.9, schema: 1);
      final badSensor = resultOf(TestType.cameraDetection, 0.9, schema: 1);

      expect(goodCognitive.concernScore, lessThan(badSensor.concernScore));
    });

    test('clamps out-of-range stored values', () {
      expect(resultOf(TestType.tap, 1.5).concernScore, 1.0);
      expect(resultOf(TestType.tap, -0.5).concernScore, 0.0);
    });
  });

  group('bands -', () {
    test('high concern is notable and low concern is reassuring, always', () {
      for (final type in TestType.values) {
        expect(TestScoreInterpretation.bandOfConcern(type, 0.95),
            ScoreBand.notable,
            reason: '$type at high concern');
        expect(TestScoreInterpretation.bandOfConcern(type, 0.02),
            ScoreBand.reassuring,
            reason: '$type at low concern');
      }
    });

    test('MoCA follows the 26/30 cut-off once expressed as concern', () {
      // 26/30 correct is 4/30 concern.
      expect(TestScoreInterpretation.bandOfConcern(TestType.neuro, 4 / 30),
          ScoreBand.reassuring);
      expect(TestScoreInterpretation.bandOfConcern(TestType.neuro, 5 / 30),
          ScoreBand.borderline);
    });

    test('the sensor notable cut-off is the app-wide symptom threshold', () {
      const t = TestScoreInterpretation.sensorNotableAtOrAbove;
      expect(TestScoreInterpretation.bandOfConcern(TestType.tap, t),
          ScoreBand.notable);
      expect(TestScoreInterpretation.bandOfConcern(TestType.tap, t - 0.01),
          ScoreBand.borderline);
    });

    test('sensor tests keep a genuine middle band', () {
      expect(TestScoreInterpretation.bandOfConcern(TestType.tremor, 0.5),
          ScoreBand.borderline);
    });

    test('every type bands the whole range without throwing', () {
      for (final type in TestType.values) {
        for (final c in [-1.0, 0.0, 0.25, 0.5, 0.75, 1.0, 2.0]) {
          expect(() => TestScoreInterpretation.bandOfConcern(type, c),
              returnsNormally);
        }
      }
    });
  });
}
