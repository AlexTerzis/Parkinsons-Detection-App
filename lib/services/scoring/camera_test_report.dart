import 'dart:math' as math;

import '../../models/camera_task_protocol.dart';
import '../tremor_analysis_service.dart';
import 'camera_recording.dart';
import 'motor_rating.dart';
import 'movement_cycle_analyzer.dart';
import 'task_quality.dart';

/// What was measured in one task, and how well it was recorded.
///
/// Every measurement is nullable, and `null` always means "could not be
/// measured", never zero. A task with three cycles genuinely cannot support a
/// decrement estimate, and reporting 0 there would read as "no decrement" —
/// the opposite of the truth.
class TaskMeasurements {
  const TaskMeasurements({
    required this.taskId,
    required this.hand,
    required this.type,
    required this.quality,
    this.cycles,
    this.tremor,
  });

  final String taskId;
  final String hand;
  final CameraTaskType type;

  /// How well this task was recorded. Independent of what was measured.
  final TaskQuality quality;

  /// Movement measurements, for the three active tasks. `null` for rest.
  final CycleMetrics? cycles;

  /// Tremor measurements, for the rest task. `null` for the active tasks.
  ///
  /// Deliberately restricted to rest: the separation of tremor from voluntary
  /// movement assumes voluntary movement stays below 4 Hz, and finger tapping
  /// at 5 taps a second breaks that assumption outright — a fast healthy
  /// tapper would measure as a severe tremor.
  final TremorAnalysis? tremor;

  bool get valid => quality.valid;
  double get confidence => quality.confidence;

  /// Seconds of usable signal.
  double get usableSeconds => cycles?.durationSeconds ?? 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'taskId': taskId,
        'hand': hand,
        'taskType': type.name,
        'mdsUpdrsItem': type.mdsUpdrsItem,
        'quality': quality.toJson(),
        'cycles': cycles?.toJson(),
        'tremor': tremor?.toJson(),
      };
}

/// Everything measured for one hand.
class HandReport {
  const HandReport({
    required this.hand,
    required this.tasks,
    required this.confidence,
  });

  final String hand;
  final List<TaskMeasurements> tasks;

  /// 0-1 trust in this hand's measurements, from how well its tasks were
  /// recorded. Not a statement about the hand.
  final double confidence;

  TaskMeasurements? taskOf(CameraTaskType type) {
    for (final task in tasks) {
      if (task.type == type) return task;
    }
    return null;
  }

  CycleMetrics? cyclesOf(CameraTaskType type) => taskOf(type)?.cycles;

  TremorAnalysis? get restTremor => taskOf(CameraTaskType.rest)?.tremor;

  TremorAnalysis? get posturalTremor =>
      taskOf(CameraTaskType.posture)?.tremor;

  /// Tasks that could not be measured and would be worth repeating.
  List<TaskMeasurements> get invalidTasks =>
      tasks.where((t) => !t.valid).toList(growable: false);

  bool get hasAnyValidTask => tasks.any((t) => t.valid);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'hand': hand,
        'confidence': confidence,
        'tasks': tasks.map((t) => t.toJson()).toList(growable: false),
      };
}

/// One neutral left-versus-right comparison.
///
/// Reports both sides and the gap between them, and says nothing about what a
/// gap means. Asymmetry is of clinical interest, but stating that here would be
/// interpretation, and this type is only responsible for the arithmetic.
class HandComparison {
  const HandComparison({
    required this.name,
    required this.left,
    required this.right,
  });

  final String name;
  final double? left;
  final double? right;

  /// Available only when both hands produced the measurement.
  double? get difference =>
      (left == null || right == null) ? null : (left! - right!).abs();

  /// The difference as a fraction of the larger side, 0-1.
  ///
  /// Scale-free, so measurements in different units stay comparable with each
  /// other and between patients.
  double? get relativeDifference {
    final d = difference;
    if (d == null) return null;
    final double larger = math.max(left!.abs(), right!.abs());
    if (larger <= 0) return null;
    return (d / larger).clamp(0.0, 1.0);
  }

  bool get measured => left != null && right != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'left': left,
        'right': right,
        'difference': difference,
        'relativeDifference': relativeDifference,
      };
}

/// The complete outcome of one camera assessment.
///
/// This is the patient- and reviewer-facing result. The combined heuristic
/// score is carried on it but is deliberately not its headline: it is an
/// uncalibrated research output, and the measurements and the recording quality
/// are what the screen is built around.
class CameraTestReport {
  const CameraTestReport({
    required this.hands,
    required this.comparisons,
    required this.confidence,
    required this.rating,
    this.retryCount = 0,
    this.performedAt,
  });

