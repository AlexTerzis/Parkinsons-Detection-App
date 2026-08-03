import 'dart:math' as math;

import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';

import '../models/landmark_point.dart';

/// A landmark position together with the moment it was observed.
///
/// Timestamps are required rather than assumed, because camera frames do not
/// arrive on a regular schedule and every step below depends on knowing the
/// real interval between samples.
class TimedLandmark {
  const TimedLandmark({required this.timestampMs, required this.point});

  final int timestampMs;
  final LandmarkPoint point;
}

/// Why a dominant frequency could not be reported.
enum TremorFrequencyRejection {
  /// Fewer samples than the analysis needs.
  insufficientSamples,

  /// The measured capture rate was at or below
  /// [TremorAnalysisService.minimumFrequencyFps].
  sampleRateTooLow,

  /// The residual carried no meaningful energy, so any "peak" would be noise.
  noTremorEnergy,
}

/// The outcome of separating tremor from voluntary movement in one trajectory.
class TremorAnalysis {
  const TremorAnalysis({
    required this.rms,
    required this.amplitude,
    required this.consistency,
    required this.sampleRateHz,
    required this.sampleCount,
    this.dominantFrequencyHz,
    this.frequencyRejection,
    this.frequencyRejectionReason,
  });

  /// A result for a trajectory too short to say anything about.
  factory TremorAnalysis.empty({
    double sampleRateHz = 0,
    int sampleCount = 0,
    String reason = 'Not enough samples to analyse tremor.',
  }) {
    return TremorAnalysis(
      rms: 0,
      amplitude: 0,
      consistency: 0,
      sampleRateHz: sampleRateHz,
      sampleCount: sampleCount,
      frequencyRejection: TremorFrequencyRejection.insufficientSamples,
      frequencyRejectionReason: reason,
    );
  }

  /// Root-mean-square magnitude of the tremor residual, in normalized
  /// landmark units. This is the headline "how much tremor" number.
  final double rms;

  /// Half the robust peak-to-peak span of the residual, in normalized landmark
  /// units — roughly the amplitude of the oscillation, measured from the 5th
  /// to the 95th percentile so a single bad frame cannot inflate it.
  final double amplitude;

  /// How steady the tremor is across the recording, 0-1.
  ///
  /// One minus the coefficient of variation of the per-window RMS. A sustained
  /// tremor scores near 1; a single jerk in an otherwise still hand scores near
  /// 0. This is what separates a tremor from a flinch.
  final double consistency;

  /// The capture rate actually measured from the timestamps, not a nominal one.
  final double sampleRateHz;

  /// Number of source frames the analysis was built from.
  final int sampleCount;

  /// Peak frequency of the residual in Hz, or `null` when it could not be
  /// measured reliably — see [frequencyRejection].
  final double? dominantFrequencyHz;

  final TremorFrequencyRejection? frequencyRejection;

  /// Human-readable form of [frequencyRejection], for logs and for showing a
  /// reviewer why the field is empty.
  final String? frequencyRejectionReason;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tremor_rms': rms,
        'tremor_amplitude': amplitude,
        'tremor_consistency': consistency,
        'sample_rate_hz': sampleRateHz,
        'sample_count': sampleCount,
        'dominant_frequency_hz': dominantFrequencyHz,
        'frequency_rejection': frequencyRejection?.name,
        'frequency_rejection_reason': frequencyRejectionReason,
      };
}

/// Separates involuntary tremor from voluntary movement in hand trajectories.
///
/// The existing `HandMetrics.tremorAll` measures the standard deviation of raw
/// landmark position, which cannot tell the two apart: during an open/close
/// task (MDS-UPDRS item 3.5) the movement *is* the signal, so a healthy person
/// moving vigorously scores as severe tremor. That method is retained for
/// compatibility with stored results; this service is the corrected analysis.
///
/// The approach is the standard one for tremor work: treat voluntary movement
/// as the low-frequency component, estimate it with a low-pass filter, and take
/// tremor to be what is left over.
///
///   residual(t) = raw(t) - smoothed(t)
///
/// Voluntary hand movement in these tasks sits below roughly 2-3 Hz even when
/// performed "as fast as possible", while parkinsonian tremor is typically
/// 4-6 Hz at rest and up to about 12 Hz for action tremor.
///
/// The pipeline is: resample to a uniform grid, low-pass, subtract, then
/// measure. Resampling comes first because both the filter and the FFT assume
/// evenly spaced samples, and camera frames are not.
class TremorAnalysisService {
  const TremorAnalysisService();

