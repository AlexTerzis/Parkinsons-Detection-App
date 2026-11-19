import '../models/patient_report.dart';
import '../models/test_result.dart';
import '../models/test_type.dart';

/// Why part of an assessment is missing or cannot be relied on.
enum GapReason {
  /// The patient never took this test.
  notTaken,

  /// It ran, but produced nothing usable at all.
  nothingMeasured,

  /// Some of it was recorded and some was not.
  partlyRecorded,

  /// All of it was recorded, but poorly enough to be worth saying so.
  lowQuality,
}

/// One thing a doctor should know is absent from a report.
///
/// Carries numbers rather than a formatted sentence, so the screen can say
/// "3 of 10 items" in the reader's own language. Building the sentence here
/// would put English inside a service, which is how the Greek build ended up
/// with English chart labels elsewhere in this app.
class AssessmentGap {
  const AssessmentGap({
    required this.type,
    required this.reason,
    this.missingParts,
    this.totalParts,
    this.quality,
  });

  final TestType type;
  final GapReason reason;

  /// Tasks or postures that produced nothing, and how many there were.
  final int? missingParts;
  final int? totalParts;

  /// Recording quality, 0-1, where that is what is wrong.
  final double? quality;
}

/// Reads a report for what it does *not* say.
///
/// A report shows the tests that worked. What it silently omits — a test never
/// taken, a camera run where the hand was out of frame throughout, postures the
/// model never saw — is exactly what a doctor needs before drawing a conclusion
/// from it, and is invisible in a list of the results that did come out.
///
/// Pure and static: no Firestore, no widgets, no localization. All of it is
/// decided from the `data` maps the tests already write.
abstract final class ReportAnalysis {
  /// Below this, a recording is worth flagging to the doctor.
  ///
  /// A presentation threshold for "mention this", not a clinical one. The tests
  /// enforce their own validity separately, in `TaskQualityValidator`; anything
  /// that got as far as being stored already passed that.
  static const double qualityFloor = 0.5;

  /// The tests a complete assessment is expected to contain.
  ///
  /// Derived from [TestType.values] rather than listed, so a test added later
  /// is accounted for without anyone remembering to come back here.
  ///
  /// Voice is excluded deliberately. It is a research prototype that
  /// `TestResult.isEligibleForClinicalSummary` already keeps out of clinical
  /// summaries, so reporting its absence as a gap would ask a doctor to chase
  /// something that is not meant to be there.
  static Iterable<TestType> get expectedTests =>
      TestType.values.where((t) => t != TestType.voice);

  /// Everything missing or unreliable in [report], in [expectedTests] order.
  static List<AssessmentGap> gapsIn(PatientReport report) {
    final gaps = <AssessmentGap>[];

    for (final type in expectedTests) {
      final results = report.results.where((r) => r.type == type).toList();

      if (results.isEmpty) {
        gaps.add(AssessmentGap(type: type, reason: GapReason.notTaken));
        continue;
      }

      // The best attempt speaks for the test. A patient who retook a bad
      // recording should not still be shown as having a bad one.
      final gap = results
          .map(_gapForResult)
          .whereType<AssessmentGap>()
          .fold<AssessmentGap?>(null, _lessSevere);

      if (gap != null && results.length == 1) gaps.add(gap);
      // With more than one attempt, only flag when every attempt is flawed.
      if (gap != null && results.length > 1) {
        final allFlawed = results.every((r) => _gapForResult(r) != null);
        if (allFlawed) gaps.add(gap);
      }
    }

    return gaps;
  }

  /// Whichever of two gaps is the milder complaint, so the best attempt wins.
  static AssessmentGap? _lessSevere(AssessmentGap? a, AssessmentGap b) {
    if (a == null) return b;
    return _severity(a.reason) <= _severity(b.reason) ? a : b;
  }

  static int _severity(GapReason reason) => switch (reason) {
        GapReason.lowQuality => 0,
        GapReason.partlyRecorded => 1,
        GapReason.nothingMeasured => 2,
        GapReason.notTaken => 3,
      };

  /// What is wrong with one stored result, or null if nothing is.
  static AssessmentGap? _gapForResult(TestResult result) {
    return switch (result.type) {
      TestType.cameraDetection => _cameraGap(result),
      TestType.posture => _postureGap(result),
      _ => null,
    };
  }

  /// Camera runs record per-task, so a partial run is normal and worth saying.
  static AssessmentGap? _cameraGap(TestResult result) {
    final completed = _asInt(result.data['completed_tasks']);
    final total = _asInt(result.data['total_tasks']);
    final confidence = _asDouble(result.data['overall_confidence']);

    if (total != null && total > 0 && completed != null) {
      if (completed == 0) {
        return AssessmentGap(
          type: result.type,
          reason: GapReason.nothingMeasured,
          missingParts: total,
          totalParts: total,
        );
      }
      if (completed < total) {
        return AssessmentGap(
          type: result.type,
          reason: GapReason.partlyRecorded,
          missingParts: total - completed,
          totalParts: total,
        );
      }
    }

    if (confidence != null && confidence < qualityFloor) {
      return AssessmentGap(
        type: result.type,
        reason: GapReason.lowQuality,
        quality: confidence,
      );
    }
    return null;
  }

  /// Posture records which items the model never saw a hand for.
  static AssessmentGap? _postureGap(TestResult result) {
    final unrecorded = result.data['unrecorded_items'];
    final items = result.data['items'];
    final quality = _asDouble(result.data['recording_quality']);

    final missing = unrecorded is List ? unrecorded.length : 0;
    final total = items is List ? items.length : null;

    if (missing > 0 && total != null && total > 0) {
      return AssessmentGap(
        type: result.type,
        reason: missing >= total
            ? GapReason.nothingMeasured
            : GapReason.partlyRecorded,
        missingParts: missing,
        totalParts: total,
      );
    }

    if (quality != null && quality < qualityFloor) {
      return AssessmentGap(
        type: result.type,
        reason: GapReason.lowQuality,
        quality: quality,
      );
    }
    return null;
  }

  /// The symptoms a questionnaire result records as present.
  ///
  /// The stored `data` is the raw answer map the reasoning engine takes as
  /// input — symptom label to bool — so anything answered yes is a reported
  /// symptom. Sorted, because a Firestore map has no meaningful order and a
  /// list that reshuffles between openings is hard to read against.
  static List<String> reportedSymptoms(TestResult questionnaire) {
    final symptoms = questionnaire.data.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList()
      ..sort();
    return symptoms;
  }

  /// The concern of each test in a report, keyed by type.
  ///
  /// Where a test was taken more than once, the most recent attempt wins —
  /// that is the one the report is about.
  static Map<TestType, double> concernByType(PatientReport report) {
    final byType = <TestType, TestResult>{};
    for (final result in report.results) {
      final existing = byType[result.type];
      if (existing == null ||
          result.performedAt.isAfter(existing.performedAt)) {
        byType[result.type] = result;
      }
    }
    return byType.map((type, result) => MapEntry(type, result.concernScore));
  }

  static int? _asInt(Object? value) =>
      value is num ? value.toInt() : null;

  static double? _asDouble(Object? value) =>
      value is num ? value.toDouble() : null;
}
