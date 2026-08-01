import 'camera_recording.dart';
import 'camera_scorer.dart';
import 'enhanced_scoring_config.dart';
import 'heuristic_scorer.dart';
import 'legacy_weighted_scorer.dart';

/// Both scorers' verdicts on one recording.
class ScoringComparison {
  const ScoringComparison({
    required this.legacy,
    required this.enhanced,
    required this.selected,
  });

  final CameraScore legacy;
  final CameraScore enhanced;

  /// The score that populates `TestResult.score`, chosen by
  /// [EnhancedScoringConfig.useEnhancedScoring].
  final CameraScore selected;

  double get likelihood => selected.likelihood;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'selected': selected.scorerId,
        'legacy': legacy.toJson(),
        'enhanced': enhanced.toJson(),
      };
}

/// Runs every scorer on the same recording and reports all of them.
///
/// Running both is the point rather than an overhead: the enhanced scorer's
/// normalization ranges are provisional, and the only way to calibrate them is
/// to accumulate recordings where both verdicts are known. Both are pure local
/// arithmetic over a few thousand landmarks, so the cost is negligible.
///
/// Adding a trained model later means adding it to [_scorers] and giving it a
/// key here; nothing else changes.
class CameraScoringService {
  const CameraScoringService({
    CameraScorer legacy = const LegacyWeightedScorer(),
    CameraScorer enhanced = const HeuristicScorer(),
  })  : _legacy = legacy,
        _enhanced = enhanced;

  final CameraScorer _legacy;
  final CameraScorer _enhanced;

  List<CameraScorer> get _scorers => <CameraScorer>[_legacy, _enhanced];

  /// Every scorer's id, for callers that want to know what ran.
  List<String> get scorerIds =>
      _scorers.map((s) => s.id).toList(growable: false);

  ScoringComparison scoreAll(CameraRecording recording) {
    final legacy = _legacy.score(recording);
    final enhanced = _enhanced.score(recording);

    return ScoringComparison(
      legacy: legacy,
      enhanced: enhanced,
      selected:
          EnhancedScoringConfig.useEnhancedScoring ? enhanced : legacy,
    );
  }
}
