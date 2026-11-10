import 'dart:math' as math;

import '../../models/camera_task_protocol.dart';
import 'camera_recording.dart';
import 'movement_cycle_analyzer.dart';

/// One dimension of recording quality that a task is checked against.
///
/// Every one of these describes the *recording*, never the movement. That
/// separation is the point of this file: a task can be rejected for being
/// unmeasurable, and must never be rejected for what the measurement said.
enum QualityCheck {
  /// Enough frames actually contained the hand.
  usableFrames,

  /// The camera delivered usable frames fast enough to sample the movement.
  effectiveFps,

  /// Enough of the intended task duration produced signal.
  usableDuration,

  /// Tracking was not lost for a long continuous stretch.
  trackingContinuity,

  /// The hand stayed inside the frame.
  handInFrame,

  /// The hand on show was the one being examined.
  handedness,

  /// Frames arrived with a complete landmark set.
  landmarkCompleteness,

  /// The hand stayed at a roughly constant distance from the lens.
  handSizeStability,
}

/// A check that did not pass, with what it saw and what it needed.
class QualityFailure {
  const QualityFailure({
    required this.check,
    required this.measured,
    required this.required_,
    required this.message,
  });

  final QualityCheck check;
  final double measured;
  final double required_;

  /// What to tell the patient, in plain non-medical language.
  ///
  /// Every message names something they can physically change. "Move the phone
  /// slightly farther away" is useful; "insufficient signal quality" is not,
  /// and anything implying the *movement* was abnormal would be a diagnosis.
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'check': check.name,
        'measured': measured,
        'required': required_,
        'message': message,
      };
}

/// Something worth recording about a task that is not grounds for rejecting it.
class QualityNote {
  const QualityNote({required this.code, required this.message});

  final String code;
  final String message;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'code': code, 'message': message};
}

/// The verdict on one task's recording.
class TaskQuality {
  const TaskQuality({
    required this.taskId,
    required this.hand,
    required this.type,
    required this.valid,
    required this.confidence,
    this.failures = const <QualityFailure>[],
    this.notes = const <QualityNote>[],
    this.cycleCount = 0,
  });

  final String taskId;
  final String hand;
  final CameraTaskType type;

  /// Whether this task's recording can carry a measurement at all.
  final bool valid;

  /// 0-1 trust in the measurements from this task, driven purely by how well it
  /// was recorded. Never a statement about the patient.
  final double confidence;

  final List<QualityFailure> failures;
  final List<QualityNote> notes;

  final int cycleCount;

  /// Whether the patient should be offered a repeat of this task.
  ///
  /// Equivalent to [valid] being false today, kept separate because they are
  /// different questions: a task could in principle be unusable for a reason
  /// repeating it would not fix.
  bool get retryRecommended => !valid;

  /// The single most useful thing to tell the patient, or `null` when the task
  /// passed. The worst failure is the one furthest below its threshold.
  String? get primaryMessage {
    if (failures.isEmpty) return null;
    final sorted = List<QualityFailure>.of(failures)
      ..sort((a, b) => _shortfall(a).compareTo(_shortfall(b)));
    return sorted.first.message;
  }

  static double _shortfall(QualityFailure f) =>
      f.required_ == 0 ? 0 : f.measured / f.required_;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'taskId': taskId,
        'hand': hand,
        'taskType': type.name,
        'valid': valid,
        'confidence': confidence,
        'cycleCount': cycleCount,
        'failures': failures.map((f) => f.toJson()).toList(growable: false),
        'notes': notes.map((n) => n.toJson()).toList(growable: false),
      };
}

/// Thresholds a task must clear to count as recorded.
///
/// # These are provisional
///
/// They are reasoned from the geometry of the pipeline — the sampling rate the
/// cycle analyzer needs, the rate below which `TremorAnalysisService` refuses a
/// frequency — and not fitted to recordings from this app, because none are
/// labelled yet. [version] is stored with every result so a later change to
/// these numbers stays traceable.
class QualityRules {
  /// Defaults loosened after device testing.
  ///
  /// The first set was reasoned from the geometry alone and rejected close to
  /// every real recording: hands drift, fingertips cross the frame edge, and
  /// apparent palm size changes as the wrist turns. Thresholds that a careful
  /// patient cannot clear are not quality control — they just make the test
  /// impossible to finish, and push people to give up rather than to record
  /// something better.
  ///
  /// These are still provisional and still not fitted to labelled data.
  const QualityRules({
    this.minUsableFrameRatio = 0.55,
    this.minEffectiveFps = 10.0,
    this.minUsableDurationRatio = 0.5,
    this.maxTrackingGapSeconds = 2.5,
    this.maxOutOfFrameRatio = 0.6,
    this.minHandednessConsistency = 0.4,
    this.minLandmarkCompleteness = 0.75,
    this.minHandSizeStability = 0.55,
    this.advisoryCycleCount = 4,
    this.confidentCycleCount = 8,
    this.version = 'quality_rules_v2',
  });

