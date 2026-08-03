/// A raw-to-0-1 mapping for one feature.
class FeatureRange {
  const FeatureRange({
    required this.min,
    required this.max,
    this.inverted = false,
  });

  /// Raw value mapping to 0 (or to 1 when [inverted]).
  final double min;

  /// Raw value mapping to 1 (or to 0 when [inverted]).
  final double max;

  /// True when a *lower* raw value is the more parkinsonian one — slower
  /// tapping, lower speed, smoother-is-better metrics.
  final bool inverted;

  /// Maps [raw] onto 0-1, where 1 is always the more parkinsonian end
  /// regardless of which direction the underlying quantity runs.
  double normalize(double raw) {
    if (max == min) return 0;
    final double t = ((raw - min) / (max - min)).clamp(0.0, 1.0);
    return inverted ? 1 - t : t;
  }
}

/// Weights and normalization ranges for [HeuristicScorer], and the flag that
/// decides which scorer's likelihood is stored as the test's score.
///
/// # These ranges are provisional
///
/// They are reasoned from two sources: the geometry of MediaPipe's normalized
/// landmarks (which fixes the units — most spatial features here are in
/// palm-widths), and published descriptions of the MDS-UPDRS Part III hand
/// items and their typical performance ranges. **None of them are fitted to
/// recordings from this app**, because no labelled recordings exist yet.
///
/// Until they are calibrated, the enhanced likelihood is a research output, not
/// a clinical one, and [useEnhancedScoring] should stay `false`. Phase 3 stores
/// both scorers' results on every recording precisely so that calibration
/// becomes possible.
abstract final class EnhancedScoringConfig {
  /// Selects which scorer's likelihood populates `TestResult.score`.
  ///
  /// Both scorers always run and both results are always stored; this only
  /// decides which one the rest of the app sees. Defaults to the original
  /// scorer, so behaviour is unchanged until this is deliberately flipped.
  ///
  /// Before flipping it in production, note that `results_tab.dart` and
  /// `patience_viewmodel.dart` average `score` across time — historical legacy
  /// scores and new enhanced scores are not on the same scale, and mixing them
  /// in one trend line would be misleading.
  static const bool useEnhancedScoring = false;

  // --- Weights (must sum to 1.0; asserted by test) ---

  /// Tremor carries real but not dominant weight: it is the most specific sign
  /// here, yet a substantial share of Parkinson's presents without prominent
  /// tremor, so bradykinesia features together outweigh it.
  static const double wTremor = 0.15;

  static const double wTapRate = 0.12;
  static const double wRhythm = 0.12;

  /// Decrement is weighted alongside tremor as the most specific bradykinesia
  /// sign — healthy people slow down when tired, but the progressive
  /// amplitude decay across a 10-second task is characteristic.
  static const double wAmplitudeDecrement = 0.15;

  static const double wSpeedDecrement = 0.10;
  static const double wMeanSpeed = 0.08;
  static const double wInitiationDelay = 0.06;
  static const double wPauseBurden = 0.08;
  static const double wSmoothness = 0.06;
  static const double wAsymmetry = 0.08;

  /// Every weight, for validation and for iterating.
  static const Map<String, double> weights = <String, double>{
    'tremor': wTremor,
    'tap_rate': wTapRate,
    'rhythm_variability': wRhythm,
    'amplitude_decrement': wAmplitudeDecrement,
    'speed_decrement': wSpeedDecrement,
    'mean_speed': wMeanSpeed,
    'initiation_delay': wInitiationDelay,
    'pause_burden': wPauseBurden,
    'smoothness': wSmoothness,
    'asymmetry': wAsymmetry,
  };

  // --- Normalization ranges ---

  /// Tremor RMS from `TremorAnalysisService`, in frame-normalized landmark
  /// units.
  ///
  /// The lower bound is that service's own noise floor (0.01% of frame width,
  /// sub-pixel on any real camera). The upper bound, 2% of frame width, is
  /// roughly a fifth of a typical palm width at arm's length — a pronounced,
  /// plainly visible tremor. PROVISIONAL.
  static const FeatureRange tremorRms =
      FeatureRange(min: 0.0001, max: 0.02);