  /// Low-pass cutoff separating voluntary movement from tremor.
  ///
  /// Sits above the ~2-3 Hz ceiling of voluntary movement and below the 4-6 Hz
  /// parkinsonian tremor band. Clamped against the sample rate in
  /// [_effectiveCutoff] so it can never approach Nyquist.
  static const double lowPassCutoffHz = 4.0;

  /// Order of each low-pass pass. Applied forward and backward, so the
  /// effective response is 8th order and zero-phase.
  ///
  /// A plain moving average was tried first and is not sharp enough here: at a
  /// window that preserves 5 Hz tremor it still leaks about a quarter of a 2 Hz
  /// voluntary movement into the residual, which is enough for vigorous
  /// open/close to outscore real tremor. Butterworth's steeper rolloff is what
  /// makes the separation hold.
  static const int _butterworthOrder = 4;

  /// Frequency estimation is refused at or below this capture rate.
  ///
  /// Nyquist at 15 fps is 7.5 Hz. That is only just above the 4-6 Hz band of
  /// interest, leaving no headroom: any real tremor above 7.5 Hz aliases down
  /// into that band and is indistinguishable from a genuine parkinsonian
  /// frequency. A wrong number here is worse than no number, so below this the
  /// service reports `null` and says why.
  static const double minimumFrequencyFps = 15.0;

  /// Peaks below this are voluntary movement leaking through the filter, not
  /// tremor, so they are excluded from the frequency search.
  static const double minimumTremorHz = 1.5;

  /// Highest frequency considered plausible for hand tremor.
  static const double maximumTremorHz = 14.0;

  /// Minimum resampled points before an FFT is attempted.
  static const int minimumFftSamples = 32;

  /// Minimum source frames before anything is attempted.
  static const int _minimumSamples = 8;

  /// Residual RMS below this is treated as no tremor at all rather than as a
  /// signal whose peak is worth reporting.
  ///
  /// Landmark coordinates are normalised to the frame, so this is 0.01% of the
  /// frame width — well under a pixel on any real camera, and below the
  /// landmark detector's own jitter. It also sits comfortably above the small
  /// residue the filter leaves on a pure drift, so a hand that is merely moving
  /// steadily reports no tremor rather than a frequency derived from rounding
  /// error.
  static const double _noiseFloor = 1e-4;

  /// Analyses one landmark's trajectory over time.
  TremorAnalysis analyzeLandmark(List<TimedLandmark> samples) {
    final ordered = _sortedByTime(samples);
    if (ordered.length < _minimumSamples) {
      return TremorAnalysis.empty(sampleCount: ordered.length);
    }

    final double fps = _measureSampleRate(ordered);
    final residual = _residualOf(ordered, fps);
    if (residual == null) {
      return TremorAnalysis.empty(
        sampleRateHz: fps,
        sampleCount: ordered.length,
      );
    }

    return _analysisFrom(
      residual: residual,
      spectrum: _spectrumOf(residual, fps),
      fps: fps,
      sampleCount: ordered.length,
    );
  }

