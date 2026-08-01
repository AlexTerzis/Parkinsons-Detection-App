import 'dart:math' as math;

import '../../models/camera_task_protocol.dart';
import '../tremor_analysis_service.dart';
import 'camera_recording.dart';
import 'camera_scorer.dart';
import 'enhanced_scoring_config.dart';
import 'movement_cycle_analyzer.dart';

/// Multi-feature heuristic over the MDS-UPDRS task sequence.
///
/// Where the original scorer averages positional variance across both hands,
/// this reads each task as the movement it actually is and measures the signs
/// the scale is looking for: decrementing amplitude and speed, irregular
/// rhythm, hesitations, delayed initiation, slowness, and asymmetry between the
/// hands — plus tremor, taken from [TremorAnalysisService] so that voluntary
/// movement has already been removed.
///
/// Features that could not be measured are reported as unmeasured and their
/// weight is redistributed across the rest, so a recording that only supports
/// half the features is not silently scored as healthy on the other half.
class HeuristicScorer implements CameraScorer {
  const HeuristicScorer({
    MovementCycleAnalyzer cycleAnalyzer = const MovementCycleAnalyzer(),
    TremorAnalysisService tremorAnalyzer = const TremorAnalysisService(),
  })  : _cycles = cycleAnalyzer,
        _tremor = tremorAnalyzer;

  final MovementCycleAnalyzer _cycles;
  final TremorAnalysisService _tremor;

  @override
  String get id => 'heuristic_v1';

  @override
  CameraScore score(CameraRecording recording) {
    final analyses = <String, _HandAnalysis>{};
    for (final hand in CameraTaskProtocol.hands) {
      analyses[hand] = _analyzeHand(recording, hand);
    }

    final withData =
        analyses.values.where((a) => a.hasData).toList(growable: false);
    final notes = <String>[];

    if (withData.isEmpty) {
      return CameraScore(
        scorerId: id,
        likelihood: 0,
        confidence: 0,
        features: EnhancedScoringConfig.weights.entries
            .map((e) => FeatureContribution.unmeasured(
                  name: e.key,
                  weight: e.value,
                  note: 'No usable movement data in the recording.',
                ))
            .toList(growable: false),
        notes: const <String>['Recording contained no usable movement tasks.'],
      );
    }

    if (withData.length == 1) {
      notes.add('Only the ${withData.first.hand.toLowerCase()} hand produced '
          'usable data; asymmetry could not be measured.');
    }

    // --- Raw feature values, averaged over the hands that produced them ---

    double? mean(double? Function(_HandAnalysis) pick) {
      final values = withData.map(pick).whereType<double>().toList();
      if (values.isEmpty) return null;
      return values.reduce((a, b) => a + b) / values.length;
    }

    final double? tapRate = mean((a) => a.tapRate);
    final double? rhythm = mean((a) => a.rhythmVariability);
    final double? amplitudeDecrement = mean((a) => a.amplitudeDecrement);
    final double? speedDecrement = mean((a) => a.speedDecrement);
    final double? meanSpeed = mean((a) => a.meanSpeed);
    final double? initiationDelay = mean((a) => a.initiationDelay);
    final double? pauseBurden = mean((a) => a.pauseBurden);
    final double? smoothness = mean((a) => a.smoothness);
    final double? tremorSeverity = mean((a) => a.tremorSeverity);

    // Asymmetry needs both hands by definition.
    double? asymmetry;
    if (withData.length == 2) {
      final a = withData[0].bradykinesiaComposite;
      final b = withData[1].bradykinesiaComposite;
      if (a != null && b != null) asymmetry = (a - b).abs();
    }

    if (analyses.values.any((a) => a.tremorFrequencyUnavailable)) {
      notes.add('Tremor frequency was unavailable for at least one task, so '
          'tremor severity is discounted rather than frequency-confirmed.');
    }

    // --- Normalize ---

    const config = EnhancedScoringConfig.weights;
    final drafts = <_Draft>[
      _Draft('tremor', tremorSeverity, config['tremor']!,
          // Already 0-1 from _HandAnalysis, which folds in the band check.
          normalizer: (v) => v.clamp(0.0, 1.0)),
      _Draft('tap_rate', tapRate, config['tap_rate']!,
          normalizer: EnhancedScoringConfig.tapRate.normalize),
      _Draft('rhythm_variability', rhythm, config['rhythm_variability']!,
          normalizer: EnhancedScoringConfig.rhythmVariability.normalize),
      _Draft('amplitude_decrement', amplitudeDecrement,
          config['amplitude_decrement']!,
          normalizer: EnhancedScoringConfig.amplitudeDecrement.normalize),
      _Draft('speed_decrement', speedDecrement, config['speed_decrement']!,
          normalizer: EnhancedScoringConfig.speedDecrement.normalize),
      _Draft('mean_speed', meanSpeed, config['mean_speed']!,
          normalizer: EnhancedScoringConfig.meanSpeed.normalize),
      _Draft('initiation_delay', initiationDelay, config['initiation_delay']!,
          normalizer: EnhancedScoringConfig.initiationDelay.normalize),
      _Draft('pause_burden', pauseBurden, config['pause_burden']!,
          normalizer: EnhancedScoringConfig.pauseBurden.normalize),
      _Draft('smoothness', smoothness, config['smoothness']!,
          normalizer: EnhancedScoringConfig.smoothness.normalize),
      _Draft('asymmetry', asymmetry, config['asymmetry']!,
          normalizer: EnhancedScoringConfig.asymmetry.normalize),
    ];

    // Redistribute the weight of unmeasured features across the measured ones,
    // so likelihood stays on a 0-1 scale and is comparable between recordings
    // that supported different feature sets.
    final double measuredWeight = drafts
        .where((d) => d.raw != null)
        .fold<double>(0, (sum, d) => sum + d.weight);

    if (measuredWeight <= 0) {
      return CameraScore(
        scorerId: id,
        likelihood: 0,
        confidence: 0,
        features: drafts
            .map((d) => FeatureContribution.unmeasured(
                  name: d.name,
                  weight: d.weight,
                  note: 'Not measurable from this recording.',
                ))
            .toList(growable: false),
        notes: notes,
      );
    }

    final unmeasured = drafts.where((d) => d.raw == null).toList();
    if (unmeasured.isNotEmpty) {
      notes.add('${unmeasured.length} of ${drafts.length} features were not '
          'measurable (${unmeasured.map((d) => d.name).join(', ')}); their '
          'weight was redistributed across the rest.');
    }

    final features = <FeatureContribution>[];
    double likelihood = 0;

    for (final draft in drafts) {
      if (draft.raw == null) {
        features.add(FeatureContribution.unmeasured(
          name: draft.name,
          weight: 0,
          note: 'Not measurable from this recording; nominal weight '
              '${draft.weight} redistributed.',
        ));
        continue;
      }
      final double normalized = draft.normalizer(draft.raw!);
      final double effectiveWeight = draft.weight / measuredWeight;
      likelihood += normalized * effectiveWeight;
      features.add(FeatureContribution(
        name: draft.name,
        raw: draft.raw,
        normalized: normalized,
        weight: effectiveWeight,
      ));
    }

    return CameraScore(
      scorerId: id,
      likelihood: likelihood.clamp(0.0, 1.0),
      confidence: _confidence(recording, analyses.values, measuredWeight),
      features: features,
      notes: notes,
    );
  }

