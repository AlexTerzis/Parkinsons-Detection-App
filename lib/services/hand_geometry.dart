import 'dart:math' as math;

import '../models/landmark_point.dart';

/// MediaPipe hand landmark indices.
///
/// See https://developers.google.com/mediapipe/solutions/vision/hand_landmarker
///
/// Each finger runs MCP → PIP → DIP → TIP from the knuckle outward; the thumb
/// runs CMC → MCP → IP → TIP, one joint short, which is why it needs its own
/// handling nearly everywhere below.
abstract final class HandLandmark {
  static const int wrist = 0;

  static const int thumbCmc = 1;
  static const int thumbMcp = 2;
  static const int thumbIp = 3;
  static const int thumbTip = 4;

  static const int indexMcp = 5;
  static const int indexPip = 6;
  static const int indexDip = 7;
  static const int indexTip = 8;

  static const int middleMcp = 9;
  static const int middlePip = 10;
  static const int middleDip = 11;
  static const int middleTip = 12;

  static const int ringMcp = 13;
  static const int ringPip = 14;
  static const int ringDip = 15;
  static const int ringTip = 16;

  static const int pinkyMcp = 17;
  static const int pinkyPip = 18;
  static const int pinkyDip = 19;
  static const int pinkyTip = 20;

  /// A complete hand has this many landmarks.
  static const int count = 21;
}

/// The five digits.
///
/// The index finger is `indexFinger` rather than `index` because every Dart
/// enum already carries an `index` property giving its ordinal position.
enum Finger { thumb, indexFinger, middle, ring, pinky }

extension FingerLandmarks on Finger {
  /// The knuckle where this digit leaves the palm.
  int get mcp {
    switch (this) {
      case Finger.thumb:
        return HandLandmark.thumbMcp;
      case Finger.indexFinger:
        return HandLandmark.indexMcp;
      case Finger.middle:
        return HandLandmark.middleMcp;
      case Finger.ring:
        return HandLandmark.ringMcp;
      case Finger.pinky:
        return HandLandmark.pinkyMcp;
    }
  }

  /// The middle joint — PIP for the fingers, IP for the thumb.
  int get pip {
    switch (this) {
      case Finger.thumb:
        return HandLandmark.thumbIp;
      case Finger.indexFinger:
        return HandLandmark.indexPip;
      case Finger.middle:
        return HandLandmark.middlePip;
      case Finger.ring:
        return HandLandmark.ringPip;
      case Finger.pinky:
        return HandLandmark.pinkyPip;
    }
  }

  int get tip {
    switch (this) {
      case Finger.thumb:
        return HandLandmark.thumbTip;
      case Finger.indexFinger:
        return HandLandmark.indexTip;
      case Finger.middle:
        return HandLandmark.middleTip;
      case Finger.ring:
        return HandLandmark.ringTip;
      case Finger.pinky:
        return HandLandmark.pinkyTip;
    }
  }
}

/// Which way the palm is turned, relative to the camera.
enum PalmFacing {
  /// Palm toward the lens.
  toward,

  /// Back of the hand toward the lens.
  away,

  /// Turned side-on, where neither face is presented and the depth estimate is
  /// least reliable.
  edge,
}