  /// Analyses a whole hand: one entry per landmark, each a trajectory.
  ///
  /// Time-domain metrics are averaged across landmarks. The frequency, though,
  /// comes from summing the landmarks' spectra and taking a single peak — the
  /// whole hand shakes together, so pooling the energy finds the shared
  /// frequency far more reliably than averaging 21 separately noisy estimates.
  TremorAnalysis analyzeHand(List<List<TimedLandmark>> perLandmark) {
    final residuals = <_Residual>[];
    final rates = <double>[];
    int totalSamples = 0;

    for (final trajectory in perLandmark) {
      final ordered = _sortedByTime(trajectory);
      if (ordered.length < _minimumSamples) continue;

      final double fps = _measureSampleRate(ordered);
      final residual = _residualOf(ordered, fps);
      if (residual == null) continue;

      residuals.add(residual);
      rates.add(fps);
      totalSamples += ordered.length;
    }

    if (residuals.isEmpty) return TremorAnalysis.empty();

    final double fps = rates.reduce((a, b) => a + b) / rates.length;

    // Pool the spectra, then peak-pick once. Landmarks whose grids came out a
    // different length are still counted in the time-domain averages; only
    // their spectra are skipped, since they cannot be summed bin for bin.
    List<double>? pooled;
    double? binHz;
    for (final residual in residuals) {
      final spectrum = _spectrumOf(residual, fps);
      if (spectrum == null) continue;
      if (pooled == null) {
        pooled = List<double>.of(spectrum.magnitudes);
        binHz = spectrum.binHz;
        continue;
      }
      if (spectrum.magnitudes.length != pooled.length) continue;
      for (int i = 0; i < pooled.length; i++) {
        pooled[i] += spectrum.magnitudes[i];
      }
    }

    double rms = 0, amplitude = 0, consistency = 0;
    for (final residual in residuals) {
      rms += _rmsOf(residual);
      amplitude += _amplitudeOf(residual);
      consistency += _consistencyOf(residual);
    }
    final int n = residuals.length;

    return _analysisFrom(
      residual: residuals.first,
      spectrum: pooled == null
          ? null
          : _Spectrum(magnitudes: pooled, binHz: binHz!),
      fps: fps,
      sampleCount: totalSamples,
      rmsOverride: rms / n,
      amplitudeOverride: amplitude / n,
      consistencyOverride: consistency / n,
    );
  }

  // --- Assembly ---

  TremorAnalysis _analysisFrom({
    required _Residual residual,
    required _Spectrum? spectrum,
    required double fps,
    required int sampleCount,
    double? rmsOverride,
    double? amplitudeOverride,
    double? consistencyOverride,
  }) {
    final double rms = rmsOverride ?? _rmsOf(residual);

    TremorFrequencyRejection? rejection;
    String? reason;
    double? frequency;

    if (fps <= minimumFrequencyFps) {
      rejection = TremorFrequencyRejection.sampleRateTooLow;
      reason = 'Measured capture rate ${fps.toStringAsFixed(1)} fps is at or '
          'below the ${minimumFrequencyFps.toStringAsFixed(0)} fps needed for a '
          'reliable frequency estimate; frequencies above Nyquist '
          '(${(fps / 2).toStringAsFixed(1)} Hz) would alias into the tremor '
          'band and be reported as a plausible-looking but wrong number.';
    } else if (rms < _noiseFloor) {
      rejection = TremorFrequencyRejection.noTremorEnergy;
      reason = 'Residual energy is below the noise floor; no tremor to measure.';
    } else if (spectrum == null) {
      rejection = TremorFrequencyRejection.insufficientSamples;
      reason = 'Fewer than $minimumFftSamples resampled points were available '
          'for the FFT.';
    } else {
      frequency = _peakFrequency(spectrum);
      if (frequency == null) {
        rejection = TremorFrequencyRejection.noTremorEnergy;
        reason = 'No spectral peak between ${minimumTremorHz}Hz and '
            '${maximumTremorHz}Hz.';
      }
    }

    if (reason != null) {
      debugPrint('TremorAnalysisService: no dominant frequency — $reason');
    }

    return TremorAnalysis(
      rms: rms,
      amplitude: amplitudeOverride ?? _amplitudeOf(residual),
      consistency: consistencyOverride ?? _consistencyOf(residual),
      sampleRateHz: fps,
      sampleCount: sampleCount,
      dominantFrequencyHz: frequency,
      frequencyRejection: rejection,
      frequencyRejectionReason: reason,
    );
  }

  // --- Preparation ---