  // --- Per hand ---

  _HandAnalysis _analyzeHand(CameraRecording recording, String hand) {
    final metrics = <CycleMetrics>[];
    for (final task in recording.tasksFor(hand)) {
      if (!task.isScored) continue;
      metrics.add(_cycles.analyze(task));
    }

    // Tremor is measured on the REST tasks only.
    //
    // TremorAnalysisService separates tremor from voluntary movement by
    // low-passing at 4 Hz and keeping the residual, which assumes voluntary
    // movement stays below that. Finger tapping at 5 taps/second breaks the
    // assumption outright: the tapping itself lands in the 4-6 Hz parkinsonian
    // band and is measured as severe tremor, so a fast healthy tapper would
    // score higher on tremor than a slow patient with a real one.
    //
    // Restricting to rest sidesteps this entirely and matches the clinical
    // reading — rest tremor is the classic parkinsonian sign. The cost is that
    // pure action tremor is not captured; that needs a method which can tell
    // 5 Hz tremor from 5 Hz voluntary movement, which this one cannot.
    double? worstRms;
    double? worstFrequency;
    bool frequencyUnavailable = false;

    for (final task in recording.tasksFor(hand)) {
      if (task.isScored || task.frames.length < 8) continue;
      final analysis = _tremor.analyzeHand(task.allTrajectories());
      if (analysis.dominantFrequencyHz == null) frequencyUnavailable = true;
      if (worstRms == null || analysis.rms > worstRms) {
        worstRms = analysis.rms;
        worstFrequency = analysis.dominantFrequencyHz;
      }
    }

    return _HandAnalysis(
      hand: hand,
      metrics: metrics,
      tremorRms: worstRms,
      tremorFrequencyHz: worstFrequency,
      tremorFrequencyUnavailable: frequencyUnavailable,
    );
  }

  // --- Confidence ---

