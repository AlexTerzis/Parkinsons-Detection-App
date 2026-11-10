import 'dart:math' as math;

import '../../models/camera_task_protocol.dart';
import '../../models/landmark_point.dart';
import 'camera_recording.dart';

/// MediaPipe hand landmark indices used here.
///
/// See https://developers.google.com/mediapipe/solutions/vision/hand_landmarker
abstract final class _Landmark {
  static const int wrist = 0;
  static const int thumbTip = 4;
  static const int indexMcp = 5;
  static const int indexTip = 8;
  static const int middleMcp = 9;
  static const int middleTip = 12;
  static const int ringTip = 16;
  static const int pinkyMcp = 17;
  static const int pinkyTip = 20;
}

/// What one repetitive movement task looked like.
///
/// Every field is nullable where it genuinely may not be measurable: a task
/// with two detected cycles cannot support a decrement estimate, and saying so
/// is better than returning a number computed from nothing.
class CycleMetrics {
  const CycleMetrics({
    required this.taskId,
    required this.hand,
    required this.durationSeconds,
    required this.fps,
    required this.cycleCount,
    this.rateHz,
    this.rhythmVariability,
    this.amplitudeDecrement,
    this.speedDecrement,
    this.meanSpeed,
    this.maxSpeed,
    this.initiationDelaySeconds,
    this.smoothness,
    this.pauseCount = 0,
    this.pauseSeconds = 0,
    this.meanAmplitude,
  });

  /// An empty result for a task with no usable signal.
  const CycleMetrics.empty({required this.taskId, required this.hand})
      : durationSeconds = 0,
        fps = 0,
        cycleCount = 0,
        rateHz = null,
        rhythmVariability = null,
        amplitudeDecrement = null,
        speedDecrement = null,
        meanSpeed = null,
        maxSpeed = null,
        initiationDelaySeconds = null,
        smoothness = null,
        pauseCount = 0,
        pauseSeconds = 0,
        meanAmplitude = null;

  final String taskId;
  final String hand;
  final double durationSeconds;
  final double fps;

  /// Complete movement cycles detected (one open *and* close, one tap down
  /// *and* up).
  final int cycleCount;

  /// Cycles per second over the whole task, so hesitation and a slow start
  /// pull it down — which is the clinically meaningful reading.
  final double? rateHz;

  /// Coefficient of variation of the intervals between cycles. 0 is
  /// metronomic; parkinsonian movement is irregular.
  final double? rhythmVariability;

  /// Fraction of amplitude lost from the first third of the cycles to the last,
  /// clamped at 0. This is the MDS-UPDRS decrementing-amplitude sign, and it is
  /// the single most specific thing measured here.
  final double? amplitudeDecrement;

  /// The same, for per-cycle peak speed.
  final double? speedDecrement;

  /// Speed of the cycle signal in palm-widths per second.
  final double? meanSpeed;
  final double? maxSpeed;

  /// Time from the first frame to the first detected movement.
  final double? initiationDelaySeconds;

  /// Log dimensionless jerk. Higher (less negative) is smoother.
  final double? smoothness;

  /// Inter-cycle gaps far longer than the patient's own median — the
  /// "halts and hesitations" sign.
  final int pauseCount;
  final double pauseSeconds;

  /// Mean cycle amplitude in palm-widths, kept mostly for interpreting
  /// [amplitudeDecrement].
  final double? meanAmplitude;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'taskId': taskId,
        'hand': hand,
        'durationSeconds': durationSeconds,
        'fps': fps,
        'cycleCount': cycleCount,
        'rateHz': rateHz,
        'rhythmVariability': rhythmVariability,
        'amplitudeDecrement': amplitudeDecrement,
        'speedDecrement': speedDecrement,
        'meanSpeed': meanSpeed,
        'maxSpeed': maxSpeed,
        'initiationDelaySeconds': initiationDelaySeconds,
        'smoothness': smoothness,
        'pauseCount': pauseCount,
        'pauseSeconds': pauseSeconds,
        'meanAmplitude': meanAmplitude,
      };
}

