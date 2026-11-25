import 'dart:math' as math;

import '../../models/camera_task_protocol.dart';
import '../tremor_analysis_service.dart';
import 'camera_recording.dart';
import 'movement_cycle_analyzer.dart';
import 'task_quality.dart';

/// Maps a raw measurement onto the 0-4 rating scale by linear interpolation
/// between five anchors: the values that correspond to ratings 0, 1, 2, 3, 4.
///
/// Anchors may run either way. Rising anchors mean a higher raw value is worse
/// (more hesitations, more decrement); falling anchors mean a lower one is
/// (slower tapping).
class RatingAnchors {
  const RatingAnchors(this.values);

  final List<double> values;

  double rate(double raw) {
    final bool falling = values.first > values.last;
    final List<double> a = falling ? values.map((v) => -v).toList() : values;
    final double x = falling ? -raw : raw;

    if (x <= a.first) return 0;
    if (x >= a.last) return 4;
    for (int i = 1; i < a.length; i++) {
      if (x <= a[i]) {
        final double span = a[i] - a[i - 1];
        final double t = span <= 0 ? 1 : (x - a[i - 1]) / span;
        return (i - 1) + t;
      }
    }
    return 4;
  }
}

/// The thresholds behind every rating.
///
/// Modelled on the MDS-UPDRS Part III anchors. The scale's examiner judges
/// speed, amplitude, hesitations and decrement and gives the item 0 (normal),
/// 1 (slight), 2 (mild), 3 (moderate) or 4 (severe); here each of those signs
/// is measured and mapped onto the same 0-4 range.
///
/// **PROVISIONAL.** These are reasoned from the scale's wording and from
/// published video-based tapping studies, not fitted to recordings from this
/// app. They are the numbers to adjust once clinician-rated recordings exist.
abstract final class MotorRatingRules {
  static const String version = 'motor_rating_v1';

  // --- Speed: cycles per second, lower is worse ---

  /// Finger taps per second. Healthy adults tapping "big and fast" on video
  /// typically manage 3 or more.
  static const RatingAnchors tapRate =
      RatingAnchors(<double>[3.0, 2.3, 1.6, 1.0, 0.5]);

  /// Full open-and-close cycles per second.
  static const RatingAnchors openCloseRate =
      RatingAnchors(<double>[2.0, 1.5, 1.0, 0.6, 0.3]);

  /// Full palm up-and-down turns per second.
  static const RatingAnchors rotationRate =
      RatingAnchors(<double>[1.8, 1.3, 0.9, 0.5, 0.25]);

  // --- Interruptions ---

  /// Hesitations in a 10-second task. The scale's wording: 1-2 interruptions
  /// is slight, 3-5 mild, more than 5 moderate.
  static const RatingAnchors pauses =
      RatingAnchors(<double>[0.5, 1.5, 3.5, 6, 10]);

  /// Irregular rhythm, as the coefficient of variation of the intervals
  /// between movements. A steady rhythm sits around 0.1.
  static const RatingAnchors rhythm =
      RatingAnchors(<double>[0.15, 0.25, 0.40, 0.60, 0.90]);

  // --- Decrement ---

  /// Fraction of movement size lost from the first third of the task to the
  /// last. Some loss over 10 seconds is ordinary fatigue.
  static const RatingAnchors decrement =
      RatingAnchors(<double>[0.15, 0.25, 0.40, 0.60, 0.85]);

  /// A task with fewer complete movements than this, while the hand was in
  /// view the whole time, is rated as "can barely perform" (4).
  static const int minimumCycles = 3;

  // --- Tremor ---

  /// Peak-to-peak tremor in centimetres. The scale's bands: up to 1 cm is
  /// slight, 1-3 cm mild, 3-10 cm moderate, over 10 cm severe. The first
  /// anchor sits above landmark jitter so a still hand rates 0.
  static const RatingAnchors tremorCm =
      RatingAnchors(<double>[0.4, 1.0, 3.0, 10.0, 20.0]);

  /// Typical adult palm length, wrist to the base of the middle finger, used
  /// to turn the picture's units into centimetres.
  static const double palmLengthCm = 9.5;

