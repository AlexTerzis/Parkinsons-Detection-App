/// Simple container for a single landmark coordinate.
/// All values are expected to be normalized (0-1 range) as produced by
/// MediaPipe.
class LandmarkPoint {
  /// Horizontal position.
  final double x;
  /// Vertical position.
  final double y;
  /// Depth coordinate.
  final double z;
  /// Optional confidence score from the detector.
  final double score;

  const LandmarkPoint({
    required this.x,
    required this.y,
    required this.z,
    this.score = 0,
  });
}
