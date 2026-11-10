import 'landmark_point.dart';

/// One hand as reported by the detector for a single frame.
class LandmarkData {
  const LandmarkData({
    required this.handedness,
    required this.landmarks,
    this.handednessConfidence,
  });

  /// `'Left'`, `'Right'`, or `'Unknown'`.
  ///
  /// Reported from the *camera's* point of view, so a mirrored front-facing
  /// preview can label the hands the opposite way round from what the patient
  /// sees. Consistent within a run — left/right comparisons hold either way —
  /// but not guaranteed to be anatomically correct.
  final String handedness;

  /// The MediaPipe hand landmarks, frame-normalized.
  final List<LandmarkPoint> landmarks;

  /// The detector's confidence in the [handedness] call, 0-1, or `null` when
  /// the native layer did not report one.
  ///
  /// `null` is "unknown", never "zero" — a build whose native side predates the
  /// score must not have every frame treated as a marginal detection.
  final double? handednessConfidence;
}

/// Everything the detector produced for one processed camera frame.
///
/// A frame with no hands is still a frame, and is still delivered: see
/// [TrackingState] for why the empty case has to be recorded rather than
/// dropped.
class FrameData {
  const FrameData({required this.timestamp, required this.hands});

  /// Milliseconds since epoch, taken when the frame was received.
  final int timestamp;

  /// Hands seen in this frame; empty when the detector found none.
  final List<LandmarkData> hands;

  /// The entry for [hand], or `null` when that hand was not among [hands].
  LandmarkData? handFor(String hand) {
    for (final candidate in hands) {
      if (candidate.handedness == hand) return candidate;
    }
    return null;
  }
}