  /// Parkinsonian tremor band. A tremor outside it is discounted.
  static const double tremorBandMinHz = 3.5;
  static const double tremorBandMaxHz = 7.5;

  /// Multiplier when the tremor's frequency is outside the band.
  static const double outOfBandFactor = 0.5;

  /// Multiplier when the frequency could not be measured (too few frames per
  /// second), so the rating is on amplitude alone.
  static const double unknownFrequencyFactor = 0.75;

  // --- The overall score ---

  /// How the 0-1 score is built from the per-hand ratings. See
  /// [MotorRating.score].
  static const double wBradykinesia = 0.60;
  static const double wTremor = 0.25;
  static const double wAsymmetry = 0.15;
}

/// The rating of one task for one hand.
class ItemRating {
  const ItemRating({
    required this.taskId,
    required this.hand,
    required this.type,
    required this.rating,
    required this.signs,
    this.note,
  });

  final String taskId;
  final String hand;
  final CameraTaskType type;

  /// 0-4, continuous. 0 normal, 1 slight, 2 mild, 3 moderate, 4 severe.
  final double rating;

  /// The sub-ratings it was built from, each 0-4 — e.g. `speed`, `pauses`,
  /// `rhythm`, `decrement`, `tremor` — with the raw value alongside.
  final Map<String, SignRating> signs;

  /// Why the rating is what it is, when that is not obvious from [signs].
  final String? note;

  /// The whole-number grade shown to people.
  int get grade => rating.round().clamp(0, 4);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'taskId': taskId,
        'hand': hand,
        'taskType': type.name,
        'mdsUpdrsItem': type.mdsUpdrsItem,
        'rating': rating,
        'grade': grade,
        'signs': <String, dynamic>{
          for (final entry in signs.entries) entry.key: entry.value.toJson(),
        },
        if (note != null) 'note': note,
      };
}

/// One measured sign and the rating it maps to.
class SignRating {
  const SignRating({required this.raw, required this.rating});

  final double raw;
  final double rating;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'raw': raw,
        'rating': rating,
      };
}

/// Every rating for one hand.
class HandRating {
  const HandRating({required this.hand, required this.items});

  final String hand;
  final List<ItemRating> items;

  ItemRating? itemOf(CameraTaskType type) {
    for (final item in items) {
      if (item.type == type) return item;
    }
    return null;
  }

  /// Mean of the three movement items, 0-4, or `null` when none was rated.
  double? get bradykinesia {
    final values = items
        .where((i) => i.type.isScored)
        .map((i) => i.rating)
        .toList(growable: false);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// The worse of rest and postural tremor, 0-4, or `null` when neither was
  /// rated.
  double? get tremor {
    final values = items
        .where((i) => i.type.isTremor)
        .map((i) => i.rating)
        .toList(growable: false);
    if (values.isEmpty) return null;
    return values.reduce(math.max);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'hand': hand,
        'bradykinesia': bradykinesia,
        'tremor': tremor,
        'items': items.map((i) => i.toJson()).toList(growable: false),
      };
}

/// The whole recording's ratings and the single score derived from them.
class MotorRating {
  const MotorRating({required this.hands});

  final List<HandRating> hands;

  HandRating? handRating(String hand) {
    for (final h in hands) {
      if (h.hand == hand) return h;
    }
    return null;
  }

  /// The hand with the higher bradykinesia rating — Parkinson's usually
  /// starts on one side, so the worse hand is what the score follows. `null`
  /// when no hand had a rated movement.
  HandRating? get worseHand {
    HandRating? worst;
    for (final h in hands) {
      final b = h.bradykinesia;
      if (b == null) continue;
      if (worst == null || b > worst.bradykinesia!) worst = h;
    }
    return worst;
  }

  /// Difference between the hands' bradykinesia ratings, 0-4, or `null` when
  /// both were not rated.
  double? get asymmetry {
    final values = hands
        .map((h) => h.bradykinesia)
        .whereType<double>()
        .toList(growable: false);
    if (values.length < 2) return null;
    return (values[0] - values[1]).abs();
  }

  /// The worst tremor of either hand, 0-4, or `null`.
  double? get tremor {
    final values =
        hands.map((h) => h.tremor).whereType<double>().toList(growable: false);
    if (values.isEmpty) return null;
    return values.reduce(math.max);
  }