/// Reduces a repetitive-movement task to a 1-D signal and measures its cycles.
///
/// Each MDS-UPDRS hand item asks for a different movement, so each gets the
/// signal that actually captures it:
///
/// * item 3.4, finger tapping — thumb-tip to index-tip distance
/// * item 3.5, hand open/close — mean wrist-to-fingertip distance (aperture)
/// * item 3.6, pronation/supination — signed horizontal offset between the
///   index and pinky knuckles, which reverses as the palm turns over
///
/// Every signal is divided by palm size before use. Landmark coordinates are
/// normalized to the frame, so an identical movement produces larger numbers
/// when the hand is nearer the lens; without this step "amplitude decrement"
/// would partly be measuring the patient drifting backwards.
class MovementCycleAnalyzer {
  const MovementCycleAnalyzer();

  /// Cycle boundaries are counted with hysteresis of this fraction of the
  /// signal's range, so sensor noise around the midpoint cannot be mistaken
  /// for movement.
  static const double _hysteresisFraction = 0.15;

  /// Cycles smaller than this fraction of the median cycle are discarded as
  /// jitter rather than counted as very small taps.
  static const double _minRelativeAmplitude = 0.2;

  /// Peak-to-peak signal range below which a task counts as no movement.
  ///
  /// In palm-widths for the distance tasks and half-turns for rotation, so a
  /// fiftieth is about 2% of a palm span or roughly 3.6 degrees of roll — far
  /// below even a severely reduced movement, and above landmark jitter.
  static const double _minimumSignalRange = 0.02;

  /// A gap this many times the patient's own median inter-cycle interval
  /// counts as a hesitation. Relative to their own rhythm, not an absolute
  /// time, so a uniformly slow patient is not charged for pauses they did not
  /// take.
  static const double _pauseFactor = 2.5;

  /// Cycles needed before a decrement estimate is attempted, so each third
  /// holds at least two.
  static const int _minCyclesForDecrement = 6;

  /// Samples in the pre-detection smoothing window. Short enough to leave a
  /// 6 Hz movement intact at 30 fps, long enough to kill single-frame spikes.
  static const int _smoothingWindow = 3;

  /// Measures one task. Rest tasks have no cycles and return empty.
  CycleMetrics analyze(RecordedTask task) {
    if (task.type == CameraTaskType.rest || task.frames.length < 4) {
      return CycleMetrics.empty(taskId: task.taskId, hand: task.hand);
    }

    final signal = cycleSignalFor(task);
    if (signal.length < 4) {
      return CycleMetrics.empty(taskId: task.taskId, hand: task.hand);
    }

    final times = task.frames
        .map((f) => (f.timestamp - task.frames.first.timestamp) / 1000.0)
        .toList(growable: false);
    final double duration = times.last;
    if (duration <= 0) {
      return CycleMetrics.empty(taskId: task.taskId, hand: task.hand);
    }

    final smoothed = _smooth(signal, _smoothingWindow);
    final speeds = _derivative(smoothed, times);
    final cycles = _detectCycles(smoothed, times);

    // Speed statistics span the whole task, cycles or not — a hand that barely
    // moves still has a measurable (very low) speed.
    final absSpeeds = speeds.map((s) => s.abs()).toList(growable: false);
    final double meanSpeed =
        absSpeeds.reduce((a, b) => a + b) / absSpeeds.length;
    final double maxSpeed = absSpeeds.reduce(math.max);

    if (cycles.isEmpty) {
      return CycleMetrics(
        taskId: task.taskId,
        hand: task.hand,
        durationSeconds: duration,
        fps: task.fps,
        cycleCount: 0,
        meanSpeed: meanSpeed,
        maxSpeed: maxSpeed,
        smoothness: _logDimensionlessJerk(speeds, times),
      );
    }

    final intervals = <double>[
      for (int i = 1; i < cycles.length; i++)
        cycles[i].startTime - cycles[i - 1].startTime,
    ];

    return CycleMetrics(
      taskId: task.taskId,
      hand: task.hand,
      durationSeconds: duration,
      fps: task.fps,
      cycleCount: cycles.length,
      rateHz: cycles.length / duration,
      rhythmVariability: _coefficientOfVariation(intervals),
      amplitudeDecrement:
          _decrement(cycles.map((c) => c.amplitude).toList(growable: false)),
      speedDecrement:
          _decrement(cycles.map((c) => c.peakSpeed).toList(growable: false)),
      meanSpeed: meanSpeed,
      maxSpeed: maxSpeed,
      initiationDelaySeconds: cycles.first.startTime,
      smoothness: _logDimensionlessJerk(
        speeds,
        times,
        cycleCount: cycles.length,
      ),
      pauseCount: _pauseCount(intervals),
      pauseSeconds: _pauseSeconds(intervals),
      meanAmplitude: cycles.map((c) => c.amplitude).reduce((a, b) => a + b) /
          cycles.length,
    );
  }

