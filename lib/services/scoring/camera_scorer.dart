import 'camera_recording.dart';

/// One feature's journey from measurement to its share of the likelihood.
///
/// Keeping the raw, normalized and weighted values together is what makes a
/// score explainable: a reviewer can see that a high likelihood came from, say,
/// amplitude decrement rather than from tremor. It is also the shape an ML
/// model's feature attribution would take, so the breakdown stays meaningful
/// after a swap.
class FeatureContribution {
  const FeatureContribution({
    required this.name,
    required this.raw,
    required this.normalized,
    required this.weight,
    this.note,
  });

  /// A feature that could not be measured at all.
  ///
  /// Carries [note] explaining why. Its [normalized] value is 0, but callers
  /// should read [measured] rather than treating that 0 as "no symptom" — the
  /// difference between "no tremor" and "could not measure tremor" matters.
  const FeatureContribution.unmeasured({
    required this.name,
    required this.weight,
    required String this.note,
  })  : raw = null,
        normalized = 0;

  final String name;

  /// The feature in its own units (taps/second, seconds, fraction), or `null`
  /// when it could not be measured.
  final double? raw;

  /// [raw] mapped to 0-1, where 1 is more parkinsonian.
  final double normalized;

  /// This feature's share of the total. Weights across a score sum to 1.
  final double weight;

  /// Why the feature is unmeasured, or any caveat on its value.
  final String? note;

  bool get measured => raw != null;

  /// What this feature actually added to the likelihood.
  double get contribution => normalized * weight;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'raw': raw,
        'normalized': normalized,
        'weight': weight,
        'contribution': contribution,
        'measured': measured,
        if (note != null) 'note': note,
      };
}

/// What a scorer returns.
class CameraScore {
  const CameraScore({
    required this.scorerId,
    required this.likelihood,
    required this.confidence,
    required this.features,
    this.notes = const <String>[],
  });

  /// Which scorer produced this, so stored results stay interpretable after
  /// the scorers change.
  final String scorerId;

  /// 0-1. Explicitly *not* a probability of disease — it is this scorer's
  /// weighted read of the movement features.
  final double likelihood;

  /// 0-1 trust in [likelihood], driven by data quality: capture rate, how much
  /// of the time the hand was actually visible, how many tasks completed, and
  /// how many movement cycles were detected. A confident-looking likelihood
  /// from a recording where the hand was out of frame would be worse than
  /// useless.
  final double confidence;

  final List<FeatureContribution> features;

  /// Anything a reviewer should know about how this score was arrived at.
  final List<String> notes;

  /// Features that contributed most, strongest first.
  List<FeatureContribution> get topContributors {
    final sorted = List<FeatureContribution>.of(features)
      ..sort((a, b) => b.contribution.compareTo(a.contribution));
    return sorted;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'scorer_id': scorerId,
        'likelihood': likelihood,
        'confidence': confidence,
        'features': features.map((f) => f.toJson()).toList(growable: false),
        if (notes.isNotEmpty) 'notes': notes,
      };
}

/// Turns a recording into a score.
///
/// The point of this interface is that the heuristic below it is replaceable.
/// A trained model would implement exactly this — taking a [CameraRecording]
/// and returning a [CameraScore] whose `features` carry its inputs or its
/// attributions — and nothing that calls a scorer would need to change.
///
/// Implementations must be pure: same recording in, same score out, no I/O.
/// That is what allows several to run on one recording and be compared.
abstract interface class CameraScorer {
  /// Stable identifier stored alongside results, e.g. `heuristic_v1`. Version
  /// it whenever the maths changes, so old documents remain interpretable.
  String get id;

  CameraScore score(CameraRecording recording);
}