  /// The test's score, 0-1, where higher means more signs. `null` when no
  /// movement could be rated, in which case nothing is scored.
  ///
  /// `(0.60 × B + 0.25 × T + 0.15 × A) / 4`, where
  /// * B is the worse hand's bradykinesia rating (0-4),
  /// * T is the worst tremor rating of either hand (0-4),
  /// * A is the left/right difference in bradykinesia, doubled and capped at 4
  ///   — a one-point gap between the hands is already a notable asymmetry.
  ///
  /// When T or A cannot be measured their weight is shared out over the rest,
  /// so the score stays on the same 0-1 range. Dividing by 4 keeps the reading
  /// simple: a score of 0.25 is roughly "slight" (1) and 0.5 roughly "mild"
  /// (2) on the rating scale.
  double? get score {
    final b = worseHand?.bradykinesia;
    if (b == null) return null;

    double sum = MotorRatingRules.wBradykinesia * b;
    double weight = MotorRatingRules.wBradykinesia;

    final t = tremor;
    if (t != null) {
      sum += MotorRatingRules.wTremor * t;
      weight += MotorRatingRules.wTremor;
    }
    final a = asymmetry;
    if (a != null) {
      sum += MotorRatingRules.wAsymmetry * math.min(4.0, 2 * a);
      weight += MotorRatingRules.wAsymmetry;
    }
    return (sum / weight / 4).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'scorer_id': MotorRatingRules.version,
        'score': score,
        'worse_hand': worseHand?.hand,
        'bradykinesia': worseHand?.bradykinesia,
        'tremor': tremor,
        'asymmetry': asymmetry,
        'hands': <String, dynamic>{
          for (final h in hands) h.hand: h.toJson(),
        },
      };
}

/// Rates a recording task by task, the way an examiner would rate each item.
///
/// Only tasks that passed the recording-quality check are rated. A task the
/// camera could not see properly says nothing about the patient, and rating it
/// would turn a bad recording into a finding.
class MotorRatingScorer {
  const MotorRatingScorer({
    MovementCycleAnalyzer cycleAnalyzer = const MovementCycleAnalyzer(),
    TremorAnalysisService tremorAnalyzer = const TremorAnalysisService(),
    TaskQualityValidator validator = const TaskQualityValidator(),
  })  : _cycles = cycleAnalyzer,
        _tremor = tremorAnalyzer,
        _validator = validator;

  final MovementCycleAnalyzer _cycles;
  final TremorAnalysisService _tremor;
  final TaskQualityValidator _validator;

  MotorRating rate(
    CameraRecording recording, {
    Map<String, TaskQuality> qualities = const <String, TaskQuality>{},
  }) {
    final hands = <HandRating>[];
    for (final hand in CameraTaskProtocol.hands) {
      final items = <ItemRating>[];
      for (final task in recording.tasksFor(hand)) {
        final quality = qualities[task.taskId] ?? _validator.validate(task);
        if (!quality.valid) continue;
        final item = task.isScored ? rateMovement(task) : rateTremor(task);
        if (item != null) items.add(item);
      }
      hands.add(HandRating(hand: hand, items: items));
    }
    return MotorRating(hands: hands);
  }