  List<TimedLandmark> _sortedByTime(List<TimedLandmark> samples) {
    return List<TimedLandmark>.of(samples)
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
  }

  /// Effective capture rate from first and last timestamp.
  double _measureSampleRate(List<TimedLandmark> ordered) {
    if (ordered.length < 2) return 0;
    final int spanMs = ordered.last.timestampMs - ordered.first.timestampMs;
    if (spanMs <= 0) return 0;
    return (ordered.length - 1) * 1000 / spanMs;
  }

  /// Cutoff actually used, held well clear of Nyquist so the filter stays
  /// meaningful when frames are scarce.
  double _effectiveCutoff(double fps) =>
      math.min(lowPassCutoffHz, fps / 5);

  /// Resamples to a uniform grid, low-passes it, and returns raw minus
  /// smoothed on that same grid.
  _Residual? _residualOf(List<TimedLandmark> ordered, double fps) {
    if (fps <= 0) return null;

    final int spanMs = ordered.last.timestampMs - ordered.first.timestampMs;
    if (spanMs <= 0) return null;

    final double stepMs = 1000 / fps;
    final int count = (spanMs / stepMs).floor() + 1;
    if (count < _minimumSamples) return null;

    final timestamps =
        ordered.map((s) => s.timestampMs).toList(growable: false);
    final double cutoff = _effectiveCutoff(fps);

    List<double> axis(double Function(LandmarkPoint) pick) {
      final uniform = _resample(
        timestamps,
        ordered.map((s) => pick(s.point)).toList(growable: false),
        stepMs,
        count,
      );
      return _subtract(uniform, _lowPass(uniform, fps, cutoff));
    }

    return _Residual(
      startMs: ordered.first.timestampMs,
      stepMs: stepMs,
      x: axis((p) => p.x),
      y: axis((p) => p.y),
      z: axis((p) => p.z),
    );
  }

  /// Linear interpolation onto a uniform grid.
  List<double> _resample(
    List<int> timestampsMs,
    List<double> values,
    double stepMs,
    int count,
  ) {
    final out = List<double>.filled(count, 0);
    final int t0 = timestampsMs.first;
    int cursor = 0;

    for (int k = 0; k < count; k++) {
      final double t = t0 + k * stepMs;

      while (cursor < timestampsMs.length - 2 &&
          timestampsMs[cursor + 1] < t) {
        cursor++;
      }

      final int ta = timestampsMs[cursor];
      final int tb = timestampsMs[cursor + 1];
      if (tb == ta) {
        out[k] = values[cursor];
        continue;
      }
      final double f = ((t - ta) / (tb - ta)).clamp(0.0, 1.0);
      out[k] = values[cursor] + (values[cursor + 1] - values[cursor]) * f;
    }
    return out;
  }

  List<double> _subtract(List<double> a, List<double> b) =>
      List<double>.generate(a.length, (i) => a[i] - b[i], growable: false);

  // --- Filtering ---

  /// Zero-phase Butterworth low-pass.
  ///
  /// Runs the cascade forward and then backward. The reverse pass cancels the
  /// phase shift of the forward one, which matters more than usual here: any
  /// lag in the smoothed estimate would show up in `raw - smoothed` as
  /// oscillation that is not there.
  ///
  /// The signal is extended at both ends by odd (point) reflection before
  /// filtering. Odd extension continues a straight line straight, so a steady
  /// drift stays in the smoothed estimate and is removed by the subtraction,
  /// rather than producing an edge transient the metrics would read as tremor.
  List<double> _lowPass(List<double> data, double fps, double cutoffHz) {
    if (data.length < 4 || cutoffHz <= 0 || cutoffHz >= fps / 2) {
      return List<double>.of(data);
    }

    final sections = _butterworthSections(fps, cutoffHz);
    final int pad = math.min(data.length - 1, 3 * _butterworthOrder * 2);

    final padded = <double>[
      for (int i = pad; i >= 1; i--) 2 * data.first - data[i],
      ...data,
      for (int i = 1; i <= pad; i++) 2 * data.last - data[data.length - 1 - i],
    ];

    var pass = padded;
    for (final section in sections) {
      pass = _applyBiquad(pass, section);
    }
    pass = pass.reversed.toList();
    for (final section in sections) {
      pass = _applyBiquad(pass, section);
    }
    pass = pass.reversed.toList();

    return pass.sublist(pad, pad + data.length);
  }

