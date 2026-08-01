import '../ui/views/camera_test/camera_task_protocol.dart';
import 'landmark_point.dart';

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
  });

  final String taskId;

  /// `'Left'` or `'Right'` — the hand under examination for [taskId].
  final String hand;

  /// Milliseconds since epoch, as reported when the frame was detected.
  final int timestamp;

  /// The 21 MediaPipe hand landmarks for [hand] in this frame.
  final List<LandmarkPoint> landmarks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'taskId': taskId,
        'hand': hand,
        't': timestamp,
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
  CameraTaskSegment({required this.task});

  final CameraTask task;

  final List<TaggedFrame> frames = <TaggedFrame>[];

  /// Frames in which the examined hand was not visible. Kept because a task
  /// with few frames and many misses means "hand out of view", which is a very
  /// different thing from "hand held still".
  int missedFrames = 0;

  DateTime? startedAt;
  DateTime? endedAt;

  String get taskId => task.id;
  String get hand => task.hand;

  /// Effective capture rate, derived from the first and last frame timestamps.
  ///
  /// Measured rather than assumed: the variance metrics in [HandMetrics] treat
  /// consecutive frames as evenly spaced, so a low or uneven rate directly
  /// weakens the result and a reviewer needs to see it.
  double get fps {
    if (frames.length < 2) return 0;
    final int spanMs = frames.last.timestamp - frames.first.timestamp;
    if (spanMs <= 0) return 0;
    return (frames.length - 1) * 1000 / spanMs;
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
      };

  /// The full segment including landmark data — uploaded to Storage, never
  /// written to Firestore.
  Map<String, dynamic> toJson() => <String, dynamic>{
        ...toSummaryJson(),
        'frames': frames.map((f) => f.toJson()).toList(growable: false),
      };
}
