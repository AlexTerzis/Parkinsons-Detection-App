import '../models/frame_data.dart';
import '../models/landmark_point.dart';

/// Turns the native detector's payload into [LandmarkData].
///
/// Split out from `HandMetrics` so the camera preview does not have to depend
/// on the scoring helpers merely to decode a frame. That dependency is what let
/// an earlier version of the preview compute and display live symptom metrics;
/// removing it makes the layering enforce the separation rather than relying on
/// nobody reaching for it.
///
/// Every field is read defensively: this is a platform-channel boundary, and a
/// malformed payload must degrade to "no hand" rather than throw on the camera
/// thread.
class LandmarkParser {
  const LandmarkParser();

  /// Parses one `onLandmarks` payload.
  ///
  /// Hands whose handedness repeats within a frame are kept once — MediaPipe is
  /// configured for two hands, and two entries claiming the same side means the
  /// classifier is confused, so the first is taken and the duplicate dropped.
  List<LandmarkData> parseHands(List<dynamic> raw) {
    final out = <LandmarkData>[];
    final seen = <String>{};

    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);

      final String side = map['handedness'] as String? ?? 'Unknown';
      if (!seen.add(side)) continue;

      final points = map['landmarks'];
      if (points is! List) continue;

      out.add(LandmarkData(
        handedness: side,
        landmarks: points
            .map(_parsePoint)
            .whereType<LandmarkPoint>()
            .toList(growable: false),
        // Absent on builds whose native layer predates the score. Left null
        // rather than defaulted, so "unknown" stays distinguishable from a
        // genuinely low confidence.
        handednessConfidence: (map['handednessScore'] as num?)?.toDouble(),
      ));
    }
    return out;
  }

  LandmarkPoint? _parsePoint(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return LandmarkPoint(
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
      z: (map['z'] as num?)?.toDouble() ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0,
    );
  }
}