  /// The 1-D movement signal for a task.
  ///
  /// In palm-widths for the two distance-based tasks, and in half-turns for
  /// palm rotation — chosen so the three stay of comparable magnitude, since
  /// the scorer averages speed across them.
  ///
  /// Exposed rather than private so the scale-invariance and cycle shape can be
  /// tested directly.
  List<double> cycleSignalFor(RecordedTask task) {
    if (task.type == CameraTaskType.pronationSupination) {
      return _rotationSignal(task);
    }

    final out = <double>[];
    for (final frame in task.frames) {
      final lm = frame.landmarks;
      if (lm.length < 21) continue;

      // Palm size as the scale reference. It is the most stable span on the
      // hand: unlike finger spans it barely changes with the movement itself,
      // so dividing by it removes distance-to-camera without also removing the
      // signal.
      final double palm = _distance(lm[_Landmark.wrist], lm[_Landmark.middleMcp]);
      if (palm <= 0) continue;

      switch (task.type) {
        case CameraTaskType.fingerTap:
          out.add(
              _distance(lm[_Landmark.thumbTip], lm[_Landmark.indexTip]) / palm);
        case CameraTaskType.openClose:
          final double aperture = (_distance(lm[_Landmark.wrist], lm[_Landmark.indexTip]) +
                  _distance(lm[_Landmark.wrist], lm[_Landmark.middleTip]) +
                  _distance(lm[_Landmark.wrist], lm[_Landmark.ringTip]) +
                  _distance(lm[_Landmark.wrist], lm[_Landmark.pinkyTip])) /
              4;
          out.add(aperture / palm);
        case CameraTaskType.pronationSupination:
        case CameraTaskType.rest:
          break;
      }
    }
    return out;
  }

