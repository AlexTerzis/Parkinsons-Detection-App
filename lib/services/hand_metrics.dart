import 'dart:math' as math;

import '../models/landmark_point.dart';

/// Helper class for analyzing sequences of hand landmarks.
///
/// The landmark data expected by these utilities is a list where each entry
/// represents one landmark (e.g. thumb tip) tracked over time. Every landmark
/// is itself a list of [LandmarkPoint]s containing `x`, `y` and `z` coordinates recorded
/// for each frame:
///
/// ```
/// [
///   [LandmarkPoint(x: 0.1, y: 0.2, z: 0.0), LandmarkPoint(x: 0.1, y: 0.21, z: 0.02)],
///   [LandmarkPoint(x: 0.5, y: 0.4, z: -0.1), ...],
///   ... // one list per landmark
/// ]
/// ```
///
/// This mirrors the structure assembled in `CameraTestViewModel` and
/// `HandLandmarkerScreen` where the same landmark is tracked across multiple
/// frames.
class HandMetrics {
  /// Scale factors applied to variance metrics so the resulting values roughly
  /// map into a 0-1 range. They can be tuned per instance when the service is
  /// registered.
  final double speedVarScale;
  final double accelVarScale;
  final double jerkVarScale;

  const HandMetrics({
    this.speedVarScale = 10.0,
    this.accelVarScale = 10.0,
    this.jerkVarScale = 10.0,
  });

  /// 3D distance between two landmark points.
  double _distance(LandmarkPoint a, LandmarkPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final dz = a.z - b.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Returns the variance of [data] or `0` if not enough samples are present.
  double _variance(List<double> data) {
    if (data.length < 2) return 0;
    final mean = data.reduce((a, b) => a + b) / data.length;
    final sqSum = data.map((d) => (d - mean) * (d - mean)).reduce((a, b) => a + b);
    return sqSum / data.length;
  }

  /// Calculates speed variance across all provided landmark trajectories.
  /// The resulting value is scaled to roughly fall within 0-1.
  double speedVarianceAll(List<List<LandmarkPoint>> landmarks) {
    final List<double> displacements = [];
    for (final points in landmarks) {
      for (int i = 1; i < points.length; i++) {
        displacements.add(_distance(points[i], points[i - 1]));
      }
    }
    return _variance(displacements) * speedVarScale;
  }

  /// Calculates acceleration variance across all trajectories.
  ///
  /// Acceleration is approximated by the difference between consecutive
  /// displacements and therefore assumes roughly constant frame intervals.
  double accelerationVarianceAll(List<List<LandmarkPoint>> landmarks) {
    final List<double> accels = [];
    for (final points in landmarks) {
      if (points.length < 3) continue;
      final List<double> displacements = [];
      for (int i = 1; i < points.length; i++) {
        displacements.add(_distance(points[i], points[i - 1]));
      }
      for (int i = 1; i < displacements.length; i++) {
        accels.add(displacements[i] - displacements[i - 1]);
      }
    }
    return _variance(accels) * accelVarScale;
  }

  /// Calculates jerk variance across all trajectories.
  ///
  /// Jerk is derived from the change in acceleration, again assuming
  /// a constant sampling rate between frames.
  double jerkVarianceAll(List<List<LandmarkPoint>> landmarks) {
    final List<double> jerks = [];
    for (final points in landmarks) {
      if (points.length < 4) continue;
      final List<double> displacements = [];
      for (int i = 1; i < points.length; i++) {
        displacements.add(_distance(points[i], points[i - 1]));
      }
      final List<double> accels = [];
      for (int i = 1; i < displacements.length; i++) {
        accels.add(displacements[i] - displacements[i - 1]);
      }
      for (int i = 1; i < accels.length; i++) {
        jerks.add(accels[i] - accels[i - 1]);
      }
    }
    return _variance(jerks) * jerkVarScale;
  }

  /// Calculates tremor by averaging the standard deviation of x, y and z
  /// coordinates for each landmark trajectory.
  double tremorAll(List<List<LandmarkPoint>> landmarks) {
    final List<double> stdDevs = [];
    for (final points in landmarks) {
      if (points.length < 3) continue;
      final xs = points.map((p) => p.x).toList();
      final ys = points.map((p) => p.y).toList();
      final zs = points.map((p) => p.z).toList();

      final stdX = math.sqrt(_variance(xs));
      final stdY = math.sqrt(_variance(ys));
      final stdZ = math.sqrt(_variance(zs));

      stdDevs.add((stdX + stdY + stdZ) / 3);
    }
    if (stdDevs.isEmpty) return 0;
    return stdDevs.reduce((a, b) => a + b) / stdDevs.length;
  }

  /// Computes the average distance between the index fingertip (8) and
  /// pinky fingertip (20) across all frames. Returns `0` if data is missing.
  double fingerSpread(List<List<LandmarkPoint>> landmarks) {
    if (landmarks.length <= 20) return 0;
    final indexPoints = landmarks[8];
    final pinkyPoints = landmarks[20];
    final int len = math.min(indexPoints.length, pinkyPoints.length);
    if (len == 0) return 0;
    double total = 0;
    for (int i = 0; i < len; i++) {
      total += _distance(indexPoints[i], pinkyPoints[i]);
    }
    return total / len;
  }

  /// Returns a map from handedness ("Left" or "Right") to that hand's landmark list.
  Map<String, List<LandmarkPoint>> parseRawHands(List<dynamic> raw) {
    final out = <String, List<LandmarkPoint>>{};
    for (final handRaw in raw) {
      if (handRaw is Map) {
        final map = Map<String, dynamic>.from(handRaw);
        final side = map['handedness'] as String? ?? 'Unknown';
        final lms = map['landmarks'] as List?;
        if (lms != null) {
          final points = lms.map((lm) {
            final m = Map<String, dynamic>.from(lm as Map);
            return LandmarkPoint(
              x: (m['x'] ?? 0).toDouble(),
              y: (m['y'] ?? 0).toDouble(),
              z: (m['z'] ?? 0).toDouble(),
              score: (m['score'] ?? 0).toDouble(),
            );
          }).toList();
          out[side] = points;
        }
      }
    }
    return out;
  }

  /// Utility to build a single landmark trajectory from frame history. Frames
  /// where the landmark is missing are skipped.
  List<LandmarkPoint> extractTrajectory(
      List<List<LandmarkPoint>?> history, int landmarkIndex) {
    final List<LandmarkPoint> points = [];
    for (final frame in history) {
      if (frame != null && frame.length > landmarkIndex) {
        final LandmarkPoint p = frame[landmarkIndex];
        points.add(p);
      }
    }
    return points;
  }
}