  /// Multiplier applied to tremor severity when the dominant frequency does
  /// *not* fall in the parkinsonian band, or could not be measured at all
  /// (below 15 fps — see `TremorAnalysisService.minimumFrequencyFps`).
  ///
  /// Residual movement at the right frequency is far more meaningful than the
  /// same amount of residual at any frequency, but out-of-band residual is not
  /// nothing either, so this discounts rather than zeroes it. PROVISIONAL.
  static const double outOfBandTremorFactor = 0.6;

  /// Parkinsonian tremor band, Hz. Rest tremor classically sits at 4-6 Hz;
  /// the window is opened slightly to allow for measurement spread.
  static const double tremorBandMinHz = 3.5;
  static const double tremorBandMaxHz = 7.0;

  /// Finger-tap rate, taps/second (MDS-UPDRS item 3.4).
  ///
  /// Healthy adults sustain roughly 5-7 taps/s; moderate bradykinesia falls
  /// below about 3, and severe well under 2. Inverted: slower is worse.
  /// PROVISIONAL.
  static const FeatureRange tapRate =
      FeatureRange(min: 1.0, max: 6.0, inverted: true);

  /// Coefficient of variation of inter-cycle intervals.
  ///
  /// A metronomic tapper lands near 0.05; 0.5 is grossly irregular. This is
  /// dimensionless, so it is the range least dependent on the camera setup.
  /// PROVISIONAL.
  static const FeatureRange rhythmVariability =
      FeatureRange(min: 0.05, max: 0.5);

  /// Fractional amplitude lost from the first third of a task to the last.
  ///
  /// Some falloff over 10 seconds is normal fatigue; losing half the amplitude
  /// is the decrementing sign proper. PROVISIONAL.
  static const FeatureRange amplitudeDecrement =
      FeatureRange(min: 0.05, max: 0.5);

  /// The same, on per-cycle peak speed. PROVISIONAL.
  static const FeatureRange speedDecrement =
      FeatureRange(min: 0.05, max: 0.5);

  /// Mean speed of the cycle signal, in palm-widths per second.
  ///
  /// A hand tapping at 4 Hz through one palm-width of travel averages roughly
  /// 8 palm-widths/s. Inverted: slower is worse. PROVISIONAL.
  static const FeatureRange meanSpeed =
      FeatureRange(min: 1.0, max: 10.0, inverted: true);

  /// Seconds from the task starting to the first detected movement.
  ///
  /// Allows for normal reaction time at the bottom; 2s of hesitation before
  /// starting a movement already described in words is the akinetic sign.
  /// PROVISIONAL.
  static const FeatureRange initiationDelay =
      FeatureRange(min: 0.3, max: 2.0);

  /// Fraction of the task spent in hesitations, as detected relative to the
  /// patient's own median rhythm. PROVISIONAL.
  static const FeatureRange pauseBurden =
      FeatureRange(min: 0.0, max: 0.3);

  /// Log dimensionless jerk of the cycle signal's speed profile.
  ///
  /// Higher (less negative) is smoother, hence inverted. The bounds bracket
  /// what clean synthetic oscillation and heavily perturbed movement produce
  /// through this pipeline; they are the most pipeline-specific numbers here
  /// and the ones most in need of calibration. PROVISIONAL.
  static const FeatureRange smoothness =
      FeatureRange(min: -14.0, max: -4.0, inverted: true);

  /// Absolute difference between the hands' bradykinesia composites, 0-1.
  ///
  /// Parkinson's is characteristically asymmetric at onset, which is what makes
  /// this worth its own weight rather than being averaged away. PROVISIONAL.
  static const FeatureRange asymmetry =
      FeatureRange(min: 0.05, max: 0.4);

  // --- Confidence ---

  /// Capture rate at or above which frame rate stops limiting confidence.
  ///
  /// Above this the cycle metrics are well sampled even for fast tapping; at
  /// half of it, a 6 Hz tap has only a couple of frames per cycle.
  static const double fullConfidenceFps = 25.0;

  /// Below this, the recording is too sparse for the cycle metrics to mean
  /// much and confidence bottoms out.
  static const double minimumUsableFps = 10.0;

  /// Cycles in a task before its rhythm and decrement figures are trusted.
  static const int confidentCycleCount = 8;

  /// Movement tasks in a full protocol: three per hand, two hands.
  static const int expectedMovementTasks = 6;
}
