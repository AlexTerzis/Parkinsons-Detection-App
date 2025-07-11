import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Handles feature extraction and model inference for the voice test.
class VoicePredictor {
  late final Interpreter _interpreter;
  bool _loaded = false;

  /// Loads the TFLite model from assets if it hasn't been loaded yet.
  Future<void> _ensureModel() async {
    if (_loaded) return;
    _interpreter =
        await Interpreter.fromAsset('assets/models/offline_voice.tflite');
    _loaded = true;
  }

  /// Runs inference directly on an audio file and returns the probability
  /// that the recording indicates Parkinson's disease.
  Future<double> predict(File wav) async {
    await _ensureModel();
    final features = await _extractFeatures(wav);
    final input = [features];
    final output = List.filled(1 * 1, 0.0).reshape([1, 1]);
    _interpreter.run(input, output);
    return output[0][0];
  }

  /// Extracts a simplified set of voice features from the WAV bytes.
  /// The implementation is intentionally lightweight and only approximates the
  /// classic jitter/shimmer metrics used in clinical studies.
  Future<List<double>> _extractFeatures(File wav) async {
    final bytes = await wav.readAsBytes();
    // Skip the 44 byte WAV header and treat the rest as 16‑bit PCM samples.
    final samples = bytes.buffer
        .asInt16List(44)
        .map((e) => e.toDouble())
        .toList();

    if (samples.isEmpty) {
      return List.filled(16, 0);
    }

    // Estimate the sample rate from header bytes 24‑27.
    final rate = bytes.buffer.asByteData().getUint32(24, Endian.little);

    // --- Frequency domain analysis ---
    final fft = FFT(samples.length);
    final freqs = fft.realFft(samples);
    final magnitudes = List<double>.generate(
        freqs.length ~/ 2, (i) {
          final abs = freqs[i].abs();
          return abs.x + abs.y; // Sum both lanes as a simple magnitude approximation
        });

    // Basic pitch estimation using the strongest frequency component.
    int maxIndex = 0;
    for (int i = 1; i < magnitudes.length; i++) {
      if (magnitudes[i] > magnitudes[maxIndex]) maxIndex = i;
    }
    final fo = maxIndex * rate / samples.length;

    // Highest and lowest detected frequencies.
    final fhi = (magnitudes.lastIndexWhere((m) => m > 0.01)) * rate / samples.length;
    final flo = (magnitudes.indexWhere((m) => m > 0.01)) * rate / samples.length;

    // --- Time domain analysis for jitter/shimmer approximations ---
    final zeroCrossings = <int>[];
    for (int i = 1; i < samples.length; i++) {
      if ((samples[i - 1] <= 0 && samples[i] > 0) ||
          (samples[i - 1] >= 0 && samples[i] < 0)) {
        zeroCrossings.add(i);
      }
    }
    final periods = <double>[];
    for (int i = 1; i < zeroCrossings.length; i++) {
      final diff = zeroCrossings[i] - zeroCrossings[i - 1];
      periods.add(diff / rate);
    }

    final avgPeriod =
        periods.isNotEmpty ? periods.reduce((a, b) => a + b) / periods.length : 0.0;
    final jitterAbs = periods.isNotEmpty
        ? periods
                .map((p) => (p - avgPeriod).abs())
                .reduce((a, b) => a + b) /
            periods.length
        : 0.0;
    final jitterPct = avgPeriod > 0 ? jitterAbs / avgPeriod : 0.0;

    // RAP and PPQ approximated using moving averages of period differences.
    double _rap() {
      if (periods.length < 3) return 0.0;
      double sum = 0;
      for (int i = 1; i < periods.length - 1; i++) {
        final localAvg = (periods[i - 1] + periods[i] + periods[i + 1]) / 3;
        sum += (periods[i] - localAvg).abs();
      }
      return sum / (periods.length - 2) / avgPeriod;
    }

    double _ppq() {
      if (periods.length < 5) return 0.0;
      double sum = 0;
      for (int i = 2; i < periods.length - 2; i++) {
        final localAvg = (periods[i - 2] + periods[i - 1] + periods[i] + periods[i + 1] + periods[i + 2]) / 5;
        sum += (periods[i] - localAvg).abs();
      }
      return sum / (periods.length - 4) / avgPeriod;
    }

    final rap = _rap();
    final ppq = _ppq();
    final ddp = 3 * rap;

    // Shimmer estimated from amplitude variations.
    final amplitudes = samples.map((e) => e.abs().toDouble()).toList();
    final ampMean = amplitudes.reduce((a, b) => a + b) / amplitudes.length;
    final shimmer = amplitudes
            .map((a) => (a - ampMean).abs())
            .reduce((a, b) => a + b) /
        amplitudes.length /
        ampMean;
    final shimmerDb = 20 * log(shimmer + 1e-6) / ln10;
    final apq3 = shimmer; // very rough approximation
    final apq5 = shimmer; // reuse shimmer for simplicity
    final apq = shimmer;
    final dda = 3 * apq3;

    // Noise-to-harmonics estimated from spectral flatness.
    final totalEnergy = magnitudes.reduce((a, b) => a + b);
    final harmonicEnergy = magnitudes[maxIndex];
    final nhr =
        harmonicEnergy > 0 ? (totalEnergy - harmonicEnergy) / harmonicEnergy : 0.0;
    final hnr = nhr > 0 ? 1 / nhr : 0.0;

    return [
      fo,
      fhi,
      flo,
      jitterPct,
      jitterAbs,
      rap,
      ppq,
      ddp,
      shimmer,
      shimmerDb,
      apq3,
      apq5,
      apq,
      dda,
      nhr,
      hnr,
    ];
  }
}