  /// How much the recording itself supports the likelihood, 0-1.
  ///
  /// Blends the mean of the quality factors with the worst of them, so a single
  /// bad dimension — the hand out of frame, say — drags confidence down instead
  /// of being averaged away by the others.
  double _confidence(
    CameraRecording recording,
    Iterable<_HandAnalysis> analyses,
    double measuredWeight,
  ) {
    final double fpsFactor = _between(
      recording.meanFps,
      EnhancedScoringConfig.minimumUsableFps,
      EnhancedScoringConfig.fullConfidenceFps,
    );

    final double coverageFactor = recording.meanCoverage.clamp(0.0, 1.0);

    final int tasksWithData = recording.movementTasks
        .where((t) => t.frames.isNotEmpty)
        .length;
    final double taskFactor = (tasksWithData /
            EnhancedScoringConfig.expectedMovementTasks)
        .clamp(0.0, 1.0);

    final cycleCounts = analyses
        .expand((a) => a.metrics)
        .where((m) => m.durationSeconds > 0)
        .map((m) => (m.cycleCount / EnhancedScoringConfig.confidentCycleCount)
            .clamp(0.0, 1.0))
        .toList();
    final double cycleFactor = cycleCounts.isEmpty
        ? 0
        : cycleCounts.reduce((a, b) => a + b) / cycleCounts.length;

    // How much of the intended weighting was actually measurable.
    final double featureFactor = measuredWeight.clamp(0.0, 1.0);

    final factors = <double>[
      fpsFactor,
      coverageFactor,
      taskFactor,
      cycleFactor,
      featureFactor,
    ];
    final double mean = factors.reduce((a, b) => a + b) / factors.length;
    final double worst = factors.reduce(math.min);
    return (0.5 * mean + 0.5 * worst).clamp(0.0, 1.0);
  }

  double _between(double value, double min, double max) {
    if (max <= min) return 0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }
}

/// One feature on its way to becoming a [FeatureContribution].
class _Draft {
  _Draft(this.name, this.raw, this.weight, {required this.normalizer});

  final String name;
  final double? raw;
  final double weight;
  final double Function(double) normalizer;
}

/// Everything measured for a single hand.
class _HandAnalysis {
  _HandAnalysis({
    required this.hand,
    required this.metrics,
    required this.tremorRms,
    required this.tremorFrequencyHz,
    required this.tremorFrequencyUnavailable,
  });

  final String hand;
  final List<CycleMetrics> metrics;
  final double? tremorRms;
  final double? tremorFrequencyHz;
  final bool tremorFrequencyUnavailable;

  bool get hasData => metrics.any((m) => m.cycleCount > 0 || m.meanSpeed != null);

  double? _mean(double? Function(CycleMetrics) pick) {
    final values = metrics.map(pick).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Tap rate comes only from the finger-tapping task; the other movements are
  /// paced differently and averaging them together would be meaningless.
  double? get tapRate {
    for (final m in metrics) {
      if (m.taskId.endsWith('_${CameraTaskType.fingerTap.name}')) {
        return m.rateHz;
      }
    }
    return null;
  }

  double? get rhythmVariability => _mean((m) => m.rhythmVariability);
  double? get amplitudeDecrement => _mean((m) => m.amplitudeDecrement);
  double? get speedDecrement => _mean((m) => m.speedDecrement);
  double? get meanSpeed => _mean((m) => m.meanSpeed);
  double? get initiationDelay => _mean((m) => m.initiationDelaySeconds);
  double? get smoothness => _mean((m) => m.smoothness);

  double? get pauseBurden {
    final values = metrics
        .where((m) => m.durationSeconds > 0)
        .map((m) => m.pauseSeconds / m.durationSeconds)
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Tremor severity 0-1: amplitude against the configured range, discounted
  /// when the frequency is not in the parkinsonian band or is unknown.
  double? get tremorSeverity {
    if (tremorRms == null) return null;
    final double base = EnhancedScoringConfig.tremorRms.normalize(tremorRms!);
    final double? f = tremorFrequencyHz;
    final bool inBand = f != null &&
        f >= EnhancedScoringConfig.tremorBandMinHz &&
        f <= EnhancedScoringConfig.tremorBandMaxHz;
    return inBand
        ? base
        : base * EnhancedScoringConfig.outOfBandTremorFactor;
  }

  /// This hand's overall bradykinesia level, 0-1, used only for the
  /// left-versus-right comparison.
  double? get bradykinesiaComposite {
    final parts = <double>[
      if (tapRate != null) EnhancedScoringConfig.tapRate.normalize(tapRate!),
      if (rhythmVariability != null)
        EnhancedScoringConfig.rhythmVariability.normalize(rhythmVariability!),
      if (amplitudeDecrement != null)
        EnhancedScoringConfig.amplitudeDecrement.normalize(amplitudeDecrement!),
      if (speedDecrement != null)
        EnhancedScoringConfig.speedDecrement.normalize(speedDecrement!),
      if (meanSpeed != null)
        EnhancedScoringConfig.meanSpeed.normalize(meanSpeed!),
    ];
    if (parts.isEmpty) return null;
    return parts.reduce((a, b) => a + b) / parts.length;
  }
}
