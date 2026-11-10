import '../models/hand_posture.dart';
import '../models/landmark_point.dart';
import 'hand_geometry.dart';

/// Reads a static hand posture from one frame of landmarks.
///
/// Pure and dependency-free, so every posture in the catalogue can be exercised
/// against fabricated landmarks without a camera or a running app.
///
/// # Why geometry rather than a model
///
/// A static hand shape is fully determined by the 21 landmarks, so a trained
/// classifier would be learning a function we can simply write down. Writing it
/// down means it needs no training data — of which there is none — and that a
/// posture that fails to register can be debugged by reading the numbers rather
/// than by guessing at a black box. The canned MediaPipe gesture recognizer was
/// the other candidate and knows only eight fixed gestures, which is neither
/// enough for this catalogue nor extensible.
class HandPostureClassifier {
  const HandPostureClassifier({
    this.extensionMargin = defaultExtensionMargin,
    this.thumbAbductionThreshold = defaultThumbAbduction,
  });

  /// How much further from the wrist a fingertip must sit than its middle joint
  /// before the finger counts as straight, in palm widths.
  ///
  /// A margin rather than a bare comparison, so a finger hovering between bent
  /// and straight does not flicker between states frame to frame.
  static const double defaultExtensionMargin = 0.05;

  /// Thumb tip to index knuckle, in palm widths, above which the thumb counts
  /// as held out rather than folded against the hand.
  ///
  /// The thumb needs its own rule: it can be perfectly straight and still lie
  /// flat across the palm, which is a different posture from a thumb held out,
  /// and the wrist-distance test used for the fingers cannot tell them apart.
  static const double defaultThumbAbduction = 0.9;

  final double extensionMargin;
  final double thumbAbductionThreshold;

  /// Describes the hand in [landmarks], or `null` when the frame cannot support
  /// a description.
  ///
  /// Returns `null` rather than a default-valued shape: an incomplete hand is
  /// not a fist, and letting it read as one would score a tracking failure as a
  /// posture the patient never made.
  HandShape? describe(List<LandmarkPoint> landmarks, {String handedness = 'Right'}) {
    if (!HandGeometry.isComplete(landmarks)) return null;
    if (HandGeometry.palmSpan(landmarks) <= 0) return null;

    final extended = <Finger>{};
    for (final finger in const <Finger>[
      Finger.indexFinger,
      Finger.middle,
      Finger.ring,
      Finger.pinky,
    ]) {
      if (HandGeometry.isExtended(landmarks, finger, margin: extensionMargin)) {
        extended.add(finger);
      }
    }

    final double abduction = HandGeometry.thumbAbduction(landmarks);

    return HandShape(
      extended: extended,
      // Both conditions: straightened *and* carried away from the hand.
      thumbExtended: HandGeometry.isExtended(
            landmarks,
            Finger.thumb,
            margin: extensionMargin,
          ) &&
          abduction >= thumbAbductionThreshold,
      thumbAbduction: abduction,
      thumbGaps: <Finger, double>{
        for (final finger in const <Finger>[
          Finger.indexFinger,
          Finger.middle,
          Finger.ring,
          Finger.pinky,
        ])
          // Measured in the picture plane. Whether two fingertips are touching
          // is exactly the kind of small separation that MediaPipe's relative
          // depth is too noisy to judge, and including it made pinches read as
          // open more often than not.
          finger: HandGeometry.tipGap2d(landmarks, Finger.thumb, finger),
      },
      indexMiddleGap:
          HandGeometry.tipGap2d(landmarks, Finger.indexFinger, Finger.middle),
      facing: HandGeometry.palmFacing(landmarks, handedness),
    );
  }

  /// The posture in [landmarks], or `null` if it is not one of [candidates].
  ///
  /// A hand between two postures matches neither, which is the point: the test
  /// asks for a posture to be held, and a hand passing through one on its way
  /// somewhere else has not copied anything.
  HandPosture? identify(
    List<LandmarkPoint> landmarks, {
    List<HandPosture> candidates = HandPostures.all,
    String handedness = 'Right',
  }) {
    final shape = describe(landmarks, handedness: handedness);
    if (shape == null) return null;
    for (final posture in candidates) {
      if (posture.matches(shape)) return posture;
    }
    return null;
  }

  /// Whether [landmarks] show [posture].
  bool isPosture(
    List<LandmarkPoint> landmarks,
    HandPosture posture, {
    String handedness = 'Right',
  }) {
    final shape = describe(landmarks, handedness: handedness);
    return shape != null && posture.matches(shape);
  }
}