  /// Fraction of processed frames that must have carried the hand.
  final double minUsableFrameRatio;

  /// Usable frames per second.
  ///
  /// Below roughly this, a 4 Hz movement has only three samples per cycle and
  /// the cycle metrics stop meaning much. Note that 15 fps, not this, is where
  /// tremor *frequency* becomes reportable — a task can be valid here and still
  /// yield no frequency, which is why that is a note rather than a failure.
  final double minEffectiveFps;

  /// Fraction of the planned duration that must have produced signal.
  final double minUsableDurationRatio;

  /// Longest acceptable continuous dropout. A gap longer than this is
  /// indistinguishable from a genuine pause in the movement.
  final double maxTrackingGapSeconds;

  /// Fraction of usable frames that may have part of the hand outside the view.
  final double maxOutOfFrameRatio;

  /// Of the frames holding any hand, the fraction that must hold the right one.
  final double minHandednessConsistency;

  /// Of the frames in which the hand was seen, the fraction that must have
  /// arrived with a complete landmark set.
  final double minLandmarkCompleteness;

  /// 1 minus the coefficient of variation of palm size.
  final double minHandSizeStability;

  /// Below this many cycles, decrement and rhythm are not reported on.
  ///
  /// **Deliberately not a validity threshold.** A patient with pronounced
  /// bradykinesia may genuinely manage three cycles in ten seconds — that is
  /// the finding, not a recording fault. Rejecting the task would force the
  /// most affected patients to repeat something they cannot perform better,
  /// discard their most informative recordings, and bias every dataset built
  /// from this app toward people who move well.
  final int advisoryCycleCount;

  /// Cycles before rhythm and decrement figures are fully trusted.
  final int confidentCycleCount;

  /// Stored with every result, so a threshold change stays traceable.
  final String version;
}

/// Decides whether a task was recorded well enough to measure.
///
/// Pure: same recording in, same verdict out. Kept apart from both the scorer
/// and the ViewModel so the rules can be exercised directly, and so the retry
/// flow has one place to ask.
class TaskQualityValidator {
  const TaskQualityValidator({
    this.rules = const QualityRules(),
    MovementCycleAnalyzer cycleAnalyzer = const MovementCycleAnalyzer(),
  }) : _cycles = cycleAnalyzer;

  final QualityRules rules;
  final MovementCycleAnalyzer _cycles;

  /// Validates every task in [recording], in protocol order.
  List<TaskQuality> validateAll(CameraRecording recording) =>
      recording.tasks.map(validate).toList(growable: false);

