import '../../models/camera_task_protocol.dart';
import '../../models/camera_task_segment.dart';
import '../../models/landmark_point.dart';
import '../tremor_analysis_service.dart';

/// One task's worth of captured frames, in the form a scorer needs.
///
/// Deliberately separate from [CameraTaskSegment]: that type is about
/// recording and uploading, this one is about analysis. Keeping them apart is
/// what lets a scorer be tested against synthetic input without constructing a
/// recording session, and what will let an ML model consume the same input
/// later without knowing anything about Firebase Storage.
class RecordedTask {
  const RecordedTask({
    required this.taskId,
    required this.type,
    required this.hand,
    required this.plannedDuration,
    required this.frames,
    this.missedFrames = 0,
  });

  final String taskId;
  final CameraTaskType type;

  /// `'Left'` or `'Right'`.
  final String hand;

  final Duration plannedDuration;

  /// Frames in capture order, each with its timestamp and 21 landmarks.
  final List<TaggedFrame> frames;

  /// Frames in which the examined hand was not visible.
  final int missedFrames;

  bool get isScored => type.isScored;

  /// Measured capture rate for this task, from the frame timestamps.
  double get fps {
    if (frames.length < 2) return 0;
    final int spanMs = frames.last.timestamp - frames.first.timestamp;
    if (spanMs <= 0) return 0;
    return (frames.length - 1) * 1000 / spanMs;
  }

  /// Fraction of expected frames in which the hand was actually seen, 0-1.
  ///
  /// A task can look well sampled on [fps] alone while the hand was out of
  /// frame for half of it, so coverage is tracked separately and feeds
  /// confidence.
  double get coverage {
    final int total = frames.length + missedFrames;
    if (total == 0) return 0;
    return frames.length / total;
  }

  /// The trajectory of one landmark index, as [TimedLandmark]s.
  ///
  /// This is the bridge to [TremorAnalysisService], which works in these.
  List<TimedLandmark> trajectoryOf(int landmarkIndex) {
    final out = <TimedLandmark>[];
    for (final frame in frames) {
      if (landmarkIndex < frame.landmarks.length) {
        out.add(TimedLandmark(
          timestampMs: frame.timestamp,
          point: frame.landmarks[landmarkIndex],
        ));
      }
    }
    return out;
  }

  /// All 21 landmark trajectories, in landmark order.
  List<List<TimedLandmark>> allTrajectories() =>
      List.generate(21, trajectoryOf);

  /// Plain per-landmark point lists, for the older [HandMetrics] API which has
  /// no notion of time.
  List<List<LandmarkPoint>> toPointTrajectories() {
    final trajectories = List.generate(21, (_) => <LandmarkPoint>[]);
    for (final frame in frames) {
      for (int i = 0; i < 21 && i < frame.landmarks.length; i++) {
        trajectories[i].add(frame.landmarks[i]);
      }
    }
    return trajectories;
  }
}

/// A complete camera test session, ready to be scored.
class CameraRecording {
  const CameraRecording({required this.tasks, required this.mode});

  final List<RecordedTask> tasks;
  final CameraTestMode mode;

  /// Builds a recording from the segments captured during a session.
  factory CameraRecording.fromSegments(
    List<CameraTaskSegment> segments,
    CameraTestMode mode,
  ) {
    return CameraRecording(
      mode: mode,
      tasks: segments
          .map((s) => RecordedTask(
                taskId: s.taskId,
                type: s.task.type,
                hand: s.hand,
                plannedDuration: s.task.duration,
                frames: s.frames,
                missedFrames: s.missedFrames,
              ))
          .toList(growable: false),
    );
  }

  Iterable<RecordedTask> get movementTasks => tasks.where((t) => t.isScored);

  Iterable<RecordedTask> get restTasks => tasks.where((t) => !t.isScored);

  Iterable<RecordedTask> tasksFor(String hand) =>
      tasks.where((t) => t.hand == hand);

  RecordedTask? taskFor(String hand, CameraTaskType type) {
    for (final task in tasks) {
      if (task.hand == hand && task.type == type) return task;
    }
    return null;
  }

  int get frameCount =>
      tasks.fold<int>(0, (sum, t) => sum + t.frames.length);

  /// Mean measured capture rate across tasks that produced frames.
  double get meanFps {
    final rates = tasks.map((t) => t.fps).where((f) => f > 0).toList();
    if (rates.isEmpty) return 0;
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  /// Mean hand-visible coverage across tasks that were attempted.
  double get meanCoverage {
    final values = tasks
        .where((t) => t.frames.isNotEmpty || t.missedFrames > 0)
        .map((t) => t.coverage)
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Hands that produced at least one usable movement task.
  Set<String> get handsWithData => movementTasks
      .where((t) => t.frames.isNotEmpty)
      .map((t) => t.hand)
      .toSet();
}