  /// Rates one movement task (finger tap, open/close, palm turning).
  ItemRating? rateMovement(RecordedTask task) {
    final CycleMetrics m = _cycles.analyze(task);
    if (m.durationSeconds <= 0) return null;

    if (m.cycleCount < MotorRatingRules.minimumCycles) {
      return ItemRating(
        taskId: task.taskId,
        hand: task.hand,
        type: task.type,
        rating: 4,
        signs: <String, SignRating>{
          'speed': SignRating(raw: m.rateHz ?? 0, rating: 4),
        },
        note: 'Fewer than ${MotorRatingRules.minimumCycles} complete '
            'movements while the hand was in view.',
      );
    }

    final signs = <String, SignRating>{};
    final rate = m.rateHz;
    if (rate != null) {
      signs['speed'] = SignRating(raw: rate, rating: _speedAnchors(task.type).rate(rate));
    }
    signs['pauses'] = SignRating(
      raw: m.pauseCount.toDouble(),
      rating: MotorRatingRules.pauses.rate(m.pauseCount.toDouble()),
    );
    // Rhythm between hesitations; the hesitations themselves are `pauses`.
    final rhythm = m.steadyRhythmVariability ?? m.rhythmVariability;
    if (rhythm != null) {
      signs['rhythm'] =
          SignRating(raw: rhythm, rating: MotorRatingRules.rhythm.rate(rhythm));
    }
    final decrement = m.amplitudeDecrement;
    if (decrement != null) {
      signs['decrement'] = SignRating(
          raw: decrement, rating: MotorRatingRules.decrement.rate(decrement));
    }

    // Pauses and rhythm are two views of the same sign — interruptions — so
    // they count once, as the worse of the two.
    final dimensions = <double>[
      if (signs['speed'] != null) signs['speed']!.rating,
      math.max(signs['pauses']!.rating, signs['rhythm']?.rating ?? 0),
      if (signs['decrement'] != null) signs['decrement']!.rating,
    ];

    // The worst sign counts most, as it does for an examiner, but averaged
    // with the rest so one noisy measurement alone cannot add a whole point.
    final double worst = dimensions.reduce(math.max);
    final double mean = dimensions.reduce((a, b) => a + b) / dimensions.length;

    return ItemRating(
      taskId: task.taskId,
      hand: task.hand,
      type: task.type,
      rating: (0.5 * worst + 0.5 * mean).clamp(0.0, 4.0),
      signs: signs,
    );
  }

  /// Rates one still task (rest or arms held out) for tremor.
  ItemRating? rateTremor(RecordedTask task) {
    if (task.frames.length < 8) return null;
    final double? palm = palmLength(task);
    if (palm == null || palm <= 0) return null;

    final TremorAnalysis analysis = _tremor.analyzeHand(task.allTrajectories());
    // Amplitude is half the peak-to-peak span, in picture units; the scale's
    // bands are peak-to-peak in centimetres.
    final double cm =
        2 * analysis.amplitude / palm * MotorRatingRules.palmLengthCm;

    double rating = MotorRatingRules.tremorCm.rate(cm);
    final double? f = analysis.dominantFrequencyHz;
    String? note;
    if (f == null) {
      rating *= MotorRatingRules.unknownFrequencyFactor;
      note = 'Frequency could not be measured; rated on amplitude alone.';
    } else if (f < MotorRatingRules.tremorBandMinHz ||
        f > MotorRatingRules.tremorBandMaxHz) {
      rating *= MotorRatingRules.outOfBandFactor;
      note = 'Movement was outside the typical tremor frequency range.';
    }

    return ItemRating(
      taskId: task.taskId,
      hand: task.hand,
      type: task.type,
      rating: rating.clamp(0.0, 4.0),
      signs: <String, SignRating>{
        'tremor_cm': SignRating(raw: cm, rating: rating),
        if (f != null) 'frequency_hz': SignRating(raw: f, rating: rating),
      },
      note: note,
    );
  }

  static RatingAnchors _speedAnchors(CameraTaskType type) {
    switch (type) {
      case CameraTaskType.fingerTap:
        return MotorRatingRules.tapRate;
      case CameraTaskType.openClose:
        return MotorRatingRules.openCloseRate;
      case CameraTaskType.pronationSupination:
      case CameraTaskType.rest:
      case CameraTaskType.posture:
        return MotorRatingRules.rotationRate;
    }
  }

  /// Median wrist-to-middle-knuckle length in picture units, the ruler that
  /// turns tremor amplitude into centimetres.
  static double? palmLength(RecordedTask task) {
    final lengths = <double>[];
    for (final frame in task.frames) {
      if (frame.landmarks.length < 10) continue;
      final wrist = frame.landmarks[0];
      final knuckle = frame.landmarks[9];
      final dx = wrist.x - knuckle.x;
      final dy = wrist.y - knuckle.y;
      lengths.add(math.sqrt(dx * dx + dy * dy));
    }
    if (lengths.isEmpty) return null;
    lengths.sort();
    return lengths[lengths.length ~/ 2];
  }
}
