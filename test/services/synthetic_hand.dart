import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/services/hand_geometry.dart';

/// Builds 21 landmarks for a hand in a chosen posture.
///
/// The equivalent of `test/services/scoring/synthetic_recording.dart` for static
/// shapes: a hand can be fabricated with exactly the fingers wanted and the
/// classifier checked against what was put in, with no camera and no device.
///
/// Laid out palm-toward-camera with the fingers pointing "up" the frame (toward
/// smaller y). The wrist sits below the knuckles, and every length is a multiple
/// of [palm] so the whole hand scales as one — which is what lets [scale] verify
/// that nothing depends on how near the lens the hand is.
abstract final class SyntheticHand {
  /// Wrist-to-middle-knuckle span, the classifier's unit of length.
  static const double palm = 0.12;

  static const double _wristX = 0.5;
  static const double _wristY = 0.62;
  static const double _knuckleY = _wristY - palm;

  /// Finger length, measured from the knuckle.
  static const double _fingerLength = 0.11;

  /// Where each finger's knuckle sits across the hand.
  static const Map<Finger, double> _knuckleX = <Finger, double>{
    Finger.indexFinger: 0.455,
    Finger.middle: 0.5,
    Finger.ring: 0.545,
    Finger.pinky: 0.59,
  };

  /// A hand with [extended] fingers straight and the rest curled.
  ///
  /// [thumbOut] holds the thumb away from the hand; otherwise it is tucked
  /// across the palm. [spreadIndexMiddle] separates the index and middle tips,
  /// which is the only difference between a V-sign and two fingers held
  /// together. [pinchIndexToThumb] closes the thumb and a curled index into a
  /// ring. [scale] multiplies every coordinate about the origin.
  static List<LandmarkPoint> build({
    Set<Finger> extended = const <Finger>{},
    bool thumbOut = false,
    bool spreadIndexMiddle = false,
    bool pinchIndexToThumb = false,
    double scale = 1.0,
    double z = 0.0,
  }) {
    final points = List<LandmarkPoint>.filled(
      HandLandmark.count,
      const LandmarkPoint(x: 0, y: 0, z: 0),
    );

    LandmarkPoint at(double x, double y, [double depth = 0]) =>
        LandmarkPoint(x: x * scale, y: y * scale, z: (depth + z) * scale);

    points[HandLandmark.wrist] = at(_wristX, _wristY);

    for (final entry in _knuckleX.entries) {
      final Finger finger = entry.key;
      double x = entry.value;

      // Spreading moves the two tips apart without moving the knuckles, which
      // is what actually happens when the fingers are separated.
      double tipX = x;
      if (spreadIndexMiddle && finger == Finger.indexFinger) tipX -= 0.055;
      if (spreadIndexMiddle && finger == Finger.middle) tipX += 0.055;

      points[finger.mcp] = at(x, _knuckleY);

      if (extended.contains(finger)) {
        points[finger.pip] = at(x, _knuckleY - _fingerLength * 0.4);
        // DIP always sits one index below TIP for all four fingers.
        points[finger.tip - 1] = at(tipX, _knuckleY - _fingerLength * 0.7);
        points[finger.tip] = at(tipX, _knuckleY - _fingerLength);
      } else {
        // Curled: the tip comes back past the knuckle toward the wrist, which
        // is exactly what the extension test looks for.
        points[finger.pip] = at(x, _knuckleY - _fingerLength * 0.4);
        points[finger.tip - 1] = at(x, _knuckleY - _fingerLength * 0.18);
        points[finger.tip] = at(x, _knuckleY + 0.02);
      }
    }

    // The thumb runs CMC → MCP → IP → TIP down the side of the hand.
    if (thumbOut) {
      points[HandLandmark.thumbCmc] = at(0.46, 0.60);
      points[HandLandmark.thumbMcp] = at(0.42, 0.575);
      points[HandLandmark.thumbIp] = at(0.375, 0.548);
      points[HandLandmark.thumbTip] = at(0.33, 0.52);
    } else if (pinchIndexToThumb) {
      // Curled round to meet a curled index fingertip.
      final double tipX = _knuckleX[Finger.indexFinger]!;
      const double tipY = _knuckleY + 0.02;
      points[HandLandmark.thumbCmc] = at(0.46, 0.60);
      points[HandLandmark.thumbMcp] = at(0.425, 0.575);
      points[HandLandmark.thumbIp] = at(0.43, 0.535);
      points[HandLandmark.thumbTip] = at(tipX, tipY);
    } else {
      // Tucked flat across the front of the palm.
      points[HandLandmark.thumbCmc] = at(0.46, 0.60);
      points[HandLandmark.thumbMcp] = at(0.455, 0.575);
      points[HandLandmark.thumbIp] = at(0.475, 0.558);
      points[HandLandmark.thumbTip] = at(0.50, 0.545);
    }

    return points;
  }

  /// A hand halfway between a fist and an open palm, where the fingers are
  /// neither clearly straight nor clearly curled.
  static List<LandmarkPoint> midTransition() {
    final points = build();
    // Lift every fingertip to just short of the extension margin.
    for (final finger in _knuckleX.keys) {
      final double x = _knuckleX[finger]!;
      points[finger.tip] = LandmarkPoint(
        x: x,
        y: _knuckleY - _fingerLength * 0.42,
        z: 0,
      );
    }
    return points;
  }
}
