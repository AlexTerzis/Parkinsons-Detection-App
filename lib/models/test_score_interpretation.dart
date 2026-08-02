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

  /// MoCA: 26 of 30 is the usual normal cut-off, so 0.867 on the stored scale.
  static const double mocaReassuringAtOrAbove = 26 / 30;

  /// Below this a MoCA result is the clearly notable one.
  static const double mocaNotableBelow = 0.6;

  /// FAB is stored over the app's five implemented items rather than the
  /// clinical six, so this is expressed against that scale rather than the
  /// published 16/18.
  static const double fabReassuringAtOrAbove = 0.8;
  static const double fabNotableBelow = 0.6;

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

  /// The band [score] falls into for [type].
  static ScoreBand bandOf(TestType type, double score) {
    final double s = score.clamp(0.0, 1.0);

    switch (type) {
      case TestType.neuro:
        if (s >= mocaReassuringAtOrAbove) return ScoreBand.reassuring;
        if (s < mocaNotableBelow) return ScoreBand.notable;
        return ScoreBand.borderline;

      case TestType.fab:
        if (s >= fabReassuringAtOrAbove) return ScoreBand.reassuring;
        if (s < fabNotableBelow) return ScoreBand.notable;
        return ScoreBand.borderline;

      case TestType.cameraDetection:
      case TestType.drawing:
      case TestType.voice:
      case TestType.tremor:
      case TestType.tap:
      case TestType.questionnaire:
        if (s < sensorReassuringBelow) return ScoreBand.reassuring;
        if (s >= sensorNotableAtOrAbove) return ScoreBand.notable;
        return ScoreBand.borderline;
    }
  }

  /// The fraction to fill a progress bar with, so the bar always grows toward
  /// the *worrying* end regardless of which way the underlying score runs.
  ///
  /// Without this a good MoCA would draw a nearly full bar and a good camera
  /// result a nearly empty one, which reads as the opposite of what it means.
  static double concernFraction(TestType type, double score) {
    final double s = score.clamp(0.0, 1.0);
    return directionOf(type) == ScoreDirection.higherIsBetter ? 1 - s : s;
  }
}