  /// Butterworth low-pass as cascaded biquads, via the bilinear transform.
  ///
  /// The pole Q values are the standard Butterworth ones for the order, which
  /// is what makes the cascade maximally flat in the passband instead of
  /// rippling.
  List<_Biquad> _butterworthSections(double fps, double cutoffHz) {
    const int pairs = _butterworthOrder ~/ 2;
    final double w0 = 2 * math.pi * cutoffHz / fps;
    final double cosW0 = math.cos(w0);
    final double sinW0 = math.sin(w0);

    return List<_Biquad>.generate(pairs, (k) {
      final double theta = math.pi * (2 * k + 1) / (2 * _butterworthOrder);
      final double q = 1 / (2 * math.sin(theta));
      final double alpha = sinW0 / (2 * q);

      final double a0 = 1 + alpha;
      return _Biquad(
        b0: ((1 - cosW0) / 2) / a0,
        b1: (1 - cosW0) / a0,
        b2: ((1 - cosW0) / 2) / a0,
        a1: (-2 * cosW0) / a0,
        a2: (1 - alpha) / a0,
      );
    });
  }

  /// Direct-form-I biquad, with the delay line primed to the first sample.
  ///
  /// Priming rather than starting from zero avoids a step transient at the
  /// start of every trajectory: landmark coordinates sit around 0.5, not 0, so
  /// zero-initialised state would make the filter ring on the very first
  /// samples.
  List<double> _applyBiquad(List<double> x, _Biquad c) {
    final out = List<double>.filled(x.length, 0);
    double x1 = x.first, x2 = x.first, y1 = x.first, y2 = x.first;

    for (int i = 0; i < x.length; i++) {
      final double xn = x[i];
      final double yn =
          c.b0 * xn + c.b1 * x1 + c.b2 * x2 - c.a1 * y1 - c.a2 * y2;
      x2 = x1;
      x1 = xn;
      y2 = y1;
      y1 = yn;
      out[i] = yn;
    }
    return out;
  }

  // --- Time-domain metrics ---

  double _magnitudeAt(_Residual r, int i) =>
      math.sqrt(r.x[i] * r.x[i] + r.y[i] * r.y[i] + r.z[i] * r.z[i]);

  double _rmsOf(_Residual r) {
    if (r.length == 0) return 0;
    double sum = 0;
    for (int i = 0; i < r.length; i++) {
      sum += r.x[i] * r.x[i] + r.y[i] * r.y[i] + r.z[i] * r.z[i];
    }
    return math.sqrt(sum / r.length);
  }

  /// Half the 5th-to-95th percentile span, combined across axes.
  double _amplitudeOf(_Residual r) {
    if (r.length == 0) return 0;
    double squared = 0;
    for (final axis in <List<double>>[r.x, r.y, r.z]) {
      final span = _percentile(axis, 0.95) - _percentile(axis, 0.05);
      squared += span * span;
    }
    return 0.5 * math.sqrt(squared);
  }

  double _percentile(List<double> data, double fraction) {
    if (data.isEmpty) return 0;
    final sorted = List<double>.of(data)..sort();
    final double pos = fraction * (sorted.length - 1);
    final int low = pos.floor();
    final int high = pos.ceil();
    if (low == high) return sorted[low];
    return sorted[low] + (sorted[high] - sorted[low]) * (pos - low);
  }

