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
  /// Every hand is kept, including two that claim the same side.
  ///
  /// MediaPipe's left/right call regularly gives both hands one label when
  /// they are held up together. Dropping the second as a "duplicate", as this
  /// used to, threw away a real hand — so a step recording both hands only
  /// ever saw one of them. The test now tells hands apart by where they are in
  /// the picture (see `HandAssignment`), so the label being wrong costs
  /// nothing as long as both hands arrive.
  List<LandmarkData> parseHands(List<dynamic> raw) {
    final out = <LandmarkData>[];

    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);

      final String side = map['handedness'] as String? ?? 'Unknown';

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

  /// Parses a whole native payload into a frame.
  ///
  /// Current builds send `{timestampMs, hands}`, where the timestamp is when
  /// the camera captured the frame. Older builds sent the bare list of hands;
  /// those are still accepted and stamped with [fallbackTimestamp].
  FrameData parseFrame(dynamic raw, {required int fallbackTimestamp}) {
    if (raw is Map) {
      final hands = raw['hands'];
      final ts = raw['timestampMs'];
      return FrameData(
        timestamp: ts is num ? ts.toInt() : fallbackTimestamp,
        hands: parseHands(hands is List ? hands : const <dynamic>[]),
      );
    }
    return FrameData(
      timestamp: fallbackTimestamp,
      hands: parseHands(raw is List ? raw : const <dynamic>[]),
    );
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