  /// Bumped whenever the stored shape changes. Version 1 is implicit in
  /// documents written before the guided protocol; 2 was the guided protocol
  /// with the legacy score; 3 adds per-frame accounting, task validation and
  /// the enhanced scorer.
  /// 4: landscape, hands-free, both-hands tremor steps, position-based hand
  /// assignment and the 0-4 item ratings.
  static const int protocolVersion = 4;

  /// Which feature extractor produced the measurements.
  static const String featureExtractorVersion = 'cycle_analyzer_v1';

  final List<HandReport> hands;
  final List<HandComparison> comparisons;

  /// 0-1 trust in the recording as a whole. Data quality, never a probability
  /// of anything about the patient.
  final double confidence;

  /// The per-task 0-4 ratings and the score derived from them.
  final MotorRating? rating;

  /// The test's score, 0-1, or `null` when nothing could be rated.
  double? get score => rating?.score;

  final int retryCount;
  final DateTime? performedAt;

  HandReport? handReport(String hand) {
    for (final report in hands) {
      if (report.hand == hand) return report;
    }
    return null;
  }

  /// Tasks across both hands that could not be measured.
  List<TaskMeasurements> get invalidTasks =>
      hands.expand((h) => h.invalidTasks).toList(growable: false);

  int get completedTaskCount =>
      hands.expand((h) => h.tasks).where((t) => t.valid).length;

  int get totalTaskCount => hands.expand((h) => h.tasks).length;

  /// Whether there is anything at all to show.
  ///
  /// Deliberately weaker than "a task passed validation". A task that failed a
  /// quality check still has a measured speed and duration, and those are worth
  /// showing — the alternative, which this replaced, was a screen saying
  /// nothing could be measured while the analyzer sat on real numbers.
  ///
  /// The bar is now simply: did any task record frames.
  bool get hasAnyMeasurement => hands
      .expand((h) => h.tasks)
      .any((t) => t.cycles != null || t.tremor != null);

  /// Plain-language reasons the confidence came out where it did.
  List<String> get confidenceReasons {
    final reasons = <String>[];
    if (!hasAnyMeasurement) {
      reasons.add('No step produced a usable recording.');
      return reasons;
    }
    final invalid = invalidTasks;
    if (invalid.isNotEmpty) {
      reasons.add('${invalid.length} of $totalTaskCount steps could not be '
          'measured from their recording.');
    }
    if (retryCount > 0) {
      reasons.add('$retryCount step(s) were recorded more than once.');
    }
    for (final hand in hands) {
      if (!hand.hasAnyValidTask) {
        reasons.add('The ${hand.hand.toLowerCase()} hand produced no usable '
            'recording, so the two hands cannot be compared.');
      }
    }
    if (reasons.isEmpty) {
      reasons.add('Every step was recorded cleanly.');
    }
    return reasons;
  }

  /// The Firestore `data` payload for this report.
  ///
  Map<String, dynamic> toJson() => <String, dynamic>{
        'protocol_version': protocolVersion,
        'feature_extractor_version': featureExtractorVersion,
        'quality_rules_version': const QualityRules().version,
        'overall_confidence': confidence,
        'retry_count': retryCount,
        'completed_tasks': completedTaskCount,
        'total_tasks': totalTaskCount,
        'confidence_reasons': confidenceReasons,
        'hands': <String, dynamic>{
          for (final hand in hands) hand.hand: hand.toJson(),
        },
        'comparisons':
            comparisons.map((c) => c.toJson()).toList(growable: false),

        // Named so that no reader can mistake it for a validated probability.
        // The old `parkinson_probability` key is still written alongside, by
        // the legacy path, and is documented as deprecated.
        'score': score,
        'motor_rating': rating?.toJson(),
      };
}

/// Turns a validated recording into the report the app shows and stores.
///
/// Pure. Kept apart from both the scorer and the ViewModel: the scorer answers
/// "one number for this recording", this answers "what was measured, per hand
/// and per task, and how much of it can be trusted". They call the same
/// analyzers, which is duplication of two method calls rather than of any
/// arithmetic.
class CameraReportBuilder {
  const CameraReportBuilder({
    MovementCycleAnalyzer cycleAnalyzer = const MovementCycleAnalyzer(),
    TremorAnalysisService tremorAnalyzer = const TremorAnalysisService(),
    TaskQualityValidator validator = const TaskQualityValidator(),
  })  : _cycles = cycleAnalyzer,
        _tremor = tremorAnalyzer,
        _validator = validator;

  final MovementCycleAnalyzer _cycles;
  final TremorAnalysisService _tremor;
  final TaskQualityValidator _validator;

