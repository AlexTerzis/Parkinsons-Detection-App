import '../services/parkinson_config.dart';
import 'test_type.dart';

/// Which way a test's score runs.
///
/// This is not cosmetic. `TestResult.score` holds two opposite kinds of number:
/// the sensor tests store a Parkinson's likelihood, where a high value is the
/// worrying one, while the cognitive batteries store a normalised MoCA or FAB
/// total, where a high value is the reassuring one. 80% means "well done" on
/// the neuro test and "see a doctor" on the camera test.
///
/// Anything that turns a score into words, colour or an arrow must consult
/// this first, or it will tell half the patients the opposite of the truth.
enum ScoreDirection {
  /// Higher means more sign of disease: camera, drawing, voice, tremor, tap,
  /// questionnaire.
  higherIsWorse,

  /// Higher means better performance: the MoCA and FAB batteries.
  higherIsBetter,
}

/// How a single result reads, in three plain bands.
enum ScoreBand {
  /// Nothing notable for a screening tool at this level.
  reassuring,

  /// Between the two, worth repeating or mentioning.
  borderline,

  /// Worth raising with a clinician. Never stated as a diagnosis.
  notable,
}

/// Turns a raw 0-1 [TestResult.score] into something a patient can read.
///
/// # These cut-offs are provisional
///
/// The cognitive bands follow published MoCA and FAB screening cut-offs. The
/// sensor bands reuse [ParkinsonConfig.symptomThreshold], which is the app's
/// own existing notion of "elevated" and is itself unvalidated. None of this
/// is a diagnostic instrument, and the wording shown to patients is
/// deliberately cautious as a result.
abstract final class TestScoreInterpretation {
  /// Below this a sensor score reads as reassuring.
  ///
  /// Sits under [ParkinsonConfig.symptomThreshold] so there is a genuine middle
  /// band rather than a hard pass/fail line, which a screening tool should not
  /// present.
  static const double sensorReassuringBelow = 0.4;

  /// At or above this a sensor score reads as notable. Reuses the app's
  /// existing threshold rather than inventing a second one; ParkinsonConfig is
  /// read here, never modified.
  static const double sensorNotableAtOrAbove =
      ParkinsonConfig.symptomThreshold;

  /// MoCA: 26 of 30 is the usual normal cut-off, which is 4 of 30 *missed*.
  ///
  /// Expressed as concern directly rather than as `1 - 26/30`: that
  /// subtraction lands a hair below 4/30 in binary floating point, so a
  /// patient scoring exactly 26 fell into the wrong band.
  static const double mocaConcernReassuringAtOrBelow = 4 / 30;

  /// Above this a MoCA result is the clearly notable one — worse than 18/30.
  static const double mocaConcernNotableAbove = 0.4;

  /// FAB is stored over the app's five implemented items rather than the
  /// clinical six, so these are against that scale rather than the published
  /// 16/18.
  static const double fabConcernReassuringAtOrBelow = 0.2;
  static const double fabConcernNotableAbove = 0.4;

  static ScoreDirection directionOf(TestType type) {
    switch (type) {
      case TestType.neuro:
      case TestType.fab:
        return ScoreDirection.higherIsBetter;
      case TestType.cameraDetection:
      case TestType.drawing:
      case TestType.voice:
      case TestType.tremor:
      case TestType.tap:
      case TestType.questionnaire:
        return ScoreDirection.higherIsWorse;
    }
  }

  /// The band a concern value falls into for [type].
  ///
  /// Takes `TestResult.concernScore`, never the raw stored score: concern
  /// always runs the same way, so the only thing varying per type is where the
  /// cut-offs sit.
  static ScoreBand bandOfConcern(TestType type, double concern) {
    final double c = concern.clamp(0.0, 1.0);

    switch (type) {
      case TestType.neuro:
        if (c <= mocaConcernReassuringAtOrBelow) return ScoreBand.reassuring;
        if (c > mocaConcernNotableAbove) return ScoreBand.notable;
        return ScoreBand.borderline;

      case TestType.fab:
        if (c <= fabConcernReassuringAtOrBelow) return ScoreBand.reassuring;
        if (c > fabConcernNotableAbove) return ScoreBand.notable;
        return ScoreBand.borderline;

      case TestType.cameraDetection:
      case TestType.drawing:
      case TestType.voice:
      case TestType.tremor:
      case TestType.tap:
      case TestType.questionnaire:
        if (c < sensorReassuringBelow) return ScoreBand.reassuring;
        if (c >= sensorNotableAtOrAbove) return ScoreBand.notable;
        return ScoreBand.borderline;
    }
  }

  /// Converts a *native* score — the value the test naturally produces — into
  /// concern.
  ///
  /// Used when writing a result and when reading a legacy document. New code
  /// working with a stored result should read `TestResult.concernScore`
  /// instead, which has already done this.
  static double concernFromNative(TestType type, double nativeScore) {
    final double s = nativeScore.clamp(0.0, 1.0);
    return directionOf(type) == ScoreDirection.higherIsBetter ? 1 - s : s;
  }
}