  /// One minus the coefficient of variation of per-window RMS, clamped to 0-1.
  double _consistencyOf(_Residual r) {
    if (r.length < 8) return 0;

    final int windows = math.max(2, math.min(8, r.length ~/ 8));
    final int per = r.length ~/ windows;
    if (per < 2) return 0;

    final energies = <double>[];
    for (int w = 0; w < windows; w++) {
      final int start = w * per;
      final int end = w == windows - 1 ? r.length : start + per;
      double sum = 0;
      for (int i = start; i < end; i++) {
        final m = _magnitudeAt(r, i);
        sum += m * m;
      }
      energies.add(math.sqrt(sum / (end - start)));
    }

    final double mean = energies.reduce((a, b) => a + b) / energies.length;
    if (mean <= _noiseFloor) return 0;

    final double variance =
        energies.map((e) => (e - mean) * (e - mean)).reduce((a, b) => a + b) /
            energies.length;
    return (1 - math.sqrt(variance) / mean).clamp(0.0, 1.0);
  }

  // --- Frequency domain ---

  /// Spectrum of the residual, summed across the three axes.
  ///
  /// The residual is already on a uniform grid by this point, which is what
  /// makes the FFT valid — run on raw frame data, irregular intervals smear the
  /// spectrum and shift the peak.
  _Spectrum? _spectrumOf(_Residual r, double fps) {
    if (fps <= 0 || r.length < minimumFftSamples) return null;

    final int count = r.length;
    final int padded = _nextPowerOfTwo(count);
    List<double>? summed;

    for (final axis in <List<double>>[r.x, r.y, r.z]) {
      final input = Float64List(padded);
      // Hann window over the real samples; the zero padding stays zero, which
      // interpolates the spectrum without inventing resolution.
      for (int i = 0; i < count; i++) {
        final double w = 0.5 * (1 - math.cos(2 * math.pi * i / (count - 1)));
        input[i] = axis[i] * w;
      }

      final magnitudes =
          FFT(padded).realFft(input).discardConjugates().magnitudes();

      if (summed == null) {
        summed = List<double>.of(magnitudes);
      } else {
        for (int i = 0; i < summed.length && i < magnitudes.length; i++) {
          summed[i] += magnitudes[i];
        }
      }
    }

    if (summed == null) return null;
    return _Spectrum(magnitudes: summed, binHz: fps / padded);
  }

  /// Largest peak within the plausible tremor band, refined by parabolic
  /// interpolation so the answer is not quantised to the bin width.
  double? _peakFrequency(_Spectrum spectrum) {
    final mags = spectrum.magnitudes;
    final int lowBin = math.max(1, (minimumTremorHz / spectrum.binHz).ceil());
    final int highBin =
        math.min(mags.length - 1, (maximumTremorHz / spectrum.binHz).floor());
    if (lowBin >= highBin) return null;

    int peak = -1;
    double best = 0;
    for (int i = lowBin; i <= highBin; i++) {
      if (mags[i] > best) {
        best = mags[i];
        peak = i;
      }
    }
    if (peak < 1 || best <= 0) return null;

    double offset = 0;
    if (peak < mags.length - 1) {
      final double a = mags[peak - 1];
      final double b = mags[peak];
      final double c = mags[peak + 1];
      final double denom = a - 2 * b + c;
      if (denom != 0) {
        offset = (0.5 * (a - c) / denom).clamp(-0.5, 0.5);
      }
    }
    return (peak + offset) * spectrum.binHz;
  }

  int _nextPowerOfTwo(int n) {
    int p = 1;
    while (p < n) {
      p <<= 1;
    }
    return p;
  }
}

/// Raw-minus-smoothed signal on a uniform time grid.
class _Residual {
  _Residual({
    required this.startMs,
    required this.stepMs,
    required this.x,
    required this.y,
    required this.z,
  });

  final int startMs;
  final double stepMs;
  final List<double> x;
  final List<double> y;
  final List<double> z;

  int get length => x.length;
}

class _Spectrum {
  _Spectrum({required this.magnitudes, required this.binHz});

  final List<double> magnitudes;

  /// Hz per bin.
  final double binHz;
}

/// Second-order IIR section, coefficients already normalised by a0.
class _Biquad {
  const _Biquad({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.a1,
    required this.a2,
  });

  final double b0;
  final double b1;
  final double b2;
  final double a1;
  final double a2;
}