  /// Builds the report.
  ///
  /// [qualities] lets the caller pass the verdicts already computed during the
  /// run, so a task is judged on the attempt that was actually kept. Any task
  /// not present is validated here.
  CameraTestReport build(
    CameraRecording recording, {
    Map<String, TaskQuality> qualities = const <String, TaskQuality>{},
    MotorRating? rating,
    int retryCount = 0,
    DateTime? performedAt,
  }) {
    final hands = <HandReport>[];

    for (final hand in CameraTaskProtocol.hands) {
      final tasks = <TaskMeasurements>[];

      for (final task in recording.tasksFor(hand)) {
        final quality = qualities[task.taskId] ?? _validator.validate(task);

        tasks.add(TaskMeasurements(
          taskId: task.taskId,
          hand: task.hand,
          type: task.type,
          quality: quality,
          cycles: task.isScored ? _cycles.analyze(task) : null,
          // Frequency estimation needs a minimum run of samples; below it the
          // service returns an empty analysis rather than a guess.
          tremor: !task.isScored && task.frames.length >= 8
              ? _tremor.analyzeHand(task.allTrajectories())
              : null,
        ));
      }

      hands.add(HandReport(
        hand: hand,
        tasks: tasks,
        confidence: _handConfidence(tasks),
      ));
    }

    return CameraTestReport(
      hands: hands,
      comparisons: _compare(hands),
      confidence: _overallConfidence(hands),
      rating: rating,
      retryCount: retryCount,
      performedAt: performedAt,
    );
  }

  /// Mean confidence over the hand's tasks, with the worst weighted in.
  ///
  /// A hand whose tapping was unmeasurable is not fully trusted just because
  /// its other two movements recorded cleanly.
  double _handConfidence(List<TaskMeasurements> tasks) {
    if (tasks.isEmpty) return 0;
    final values = tasks.map((t) => t.confidence).toList(growable: false);
    final double mean = values.reduce((a, b) => a + b) / values.length;
    final double worst = values.reduce(math.min);
    return (0.5 * mean + 0.5 * worst).clamp(0.0, 1.0);
  }

  double _overallConfidence(List<HandReport> hands) {
    final values = hands
        .where((h) => h.tasks.isNotEmpty)
        .map((h) => h.confidence)
        .toList(growable: false);
    if (values.isEmpty) return 0;
    final double mean = values.reduce((a, b) => a + b) / values.length;
    final double worst = values.reduce(math.min);
    return (0.5 * mean + 0.5 * worst).clamp(0.0, 1.0);
  }

  /// Neutral left-versus-right comparisons, one per measurement that both
  /// hands produced.
  List<HandComparison> _compare(List<HandReport> hands) {
    HandReport? left, right;
    for (final hand in hands) {
      if (hand.hand == 'Left') left = hand;
      if (hand.hand == 'Right') right = hand;
    }
    if (left == null || right == null) return const <HandComparison>[];

    HandComparison of(
      String name,
      double? Function(HandReport) pick,
    ) =>
        HandComparison(name: name, left: pick(left!), right: pick(right!));

    // Only measurements that mean the same thing on both sides. Comparing, say,
    // tapping rate against open/close rate would be arithmetic without meaning.
    double? tapRate(HandReport h) =>
        h.cyclesOf(CameraTaskType.fingerTap)?.rateHz;
    double? tapAmplitude(HandReport h) =>
        h.cyclesOf(CameraTaskType.fingerTap)?.meanAmplitude;
    double? openCloseRate(HandReport h) =>
        h.cyclesOf(CameraTaskType.openClose)?.rateHz;
    double? rotationRate(HandReport h) =>
        h.cyclesOf(CameraTaskType.pronationSupination)?.rateHz;

    double? meanOf(HandReport h, double? Function(CycleMetrics) pick) {
      final values = <double>[
        for (final type in <CameraTaskType>[
          CameraTaskType.fingerTap,
          CameraTaskType.openClose,
          CameraTaskType.pronationSupination,
        ])
          if (h.cyclesOf(type) != null && pick(h.cyclesOf(type)!) != null)
            pick(h.cyclesOf(type)!)!,
      ];
      if (values.isEmpty) return null;
      return values.reduce((a, b) => a + b) / values.length;
    }

    return <HandComparison>[
      of('tap_rate', tapRate),
      of('tap_amplitude', tapAmplitude),
      of('open_close_rate', openCloseRate),
      of('rotation_rate', rotationRate),
      of('speed', (h) => meanOf(h, (m) => m.meanSpeed)),
      of('rhythm_variability', (h) => meanOf(h, (m) => m.rhythmVariability)),
      of('amplitude_decrement', (h) => meanOf(h, (m) => m.amplitudeDecrement)),
      of('tremor_amplitude', (h) => h.restTremor?.amplitude),
      of('postural_tremor_amplitude', (h) => h.posturalTremor?.amplitude),
    ];
  }
}