  /// Forearm roll for MDS-UPDRS item 3.6, in half-turns.
  ///
  /// The palm is a plane, so its orientation is estimated from three of its
  /// landmarks — wrist, index MCP and pinky MCP — rather than from a single
  /// horizontal difference.
  ///
  /// The previous signal was `(indexMcp.x - pinkyMcp.x) / palm`, which has two
  /// faults. It cannot separate the forearm rolling from the whole hand being
  /// rotated in the image plane: tilting the wrist without turning the palm
  /// changes that difference just as much as a real pronation. And because it
  /// is a cosine of the roll angle, it flattens near the extremes of the
  /// movement — exactly where amplitude is read — so the same physical turn
  /// measures differently depending on where the hand started.
  ///
  /// Here the across-palm vector has the forearm direction projected out of it,
  /// which removes the in-plane rotation, and the roll is recovered as an angle
  /// with `atan2`, which is linear in the quantity of interest. The angle is
  /// unwrapped so a turn through the ±pi boundary stays continuous rather than
  /// registering as a huge jump.
  ///
  /// **Known limitation.** MediaPipe's `z` is relative depth, roughly in the
  /// same scale as `x` but not metrically calibrated, and it is the least
  /// reliable of the three coordinates. This is therefore a better-conditioned
  /// estimate of roll, not a true 3-D angle, and the amplitude it reports
  /// should not be read as a physical measurement of degrees turned.
  List<double> _rotationSignal(RecordedTask task) {
    final raw = <double>[];

    for (final frame in task.frames) {
      final lm = frame.landmarks;
      if (lm.length < 21) continue;

      final wrist = lm[_Landmark.wrist];
      final indexMcp = lm[_Landmark.indexMcp];
      final pinkyMcp = lm[_Landmark.pinkyMcp];
      final middleMcp = lm[_Landmark.middleMcp];

      // Forearm direction, from the wrist up through the palm.
      final ax = middleMcp.x - wrist.x;
      final ay = middleMcp.y - wrist.y;
      final az = middleMcp.z - wrist.z;
      final double aLen = math.sqrt(ax * ax + ay * ay + az * az);
      if (aLen <= 0) continue;

      // Across the palm, index knuckle to pinky knuckle.
      final wx = pinkyMcp.x - indexMcp.x;
      final wy = pinkyMcp.y - indexMcp.y;
      final wz = pinkyMcp.z - indexMcp.z;

      // Measure the roll in the plane perpendicular to the forearm, using an
      // orthonormal frame built there.
      //
      // Taking the raw x and z components instead is not enough: an in-plane
      // tilt of the wrist swings part of the across-palm vector into y, and an
      // angle read from x alone then moves even though the palm never turned —
      // which is the very confusion this signal exists to remove.
      //
      // `u` is the camera axis with the forearm direction taken out of it, and
      // `v = a x u` completes the frame.
      final double ux = -az * ax / (aLen * aLen);
      final double uy = -az * ay / (aLen * aLen);
      final double uz = 1 - az * az / (aLen * aLen);
      final double uLen = math.sqrt(ux * ux + uy * uy + uz * uz);

      // Degenerate when the forearm points straight at the lens: there is no
      // well-defined roll to measure, so the frame is skipped rather than
      // assigned an arbitrary angle.
      if (uLen < 1e-9) continue;

      final double nx = ux / uLen;
      final double ny = uy / uLen;
      final double nz = uz / uLen;

      // v = a_hat x u_hat
      final double vx = (ay * nz - az * ny) / aLen;
      final double vy = (az * nx - ax * nz) / aLen;
      final double vz = (ax * ny - ay * nx) / aLen;

      final double along = wx * nx + wy * ny + wz * nz;
      final double across = wx * vx + wy * vy + wz * vz;

      if (along == 0 && across == 0) continue;
      raw.add(math.atan2(along, across));
    }

    if (raw.length < 2) return const <double>[];

    // Depth is what makes the angle meaningful. If the detector reported none —
    // some builds populate z as a constant — every angle collapses onto 0 or
    // pi, and the "rotation" measured would be an artefact of that collapse.
    // Fall back to the older horizontal signal and let it be honestly weaker
    // rather than confidently wrong.
    if (_isDegenerate(raw)) return _horizontalRotationFallback(task);

    // Handedness needs no correction here. A left hand is the mirror of a right
    // one, so the same physical movement yields an angle reflected and offset
    // by pi — and every metric taken from this signal (cycle count, rate,
    // amplitude, rhythm variability, decrement) is invariant to both a constant
    // offset and a reflection. Applying a sign flip would change no number
    // while adding a rule that has to be justified and kept correct, so it is
    // deliberately not applied. This is asserted by a test that measures a
    // mirrored hand and expects identical metrics.

    // Half-turns rather than radians, so rotation amplitude lands in the same
    // range as the palm-width signals the other two tasks produce.
    return _unwrap(raw)
        .map((a) => a / math.pi)
        .toList(growable: false);
  }

  /// True when the angles take essentially only two values, which is what a
  /// missing depth coordinate produces.
  bool _isDegenerate(List<double> angles) {
    for (final angle in angles) {
      final double distanceToAxis =
          math.min((angle.abs() - math.pi).abs(), angle.abs());
      if (distanceToAxis > 1e-6) return false;
    }
    return true;
  }

  /// The pre-existing signal, kept as a fallback for depth-less input.
  List<double> _horizontalRotationFallback(RecordedTask task) {
    final out = <double>[];
    for (final frame in task.frames) {
      final lm = frame.landmarks;
      if (lm.length < 21) continue;
      final double palm =
          _distance(lm[_Landmark.wrist], lm[_Landmark.middleMcp]);
      if (palm <= 0) continue;
      out.add((lm[_Landmark.indexMcp].x - lm[_Landmark.pinkyMcp].x) / palm);
    }
    return out;
  }