  TaskQuality validate(RecordedTask task) {
    final failures = <QualityFailure>[];
    final notes = <QualityNote>[];

    // Nothing was recorded at all: report one plain failure rather than eight
    // derived ones that all say the same thing.
    if (task.processedFrameCount == 0) {
      return TaskQuality(
        taskId: task.taskId,
        hand: task.hand,
        type: task.type,
        valid: false,
        confidence: 0,
        failures: <QualityFailure>[
          QualityFailure(
            check: QualityCheck.usableFrames,
            measured: 0,
            required_: rules.minUsableFrameRatio,
            message: 'No camera frames were recorded for this step.',
          ),
        ],
      );
    }

    void check(
      QualityCheck which,
      double measured,
      double threshold,
      String message, {
      bool higherIsBetter = true,
    }) {
      final bool passed =
          higherIsBetter ? measured >= threshold : measured <= threshold;
      if (!passed) {
        failures.add(QualityFailure(
          check: which,
          measured: measured,
          required_: threshold,
          message: message,
        ));
      }
    }

    check(
      QualityCheck.usableFrames,
      task.coverage,
      rules.minUsableFrameRatio,
      'The hand was not visible for enough of the recording. '
      'Keep it in view of the camera for the whole step.',
    );

    check(
      QualityCheck.handInFrame,
      task.outOfFrameRatio,
      rules.maxOutOfFrameRatio,
      'Part of the hand kept leaving the picture. '
      'Move the phone slightly farther away so the whole hand fits.',
      higherIsBetter: false,
    );

    check(
      QualityCheck.handedness,
      task.handednessConsistency,
      rules.minHandednessConsistency,
      'The other hand was in view for much of this step. '
      'Show only the ${task.hand.toLowerCase()} hand.',
    );

    check(
      QualityCheck.trackingContinuity,
      task.longestGapSeconds,
      rules.maxTrackingGapSeconds,
      'The hand disappeared from view for a few seconds partway through. '
      'Keep it steady in front of the camera.',
      higherIsBetter: false,
    );

    check(
      QualityCheck.effectiveFps,
      task.fps,
      rules.minEffectiveFps,
      'The camera could not keep up during this step. '
      'Closing other apps and trying again usually helps.',
    );

    final double plannedSeconds = task.plannedDuration.inMilliseconds / 1000.0;
    final double durationRatio = plannedSeconds <= 0
        ? 0
        : task.usableDurationSeconds / plannedSeconds;
    check(
      QualityCheck.usableDuration,
      durationRatio,
      rules.minUsableDurationRatio,
      'Too little of this step was recorded. Please repeat it.',
    );

    check(
      QualityCheck.landmarkCompleteness,
      task.landmarkCompleteness,
      rules.minLandmarkCompleteness,
      'The whole hand was not always detected. '
      'Keep the fingers spread and the palm facing the camera.',
    );

    // Only meaningful once there are frames to measure a size trend across.
    if (task.frames.length >= 2) {
      check(
        QualityCheck.handSizeStability,
        task.handSizeStability,
        rules.minHandSizeStability,
        'The distance between the hand and the camera changed during this '
        'step. Hold the phone still and keep the hand at the same distance.',
      );
    }

    // --- Notes: recorded, never grounds for rejection ---

    int cycleCount = 0;
    if (task.isScored) {
      cycleCount = _cycles.analyze(task).cycleCount;
      if (cycleCount < rules.advisoryCycleCount) {
        notes.add(QualityNote(
          code: 'few_cycles',
          message: 'Only $cycleCount complete movements were detected, so the '
              'measurements that need a longer run of them are not reported.',
        ));
      }
    }

    if (task.fps > 0 && task.fps < _tremorFrequencyFps) {
      notes.add(const QualityNote(
        code: 'no_tremor_frequency',
        message: 'The capture rate was too low to measure a tremor frequency '
            'for this step.',
      ));
    }

    final bool valid = failures.isEmpty;

    return TaskQuality(
      taskId: task.taskId,
      hand: task.hand,
      type: task.type,
      valid: valid,
      confidence: _confidence(task, cycleCount, failures),
      failures: failures,
      notes: notes,
      cycleCount: cycleCount,
    );
  }

  /// Rate below which `TremorAnalysisService` will not report a frequency.
  ///
  /// Mirrored rather than imported so this file stays free of the analysis
  /// services; it is asserted equal to the source of truth by a test.
  static const double _tremorFrequencyFps = 15.0;

  /// How much this task's recording supports its measurements, 0-1.
  ///
  /// Blends the mean of the quality factors with the worst of them, so a single
  /// bad dimension drags confidence down rather than being averaged away by
  /// the others — the hand being out of frame is not compensated for by a good
  /// capture rate.
  double _confidence(
    RecordedTask task,
    int cycleCount,
    List<QualityFailure> failures,
  ) {
    final factors = <double>[
      task.coverage.clamp(0.0, 1.0),
      task.trackedRatio.clamp(0.0, 1.0),
      (task.fps / _tremorFrequencyFps).clamp(0.0, 1.0),
      task.handednessConsistency.clamp(0.0, 1.0),
      task.handSizeStability.clamp(0.0, 1.0),
      (1 - task.outOfFrameRatio).clamp(0.0, 1.0),
    ];

    // Cycle count informs confidence but never validity: too few cycles means
    // the rhythm and decrement figures are thin, which is a reason to trust
    // them less, not a reason to make the patient do it again.
    if (task.isScored) {
      factors.add(
        (cycleCount / rules.confidentCycleCount).clamp(0.0, 1.0),
      );
    }

    final double mean = factors.reduce((a, b) => a + b) / factors.length;
    final double worst = factors.reduce(math.min);
    final double base = 0.5 * mean + 0.5 * worst;

    // A task that failed a hard check cannot be highly trusted even if its
    // other dimensions look fine.
    return failures.isEmpty
        ? base.clamp(0.0, 1.0)
        : math.min(base, 0.4).clamp(0.0, 1.0);
  }
}
