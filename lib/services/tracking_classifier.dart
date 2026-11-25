import '../models/frame_data.dart';
import '../models/landmark_point.dart';
import '../models/tracking_event.dart';

/// Decides which detected hand is which, from where it is in the picture.
///
/// MediaPipe labels each hand Left or Right, but that label is the least
/// reliable thing in the pipeline: it flips with camera mirroring, it is often
/// the same for both hands when they are held up together, and an earlier
/// version of this app trusted it and ended up measuring the resting hand
/// instead of the moving one.
///
/// Position is much more dependable. The front camera's picture is mirrored
/// before detection, exactly like the preview the patient sees, so their right
/// hand is on the right of the picture (larger x) and their left hand on the
/// left. With two hands in view the rightmost is the right hand. With one hand
/// in view during a one-hand step, it is the hand under examination — the
/// patient was told which hand to use and to keep the other one down.
abstract final class HandAssignment {
  /// Assigns detected hands to [targetHands] (`'Left'` / `'Right'`).
  ///
  /// Every target gets an entry; `null` means that hand was not in the frame.
  static Map<String, LandmarkData?> assign(
    FrameData frame,
    List<String> targetHands,
  ) {
    final hands = frame.hands.where((h) => h.landmarks.isNotEmpty).toList()
      ..sort((a, b) => centreX(a).compareTo(centreX(b)));

    final out = <String, LandmarkData?>{
      for (final target in targetHands) target: null,
    };
    if (hands.isEmpty) return out;

    if (targetHands.length == 1) {
      final target = targetHands.single;
      if (hands.length == 1) {
        out[target] = hands.single;
      } else {
        out[target] = target == 'Right' ? hands.last : hands.first;
      }
      return out;
    }

    if (hands.length >= 2) {
      if (out.containsKey('Left')) out['Left'] = hands.first;
      if (out.containsKey('Right')) out['Right'] = hands.last;
      return out;
    }

    // One hand during a both-hands step: it is whichever side it is on.
    final only = hands.single;
    final side = centreX(only) >= 0.5 ? 'Right' : 'Left';
    if (out.containsKey(side)) out[side] = only;
    return out;
  }

  /// Horizontal centre of a hand in the (mirrored) picture, 0-1.
  static double centreX(LandmarkData hand) {
    double sum = 0;
    for (final point in hand.landmarks) {
      sum += point.x;
    }
    return sum / hand.landmarks.length;
  }
}

/// Decides what one camera frame was worth, for each hand under examination.
///
/// Pure and dependency-free, so the whole taxonomy in [TrackingState] can be
/// exercised against fabricated frames without a camera, a platform channel or
/// a running app.
class TrackingClassifier {
  const TrackingClassifier({
    this.frameMargin = defaultFrameMargin,
    this.expectedLandmarks = 21,
  });

  /// How far outside the normalized frame a landmark may sit before the hand
  /// counts as clipped.
  ///
  /// MediaPipe extrapolates landmarks past the image edge rather than clamping
  /// them, so coordinates outside 0-1 are the signal that part of the hand left
  /// the view. The tolerance is generous because that extrapolation is noisy at
  /// the boundary: a hand held fully in shot routinely reports a fingertip a
  /// percent or two outside it.
  static const double defaultFrameMargin = 0.08;

  final double frameMargin;
  final int expectedLandmarks;

  /// Classifies [frame] for the single hand [targetHand].
  TrackingEvent classify({
    required FrameData frame,
    required String targetHand,
  }) =>
      classifyAll(frame: frame, targetHands: <String>[targetHand])[targetHand]!;

  /// One event per hand in [targetHands], with that hand's landmarks when it
  /// was found.
  Map<String, TrackingEvent> classifyAll({
    required FrameData frame,
    required List<String> targetHands,
  }) {
    final assigned = HandAssignment.assign(frame, targetHands);
    final int handCount = frame.hands.length;

    return <String, TrackingEvent>{
      for (final target in targetHands)
        target: _eventFor(frame, assigned[target], handCount),
    };
  }

  TrackingEvent _eventFor(FrameData frame, LandmarkData? match, int handCount) {
    if (match == null) {
      return TrackingEvent(
        timestamp: frame.timestamp,
        state: TrackingState.noHand,
        handCount: handCount,
      );
    }

    if (match.landmarks.length < expectedLandmarks) {
      return TrackingEvent(
        timestamp: frame.timestamp,
        state: TrackingState.incompleteLandmarks,
        handednessConfidence: match.handednessConfidence,
        handCount: handCount,
      );
    }

    return TrackingEvent(
      timestamp: frame.timestamp,
      state: _isClipped(match.landmarks)
          ? TrackingState.partiallyOutOfFrame
          : TrackingState.tracked,
      landmarks: match.landmarks,
      handednessConfidence: match.handednessConfidence,
      handCount: handCount,
    );
  }

  bool _isClipped(List<LandmarkPoint> landmarks) {
    final double low = -frameMargin;
    final double high = 1 + frameMargin;
    for (final point in landmarks) {
      if (point.x < low || point.x > high || point.y < low || point.y > high) {
        return true;
      }
    }
    return false;
  }
}
