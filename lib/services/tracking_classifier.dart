import '../models/frame_data.dart';
import '../models/landmark_point.dart';
import '../models/tracking_event.dart';

/// Decides what one camera frame was worth, for the hand under examination.
///
/// Pure and dependency-free, so the whole taxonomy in [TrackingState] can be
/// exercised against fabricated frames without a camera, a platform channel or
/// a running app.
class TrackingClassifier {
  const TrackingClassifier({
    this.minimumHandednessConfidence = defaultMinimumHandednessConfidence,
    this.frameMargin = defaultFrameMargin,
    this.expectedLandmarks = 21,
    this.acceptLoneHandAsTarget = true,
  });

  /// Below this, the detector's Left/Right call is treated as marginal.
  ///
  /// MediaPipe is configured with a 0.5 minimum, so anything it reports at all
  /// clears that. This sits above it: between 0.5 and 0.75 the classifier is
  /// closer to guessing than deciding, and a run whose hand assignment is a
  /// coin flip cannot support a left-versus-right comparison. PROVISIONAL —
  /// it has not been fitted to recordings from this app.
  static const double defaultMinimumHandednessConfidence = 0.75;

  /// How far outside the normalized frame a landmark may sit before the hand
  /// counts as clipped.
  ///
  /// MediaPipe extrapolates landmarks past the image edge rather than clamping
  /// them, so coordinates outside 0-1 are the signal that part of the hand left
  /// the view. The tolerance is generous because that extrapolation is noisy at
  /// the boundary: a hand held fully in shot routinely reports a fingertip a
  /// percent or two outside it, and a tight margin flagged those frames as
  /// clipped often enough to fail otherwise good recordings on a real device.
  static const double defaultFrameMargin = 0.08;

  final double minimumHandednessConfidence;
  final double frameMargin;
  final int expectedLandmarks;

  /// Whether a single visible hand is taken to be the hand under examination,
  /// even when the detector labels it as the other side.
  ///
  /// On by default, because the label is the least trustworthy thing in this
  /// pipeline. The front camera's frames are mirrored before the detector sees
  /// them, and a mirrored right hand is geometrically identical to a left one —
  /// so an uncorrected build reports every hand as the wrong side, and the
  /// guided protocol then rejects every task the patient records. The native
  /// layer now undoes that, but nothing guarantees the app is running against a
  /// build that does, or that a different device mirrors the same way.
  ///
  /// The protocol tells the patient which hand to use and shows it on screen
  /// throughout. When exactly one hand is present, that instruction is better
  /// evidence than a label that can be inverted wholesale. Such frames are
  /// recorded as [TrackingState.lowConfidence] rather than as clean ones, so
  /// the disagreement stays visible in the data instead of being smoothed away.
  ///
  /// It does mean a patient who uses the wrong hand is not caught. That is a
  /// real cost, accepted because the alternative — as observed on a device —
  /// is that nobody can complete the test at all.
  final bool acceptLoneHandAsTarget;

  /// Classifies [frame] against the hand named by [targetHand].
  ///
  /// The order of the checks is the order of usefulness to the patient: being
  /// told to bring the hand back into view is actionable, whereas a marginal
  /// handedness score is not something they can do anything about, so clipping
  /// is reported in preference to low confidence when both apply.
  TrackingEvent classify({
    required FrameData frame,
    required String targetHand,
  }) {
    final int handCount = frame.hands.length;

    if (handCount == 0) {
      return TrackingEvent(
        timestamp: frame.timestamp,
        state: TrackingState.noHand,
      );
    }

    LandmarkData? match = frame.handFor(targetHand);

    // Exactly one hand, labelled as the other side: trust the instruction the
    // patient was given over the label. See [acceptLoneHandAsTarget].
    final bool labelDisagreed =
        match == null && acceptLoneHandAsTarget && handCount == 1;
    if (labelDisagreed) match = frame.hands.single;

    if (match == null) {
      return TrackingEvent(
        timestamp: frame.timestamp,
        state: TrackingState.wrongHand,
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

    final TrackingState state;
    if (_isClipped(match.landmarks)) {
      state = TrackingState.partiallyOutOfFrame;
    } else if (labelDisagreed ||
        (match.handednessConfidence != null &&
            match.handednessConfidence! < minimumHandednessConfidence)) {
      state = TrackingState.lowConfidence;
    } else {
      state = TrackingState.tracked;
    }

    return TrackingEvent(
      timestamp: frame.timestamp,
      state: state,
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