  /// Removes the 2*pi jumps `atan2` introduces at the ±pi boundary.
  List<double> _unwrap(List<double> angles) {
    final out = List<double>.filled(angles.length, 0);
    out[0] = angles.first;
    double offset = 0;
    for (int i = 1; i < angles.length; i++) {
      final double delta = angles[i] - angles[i - 1];
      if (delta > math.pi) {
        offset -= 2 * math.pi;
      } else if (delta < -math.pi) {
        offset += 2 * math.pi;
      }
      out[i] = angles[i] + offset;
    }
    return out;
  }

  // --- Signal helpers ---

  double _distance(LandmarkPoint a, LandmarkPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final dz = a.z - b.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  List<double> _smooth(List<double> data, int window) {
    if (window < 3 || data.length < window) return List<double>.of(data);
    final int half = window ~/ 2;
    return List<double>.generate(data.length, (i) {
      final int reach = math.min(half, math.min(i, data.length - 1 - i));
      double sum = 0;
      for (int k = i - reach; k <= i + reach; k++) {
        sum += data[k];
      }
      return sum / (2 * reach + 1);
    }, growable: false);
  }

  /// First derivative against real timestamps, since frames are irregular.
  List<double> _derivative(List<double> data, List<double> times) {
    final out = List<double>.filled(data.length, 0);
    for (int i = 1; i < data.length; i++) {
      final double dt = times[i] - times[i - 1];
      out[i] = dt <= 0 ? 0 : (data[i] - data[i - 1]) / dt;
    }
    if (data.length > 1) out[0] = out[1];
    return out;
  }

  // --- Cycle detection ---

  /// Detects cycles by midline crossings with hysteresis.
  ///
  /// Chosen over peak-picking because it degrades gracefully: a parkinsonian
  /// signal with irregular, shrinking, partly merged peaks still has clean
  /// midline crossings, whereas peak detection starts inventing or dropping
  /// peaks exactly when the movement is most abnormal.
  List<_Cycle> _detectCycles(List<double> signal, List<double> times) {
    final double low = _percentile(signal, 0.05);
    final double high = _percentile(signal, 0.95);
    final double range = high - low;

    // A hand that is not moving still produces a signal, from landmark jitter
    // and from floating-point residue in the geometry. Crossings of a midline
    // drawn through that noise are counted as cycles just as readily as real
    // ones, so a still hand can come back with dozens of "movements" at a
    // plausible-looking rate. Anything below a fiftieth of a palm-width — or of
    // a half-turn, for rotation — is treated as no movement at all.
    if (range <= _minimumSignalRange) return const <_Cycle>[];

    final double centre = (high + low) / 2;
    final double hysteresis = range * _hysteresisFraction;

    // Rising-edge crossings of the midline delimit cycles.
    final crossings = <int>[];
    bool above = signal.first > centre;
    for (int i = 1; i < signal.length; i++) {
      if (!above && signal[i] > centre + hysteresis) {
        above = true;
        crossings.add(i);
      } else if (above && signal[i] < centre - hysteresis) {
        above = false;
      }
    }
    if (crossings.length < 2) return const <_Cycle>[];

    final raw = <_Cycle>[];
    for (int c = 0; c < crossings.length - 1; c++) {
      final int start = crossings[c];
      final int end = crossings[c + 1];

      double minV = signal[start], maxV = signal[start], peakSpeed = 0;
      for (int i = start; i <= end; i++) {
        minV = math.min(minV, signal[i]);
        maxV = math.max(maxV, signal[i]);
        if (i > start) {
          final double dt = times[i] - times[i - 1];
          if (dt > 0) {
            peakSpeed =
                math.max(peakSpeed, (signal[i] - signal[i - 1]).abs() / dt);
          }
        }
      }

      raw.add(_Cycle(
        startTime: times[start],
        amplitude: maxV - minV,
        peakSpeed: peakSpeed,
      ));
    }

    // Drop wobbles far below the patient's own typical cycle.
    final amplitudes = raw.map((c) => c.amplitude).toList()..sort();
    final double median = amplitudes[amplitudes.length ~/ 2];
    if (median <= 0) return raw;
    return raw
        .where((c) => c.amplitude >= median * _minRelativeAmplitude)
        .toList(growable: false);
  }

  // --- Metric helpers ---

  double? _coefficientOfVariation(List<double> values) {
    if (values.length < 2) return null;
    final double mean = values.reduce((a, b) => a + b) / values.length;
    if (mean <= 0) return null;
    final double variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    return math.sqrt(variance) / mean;
  }

  /// Fractional fall from the first third to the last third.
  ///
  /// Clamped at 0: a movement that grows is not a negative decrement, it simply
  /// does not show the sign.
  double? _decrement(List<double> values) {
    if (values.length < _minCyclesForDecrement) return null;
    final int third = values.length ~/ 3;
    if (third < 1) return null;

    final first = values.sublist(0, third);
    final last = values.sublist(values.length - third);
    final double firstMean = first.reduce((a, b) => a + b) / first.length;
    final double lastMean = last.reduce((a, b) => a + b) / last.length;
    if (firstMean <= 0) return null;

    return ((firstMean - lastMean) / firstMean).clamp(0.0, 1.0);
  }

  double _medianOf(List<double> values) {
    final sorted = List<double>.of(values)..sort();
    return sorted[sorted.length ~/ 2];
  }

  int _pauseCount(List<double> intervals) {
    if (intervals.length < 3) return 0;
    final double threshold = _medianOf(intervals) * _pauseFactor;
    return intervals.where((i) => i > threshold).length;
  }

  double _pauseSeconds(List<double> intervals) {
    if (intervals.length < 3) return 0;
    final double median = _medianOf(intervals);
    final double threshold = median * _pauseFactor;
    double total = 0;
    for (final interval in intervals) {
      if (interval > threshold) total += interval - median;
    }
    return total;
  }

  /// Log dimensionless jerk, normalised per movement cycle.
  ///
  ///   LDLJ = -ln( (Tc^3 / vPeak^2) * integral of jerk^2 dt )
  ///
  /// where jerk is the second derivative of the speed profile and `Tc` is the
  /// *mean cycle period*, not the task duration.
  ///
  /// The per-cycle normalisation is a deliberate departure from the textbook
  /// form, which is defined for discrete reaching movements. Applied unchanged
  /// to a sustained rhythmic task, dimensionless jerk grows as (T*f)^4 — it
  /// ends up measuring how many cycles the patient managed, which is already
  /// captured by the rate feature and points the opposite way (a fast healthy
  /// tapper scores as less smooth than a slow impaired one). Normalising by the
  /// cycle period makes T*f approximately 1, cancelling the rate dependence and
  /// leaving the shape of the movement, which is what smoothness should mean
  /// here. Higher (less negative) is smoother.
  double? _logDimensionlessJerk(
    List<double> speeds,
    List<double> times, {
    int cycleCount = 0,
  }) {
    if (speeds.length < 4) return null;

    final double duration = times.last - times.first;
    final double peak = speeds.map((s) => s.abs()).reduce(math.max);
    if (duration <= 0 || peak <= 0) return null;

    // One "movement" is one cycle when the task is rhythmic; fall back to the
    // whole task when no cycles were found.
    final double period = cycleCount > 0 ? duration / cycleCount : duration;

    final accels = _derivative(speeds, times);
    final jerks = _derivative(accels, times);

    double integral = 0;
    for (int i = 1; i < jerks.length; i++) {
      final double dt = times[i] - times[i - 1];
      if (dt <= 0) continue;
      integral += jerks[i] * jerks[i] * dt;
    }
    if (integral <= 0) return null;

    // Integral is over the whole task, so scale it to one cycle's worth before
    // combining with the per-cycle period.
    final double perCycleIntegral =
        cycleCount > 0 ? integral / cycleCount : integral;

    final double dimensionless =
        math.pow(period, 3).toDouble() / (peak * peak) * perCycleIntegral;
    if (dimensionless <= 0) return null;
    return -math.log(dimensionless);
  }

  double _percentile(List<double> data, double fraction) {
    final sorted = List<double>.of(data)..sort();
    final double pos = fraction * (sorted.length - 1);
    final int low = pos.floor();
    final int high = pos.ceil();
    if (low == high) return sorted[low];
    return sorted[low] + (sorted[high] - sorted[low]) * (pos - low);
  }
}

class _Cycle {
  const _Cycle({
    required this.startTime,
    required this.amplitude,
    required this.peakSpeed,
  });

  final double startTime;
  final double amplitude;
  final double peakSpeed;
}
