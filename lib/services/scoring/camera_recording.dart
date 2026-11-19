import 'dart:math' as math;

import '../../models/camera_task_protocol.dart';
import '../../models/camera_task_segment.dart';
import '../../models/landmark_point.dart';
import '../../models/tracking_event.dart';
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
    this.samples = const <TrackingSample>[],
    int missedFrames = 0,
  }) : _declaredMissedFrames = missedFrames;

  final String taskId;
  final CameraTaskType type;

  /// `'Left'` or `'Right'`.
  final String hand;

  final Duration plannedDuration;

  /// Frames in capture order that carried landmarks.
  final List<TaggedFrame> frames;

  /// Every processed camera frame and what became of it.
  ///
  /// Empty for recordings built without per-frame accounting — synthetic
  /// fixtures, and any session captured before it existed — in which case the
  /// figures below fall back to [_declaredMissedFrames].
  final List<TrackingSample> samples;

  final int _declaredMissedFrames;

  bool get isScored => type.isScored;

  /// Frames in which the examined hand yielded no usable landmarks.
  int get missedFrames =>
      samples.isEmpty ? _declaredMissedFrames : samples.length - frames.length;

  /// Every camera frame this task saw, usable or not.
  int get processedFrameCount =>
      samples.isEmpty ? frames.length + _declaredMissedFrames : samples.length;

  /// Measured rate of usable frames, from the frame timestamps.
  double get fps {
    if (frames.length < 2) return 0;
    final int spanMs = frames.last.timestamp - frames.first.timestamp;
    if (spanMs <= 0) return 0;
    return (frames.length - 1) * 1000 / spanMs;
  }

  /// Rate at which the camera delivered frames at all — device throughput,
  /// independent of whether a hand was in them.
  double get processedFps {
    if (samples.length < 2) return fps;
    final int spanMs = samples.last.timestamp - samples.first.timestamp;
    if (spanMs <= 0) return 0;
    return (samples.length - 1) * 1000 / spanMs;
  }

  /// Fraction of processed frames that yielded landmarks, 0-1.
  ///
  /// A task can look well sampled on [fps] alone while the hand was out of
  /// frame for half of it, so coverage is tracked separately and feeds
  /// confidence.
  double get coverage {
    final int total = processedFrameCount;
    if (total == 0) return 0;
    return frames.length / total;
  }

  /// Fraction of processed frames that were clean on every dimension, 0-1.
  ///
  /// Stricter than [coverage], which also counts clipped and marginally
  /// classified frames. Falls back to [coverage] when there is no per-frame
  /// record to be stricter with.
  double get trackedRatio {
    if (samples.isEmpty) return coverage;
    final int clean =
        samples.where((s) => s.state.isFullQuality).length;
    return clean / samples.length;
  }

  /// How many frames ended in each state.
  Map<TrackingState, int> get stateCounts {
    final counts = <TrackingState, int>{};
    for (final sample in samples) {
      counts[sample.state] = (counts[sample.state] ?? 0) + 1;
    }
    return counts;
  }

  int _count(TrackingState state) =>
      samples.where((s) => s.state == state).length;

  /// Fraction of usable frames in which part of the hand had left the view.
  ///
  /// Those frames still carry landmarks, but a clipped hand understates
  /// amplitude, so a task built mostly from them measures a smaller movement
  /// than the patient actually made.
  double get outOfFrameRatio {
    if (frames.isEmpty) return 0;
    return _count(TrackingState.partiallyOutOfFrame) / frames.length;
  }

  /// Of the frames that held any hand, the fraction that held the right one.
  ///
  /// Low values mean the patient was showing the other hand — a recording of a
  /// real movement, of the wrong limb, which is worse than no recording because
  /// it looks complete.
  ///
  /// Without a per-frame record this cannot be judged, so a recording that has
  /// frames but no samples reports 1: absence of evidence is not evidence of
  /// the wrong hand, and returning 0 would fail every synthetic fixture and
  /// every session captured before per-frame accounting existed.
  double get handednessConsistency {
    if (samples.isEmpty) return frames.isEmpty ? 0 : 1;
    final int withAnyHand = samples
        .where((s) => s.state != TrackingState.noHand)
        .length;
    if (withAnyHand == 0) return 0;
    return frames.length / withAnyHand;
  }

  /// Of the frames in which the hand was seen, the fraction that arrived with a
  /// complete landmark set. Unjudgeable without samples; see above.
  double get landmarkCompleteness {
    if (samples.isEmpty) return frames.isEmpty ? 0 : 1;
    final int seen = samples.where((s) => s.state.sawTargetHand).length;
    if (seen == 0) return 0;
    return frames.length / seen;
  }

  /// The longest continuous stretch with no usable landmarks, in seconds.
  ///
  /// Distinct from [coverage]: losing every third frame and losing four
  /// consecutive seconds give the same coverage, but only the second destroys
  /// the rhythm and decrement measurements, because the analyzer cannot tell
  /// the resulting gap from a genuine pause in the movement.
  double get longestGapSeconds {
    if (frames.length < 2) {
      // Nothing usable to bridge: the gap is the whole task.
      return usableDurationSeconds > 0 ? usableDurationSeconds : 0;
    }
    int worst = 0;
    for (int i = 1; i < frames.length; i++) {
      final int gap = frames[i].timestamp - frames[i - 1].timestamp;
      if (gap > worst) worst = gap;
    }
    return worst / 1000.0;
  }

  /// Seconds spanned by the usable frames.
  double get usableDurationSeconds {
    if (frames.length < 2) return 0;
    final int spanMs = frames.last.timestamp - frames.first.timestamp;
    return spanMs <= 0 ? 0 : spanMs / 1000.0;
  }

  /// How steady the hand's apparent size was, 0-1, where 1 is rock steady.
  ///
  /// Palm size in frame-normalized units is a proxy for distance to the lens.
  /// Every spatial feature is divided by it, so a patient drifting toward or
  /// away from the camera mid-task adds a trend to amplitude that looks exactly
  /// like decrement. This reports how much room there is for that confusion.
  double get handSizeStability {
    final sizes = <double>[];
    for (final frame in frames) {
      if (frame.landmarks.length < 10) continue;
      final wrist = frame.landmarks[0];
      final middleMcp = frame.landmarks[9];
      final dx = wrist.x - middleMcp.x;
      final dy = wrist.y - middleMcp.y;
      final dz = wrist.z - middleMcp.z;
      final double size = math.sqrt(dx * dx + dy * dy + dz * dz);
      if (size > 0) sizes.add(size);
    }
    if (sizes.length < 2) return 0;

    final double mean = sizes.reduce((a, b) => a + b) / sizes.length;
    if (mean <= 0) return 0;
    final double variance =
        sizes.map((s) => (s - mean) * (s - mean)).reduce((a, b) => a + b) /
            sizes.length;
    // 1 - coefficient of variation, so "stable" is high and the number is
    // dimensionless and comparable between patients of different hand sizes.
    return (1 - math.sqrt(variance) / mean).clamp(0.0, 1.0);
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
                samples: s.samples,
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
  ///
  /// "Attempted" now means the camera delivered frames for it, not that some of
  /// them worked out. A task where the hand was never once visible used to fall
  /// out of this average entirely — it had no frames and, because misses were
  /// only counted when *some* hand was present, no misses either — so the worst
  /// possible task contributed nothing to the quality figure.
  double get meanCoverage {
    final values = tasks
        .where((t) => t.processedFrameCount > 0)
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