/// Geometry primitives shared by everything that reads hand landmarks.
///
/// Extracted so the posture classifier and the movement analyzer measure the
/// hand the same way. Every spatial quantity is expressed in **palm widths**:
/// landmark coordinates are normalised to the frame, so an identical hand
/// produces larger numbers when it is nearer the lens, and dividing by the palm
/// removes that without removing the signal.
abstract final class HandGeometry {
  /// Straight-line distance between two landmarks.
  static double distance(LandmarkPoint a, LandmarkPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final dz = a.z - b.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Distance ignoring depth.
  ///
  /// MediaPipe's `z` is relative and weakly calibrated — much noisier than `x`
  /// and `y` — so comparisons that only need to know whether two points are
  /// near each other in the picture are steadier without it.
  static double distance2d(LandmarkPoint a, LandmarkPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// The scale reference: wrist to middle knuckle.
  ///
  /// The most stable span on the hand — unlike finger spans it barely changes
  /// with the movement being measured, so dividing by it removes distance to
  /// the camera without also removing what is being looked at.
  static double palmSpan(List<LandmarkPoint> lm) =>
      distance(lm[HandLandmark.wrist], lm[HandLandmark.middleMcp]);

  /// [palmSpan] using only the picture plane.
  static double palmSpan2d(List<LandmarkPoint> lm) =>
      distance2d(lm[HandLandmark.wrist], lm[HandLandmark.middleMcp]);

  /// Whether [lm] has the full set of landmarks.
  static bool isComplete(List<LandmarkPoint> lm) =>
      lm.length >= HandLandmark.count;

  /// The palm's outward normal, from the plane through wrist, index MCP and
  /// pinky MCP.
  ///
  /// Returns `null` when the three points are collinear and no plane exists.
  ///
  /// Note that MediaPipe's `z` is relative depth rather than a metric one, so
  /// this is a well-conditioned estimate of which way the palm is turned, not a
  /// true 3-D normal. Its sign is also mirrored between hands, since a left
  /// hand is the reflection of a right one.
  static List<double>? palmNormal(List<LandmarkPoint> lm) {
    final wrist = lm[HandLandmark.wrist];
    final index = lm[HandLandmark.indexMcp];
    final pinky = lm[HandLandmark.pinkyMcp];

    final ax = index.x - wrist.x;
    final ay = index.y - wrist.y;
    final az = index.z - wrist.z;
    final bx = pinky.x - wrist.x;
    final by = pinky.y - wrist.y;
    final bz = pinky.z - wrist.z;

    final nx = ay * bz - az * by;
    final ny = az * bx - ax * bz;
    final nz = ax * by - ay * bx;

    final double length = math.sqrt(nx * nx + ny * ny + nz * nz);
    if (length <= 1e-12) return null;
    return <double>[nx / length, ny / length, nz / length];
  }

  /// Which way the palm is turned, for a hand of the given [handedness].
  ///
  /// [edgeThreshold] is how much of the normal must point along the camera axis
  /// before the hand counts as facing it rather than being side-on.
  static PalmFacing palmFacing(
    List<LandmarkPoint> lm,
    String handedness, {
    double edgeThreshold = 0.35,
  }) {
    final normal = palmNormal(lm);
    if (normal == null) return PalmFacing.edge;

    // The cross product's sign flips with the mirroring between hands, so one
    // side is negated to make "toward the camera" mean the same thing for both.
    final double towardCamera =
        handedness == 'Left' ? -normal[2] : normal[2];

    if (towardCamera.abs() < edgeThreshold) return PalmFacing.edge;
    return towardCamera > 0 ? PalmFacing.toward : PalmFacing.away;
  }

  /// Whether [finger] is straightened out rather than curled into the palm.
  ///
  /// Measured by comparing how far the tip and the middle joint sit from the
  /// wrist: straightening a finger carries its tip away from the wrist, curling
  /// it brings the tip back toward the palm and inside the middle joint.
  ///
  /// Deliberately orientation-free. The obvious alternative — "the tip is above
  /// the joint on screen" — only works for a hand held upright, and this test
  /// is precisely about hands held at unusual angles.
  static bool isExtended(
    List<LandmarkPoint> lm,
    Finger finger, {
    double margin = 0.05,
  }) {
    final wrist = lm[HandLandmark.wrist];
    final double palm = palmSpan(lm);
    if (palm <= 0) return false;

    final double tipToWrist = distance(lm[finger.tip], wrist) / palm;
    final double pipToWrist = distance(lm[finger.pip], wrist) / palm;
    return tipToWrist > pipToWrist + margin;
  }

  /// How far the thumb is held away from the side of the index knuckle, in palm
  /// widths.
  ///
  /// Separates a thumb tucked across the palm from one held out. [isExtended]
  /// alone does not: the thumb can be straight and still folded flat against
  /// the hand, which is a different posture entirely.
  static double thumbAbduction(List<LandmarkPoint> lm) {
    final double palm = palmSpan(lm);
    if (palm <= 0) return 0;
    return distance(lm[HandLandmark.thumbTip], lm[HandLandmark.indexMcp]) /
        palm;
  }

  /// Distance between two fingertips, in palm widths.
  static double tipGap(List<LandmarkPoint> lm, Finger a, Finger b) {
    final double palm = palmSpan(lm);
    if (palm <= 0) return double.infinity;
    return distance(lm[a.tip], lm[b.tip]) / palm;
  }

  /// [tipGap] ignoring depth, for "are these two touching in the picture".
  static double tipGap2d(List<LandmarkPoint> lm, Finger a, Finger b) {
    final double palm = palmSpan2d(lm);
    if (palm <= 0) return double.infinity;
    return distance2d(lm[a.tip], lm[b.tip]) / palm;
  }
}
