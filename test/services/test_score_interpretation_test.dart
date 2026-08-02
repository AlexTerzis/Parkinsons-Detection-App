import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/test_score_interpretation.dart';
import 'package:parkinsondetetion/models/test_type.dart';

void main() {
  group('TestScoreInterpretation - direction -', () {
    test('the cognitive batteries run the opposite way to the sensor tests',
        () {
      // This is the whole reason the type exists: TestResult.score holds a
      // Parkinson's likelihood for some tests and a normalised MoCA/FAB total
      // for others, so 80% means opposite things.
      for (final type in [TestType.neuro, TestType.fab]) {
        expect(TestScoreInterpretation.directionOf(type),
            ScoreDirection.higherIsBetter,
            reason: '$type is a performance score');
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
            ScoreDirection.higherIsWorse,
            reason: '$type is a likelihood score');
      }
    });

    test('every test type has a direction', () {
      for (final type in TestType.values) {
        expect(() => TestScoreInterpretation.directionOf(type),
            returnsNormally);
      }
    });
  });

  group('TestScoreInterpretation - bands -', () {
    test('a high sensor score is notable, a high cognitive score is not', () {
      // The exact inversion that a single shared band would get wrong.
      expect(TestScoreInterpretation.bandOf(TestType.cameraDetection, 0.9),
          ScoreBand.notable);
      expect(TestScoreInterpretation.bandOf(TestType.neuro, 0.9),
          ScoreBand.reassuring);
    });

    test('a low sensor score is reassuring, a low cognitive score is not', () {
      expect(TestScoreInterpretation.bandOf(TestType.drawing, 0.1),
          ScoreBand.reassuring);
      expect(TestScoreInterpretation.bandOf(TestType.neuro, 0.1),
          ScoreBand.notable);
      expect(TestScoreInterpretation.bandOf(TestType.fab, 0.1),
          ScoreBand.notable);
    });

    test('sensor tests have a genuine middle band', () {
      expect(TestScoreInterpretation.bandOf(TestType.tremor, 0.5),
          ScoreBand.borderline);
    });

    test('the notable cut-off is the app-wide symptom threshold', () {
      // Reused rather than duplicated, so the result screen and the rest of
      // the app cannot drift apart.
      const threshold = TestScoreInterpretation.sensorNotableAtOrAbove;
      expect(TestScoreInterpretation.bandOf(TestType.tap, threshold),
          ScoreBand.notable);
      expect(TestScoreInterpretation.bandOf(TestType.tap, threshold - 0.01),
          ScoreBand.borderline);
    });

    test('MoCA follows the 26/30 screening cut-off', () {
      expect(TestScoreInterpretation.bandOf(TestType.neuro, 26 / 30),
          ScoreBand.reassuring);
      expect(TestScoreInterpretation.bandOf(TestType.neuro, 25 / 30),
          ScoreBand.borderline);
    });

    test('scores outside 0-1 are clamped rather than throwing', () {
      expect(TestScoreInterpretation.bandOf(TestType.voice, 1.4),
          ScoreBand.notable);
      expect(TestScoreInterpretation.bandOf(TestType.voice, -0.3),
          ScoreBand.reassuring);
    });

    test('every type produces a band across the whole range', () {
      for (final type in TestType.values) {
        for (final score in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          expect(() => TestScoreInterpretation.bandOf(type, score),
              returnsNormally);
        }
      }
    });
  });

  group('TestScoreInterpretation - concern fraction -', () {
    test('the bar always fills toward the worrying end', () {
      // A good MoCA must not draw a nearly full bar while a good camera result
      // draws a nearly empty one; both should read as "little concern".
      final goodCognitive =
          TestScoreInterpretation.concernFraction(TestType.neuro, 0.95);
      final goodSensor =
          TestScoreInterpretation.concernFraction(TestType.cameraDetection, 0.05);

      expect(goodCognitive, closeTo(0.05, 1e-9));
      expect(goodSensor, closeTo(0.05, 1e-9));
    });

    test('a poor result fills the bar regardless of direction', () {
      expect(TestScoreInterpretation.concernFraction(TestType.fab, 0.1),
          closeTo(0.9, 1e-9));
      expect(TestScoreInterpretation.concernFraction(TestType.tremor, 0.9),
          closeTo(0.9, 1e-9));
    });

    test('stays within 0-1 for out-of-range input', () {
      for (final type in TestType.values) {
        for (final score in [-1.0, 0.0, 1.0, 2.0]) {
          final f = TestScoreInterpretation.concernFraction(type, score);
          expect(f, inInclusiveRange(0.0, 1.0));
        }
      }
    });
  });
}
