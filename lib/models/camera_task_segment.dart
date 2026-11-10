import 'camera_task_protocol.dart';
import 'landmark_point.dart';
import 'tracking_event.dart';

/// One frame of landmarks captured during a specific protocol task.
///
/// Every frame carries its own `taskId` and `hand` rather than inheriting them
/// from the enclosing segment. That redundancy is deliberate: the uploaded
/// segments are consumed by offline analysis jobs, and a frame that travels
/// alone through a pipeline stage must still say what it belongs to.
class TaggedFrame {
  const TaggedFrame({
    required this.taskId,
    required this.hand,
    required this.timestamp,
    required this.landmarks,
    this.state = TrackingState.tracked,
  });

  final String taskId;

  /// `'Left'` or `'Right'` — the hand under examination for [taskId].
  final String hand;

  /// Milliseconds since epoch, as reported when the frame was detected.
  final int timestamp;

  /// The 21 MediaPipe hand landmarks for [hand] in this frame.
  final List<LandmarkPoint> landmarks;

  /// How good this frame was. Landmark-bearing frames are not all equal — a
  /// clipped hand still produces 21 coordinates, they are just wrong about
  /// amplitude — so the state travels with the frame rather than being
  /// flattened away at capture time.
  final TrackingState state;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'taskId': taskId,
        'hand': hand,
        't': timestamp,
        'state': state.name,
        'landmarks': landmarks
            .map((p) => <double>[p.x, p.y, p.z])
            .toList(growable: false),
      };
}

/// All frames captured for one task of the guided protocol.
///
/// Segments are stored and uploaded one per task rather than merged, so a
/// reviewer can look at, say, only the right-hand finger tapping (MDS-UPDRS
/// item 3.4) without unpacking the whole recording.
class CameraTaskSegment {
  CameraTaskSegment({required this.task, required this.hand});

  final CameraTask task;

  /// The hand this segment records.
  ///
  /// Explicit rather than read off [task], because a short-mode step examines
  /// both hands at once and produces one segment per hand. Keeping the split
  /// here means a both-hands run stores exactly the same per-hand keys as a
  /// one-hand-at-a-time run, and everything downstream — analysis, validation,
  /// the results screen — stays single-handed and unaware of the difference.
  final String hand;

  /// Frames that carried usable landmarks. A subset of [samples].
  final List<TaggedFrame> frames = <TaggedFrame>[];

  /// One entry per camera frame processed during this task, whatever came of
  /// it — including the frames that held no hand at all.
  ///
  /// This is the denominator for every quality figure. Without it, a task where
  /// the hand was out of view for nine of ten seconds is indistinguishable from
  /// a short but clean one, because both leave the same handful of good frames
  /// behind.
  final List<TrackingSample> samples = <TrackingSample>[];

  DateTime? startedAt;
  DateTime? endedAt;

  /// Always per hand, so short and full runs share the same storage keys.
  String get taskId => task.segmentId(hand);

  /// Records one classified frame.
  void add(TrackingEvent event) {
    samples.add(event.sample);
    final landmarks = event.landmarks;
    if (landmarks == null) return;
    frames.add(TaggedFrame(
      taskId: taskId,
      hand: hand,
      timestamp: event.timestamp,
      landmarks: landmarks,
      state: event.state,
    ));
  }

  /// How many frames ended in each state.
  Map<TrackingState, int> get stateCounts {
    final counts = <TrackingState, int>{};
    for (final sample in samples) {
      counts[sample.state] = (counts[sample.state] ?? 0) + 1;
    }
    return counts;
  }

  /// Frames in which the examined hand yielded no usable landmarks.
  ///
  /// Previously a counter incremented by the ViewModel, which only ever saw
  /// frames that contained *some* hand — so frames with no hand at all were
  /// never counted and this systematically under-reported. Now derived from
  /// [samples], which include every processed frame.
  int get missedFrames => samples.length - frames.length;

  /// Effective rate of *usable* frames, from the first and last of them.
  ///
  /// Measured rather than assumed: the analysis treats consecutive frames as
  /// samples of a continuous movement, so a low or uneven rate directly weakens
  /// the result and a reviewer needs to see it.
  double get fps {
    if (frames.length < 2) return 0;
    final int spanMs = frames.last.timestamp - frames.first.timestamp;
    if (spanMs <= 0) return 0;
    return (frames.length - 1) * 1000 / spanMs;
  }

  /// Rate at which the camera delivered frames at all, usable or not.
  ///
  /// Separate from [fps] because they answer different questions: this one is
  /// "was the device keeping up", [fps] is "how much signal came out". A device
  /// at 30 fps with the hand out of view scores well here and badly there,
  /// which is exactly the distinction the patient needs to act on.
  double get processedFps {
    if (samples.length < 2) return 0;
    final int spanMs = samples.last.timestamp - samples.first.timestamp;
    if (spanMs <= 0) return 0;
    return (samples.length - 1) * 1000 / spanMs;
  }

  /// Rebuilds per-landmark trajectories in the shape [HandMetrics] expects:
  /// one list per landmark index, each holding that landmark over time.
  List<List<LandmarkPoint>> toTrajectories() {
    final trajectories = List.generate(21, (_) => <LandmarkPoint>[]);
    for (final frame in frames) {
      for (int i = 0; i < 21 && i < frame.landmarks.length; i++) {
        trajectories[i].add(frame.landmarks[i]);
      }
    }
    return trajectories;
  }

  /// Metadata only — safe to embed in the Firestore result document.
  Map<String, dynamic> toSummaryJson() => <String, dynamic>{
        'taskId': taskId,
        'taskType': task.type.name,
        'hand': hand,
        'mdsUpdrsItem': task.mdsUpdrsItem,
        'scored': task.isScored,
        'plannedDurationMs': task.duration.inMilliseconds,
        'startedAt': startedAt?.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'frameCount': frames.length,
        'missedFrames': missedFrames,
        'fps': fps,

        // --- Added with per-frame accounting ---
        'processedFrames': samples.length,
        'processedFps': processedFps,
        'frameStates': <String, int>{
          for (final entry in stateCounts.entries) entry.key.name: entry.value,
        },
      };

  /// The full segment including landmark data — uploaded to Storage, never
  /// written to Firestore.
  ///
  /// [samples] is written out in full alongside the frames: it is what lets an
  /// offline job reconstruct when tracking was lost, which the frame list alone
  /// cannot show because lost frames leave no frame behind.
  Map<String, dynamic> toJson() => <String, dynamic>{
        ...toSummaryJson(),
        'frames': frames.map((f) => f.toJson()).toList(growable: false),
        'tracking': samples.map((s) => s.toJson()).toList(growable: false),
      };
}
