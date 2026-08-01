import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fftea/fftea.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Handles feature extraction and model inference for the voice test.
class VoicePredictor {
  late final Interpreter _interpreter;
  bool _loaded = false;
  List<double>? _means;
  List<double>? _stds;

  /// Loads the TFLite model and normalization parameters from assets.
  Future<void> _ensureModel() async {
    if (_loaded) return;
    _interpreter = await Interpreter.fromAsset('assets/models/kalo.tflite');
    final normJson = await rootBundle.loadString('assets/models/voice_norm.json');
    final data = json.decode(normJson) as Map<String, dynamic>;
    _means = List<double>.from(data['means']);
    _stds = List<double>.from(data['stds']);
    _loaded = true;
  }

  /// Runs inference directly on an audio file and returns the probability
  /// that the recording indicates Parkinson's disease.
  Future<double> predict(File wav) async {
    await _ensureModel();

    final rawFeatures = await _extractFeatures(wav);
    debugPrint('🧠 Extracted features: $rawFeatures');

    final features = _normalizeFeatures(rawFeatures);
    debugPrint('🧪 Normalized features: $features');

    // 🧪 Debugging logs
    debugPrint('🧠 Extracted features: $rawFeatures');
    debugPrint('🧪 Normalized features: $features');
    debugPrint('🔢 Feature count: ${features.length}');
    debugPrint('✅ All finite: ${features.every((v) => v.isFinite)}');

    final input = Float32List.fromList(features).reshape([1, 16]);
    final output = Float32List(1).reshape([1, 1]);
    debugPrint('📤 Final input to model: ${input[0]}');
    _interpreter.run(input, output);

    debugPrint('📈 Raw model output: ${output[0][0]}');
    return output[0][0];
  }

  /// Normalizes features using the same means and stds used in training.
  List<double> _normalizeFeatures(List<double> features) {
    if (_means == null || _stds == null) {
      throw StateError('Normalization parameters not loaded');
    }
    final normalized = <double>[];
    for (var i = 0; i < features.length; i++) {
      final std = _stds![i];
      final mean = _means![i];
      normalized.add(std != 0 ? (features[i] - mean) / std : 0.0);
    }
    return normalized;
  }

  Future<List<double>> _extractFeatures(File wav) async {
  final bytes = await wav.readAsBytes();
  if (bytes.length <= 44) return List.filled(16, 0.0);

  final samples = bytes.buffer.asInt16List(44).map((e) => e.toDouble()).toList();
  if (samples.isEmpty) return List.filled(16, 0.0);

  final rate = bytes.buffer.asByteData().getUint32(24, Endian.little);

  // --- Frequency features ---
  int zeroCrossings = 0;
  for (int i = 1; i < samples.length; i++) {
    if ((samples[i - 1] < 0 && samples[i] >= 0) ||
        (samples[i - 1] > 0 && samples[i] <= 0)) {
      zeroCrossings++;
    }
  }
  final durationSeconds = samples.length / rate;
  final fo = (zeroCrossings / 2) / durationSeconds; // MDVP:Fo(Hz)

  // Fhi and Flo from periods between zero crossings (in Hz)
  final zcIndices = <int>[];
for (int i = 1; i < samples.length; i++) {
  // Only positive-slope zero crossings
  if (samples[i - 1] < 0 && samples[i] >= 0) {
    zcIndices.add(i);
  }
}
final periods = <double>[];
for (int i = 1; i < zcIndices.length; i++) {
  periods.add((zcIndices[i] - zcIndices[i - 1]) / rate);
}
// Ignore crazy-small periods (due to noise)
final filteredPeriods = periods.where((p) => p > 0.001).toList();
final frequencies = filteredPeriods.map((p) => 1.0 / p).toList();
final fhi = frequencies.isNotEmpty ? frequencies.reduce(max) : 0.0;
final flo = frequencies.isNotEmpty ? frequencies.reduce(min) : 0.0;



  // --- Jitter features ---
  final avgPeriod = periods.isNotEmpty
      ? periods.reduce((a, b) => a + b) / periods.length
      : 0.0;
  final jitterAbsRaw = periods.isNotEmpty
      ? periods.map((p) => (p - avgPeriod).abs()).reduce((a, b) => a + b) / periods.length
      : 0.0;
  final jitterAbs = jitterAbsRaw; // Already in ~1e-4 range
  final jitterPct = avgPeriod > 0 ? (jitterAbsRaw / avgPeriod) : 0.0; // **No ×100**; Python is ratio, not percent

  double rap0() {
    if (periods.length < 3) return 0.0;
    double sum = 0;
    for (int i = 1; i < periods.length - 1; i++) {
      final localAvg = (periods[i - 1] + periods[i] + periods[i + 1]) / 3;
      sum += (periods[i] - localAvg).abs();
    }
    return avgPeriod > 0 ? sum / (periods.length - 2) / avgPeriod : 0.0;
  }

  double ppq0() {
    if (periods.length < 5) return 0.0;
    double sum = 0;
    for (int i = 2; i < periods.length - 2; i++) {
      final localAvg = (periods[i - 2] + periods[i - 1] + periods[i] + periods[i + 1] + periods[i + 2]) / 5;
      sum += (periods[i] - localAvg).abs();
    }
    return avgPeriod > 0 ? sum / (periods.length - 4) / avgPeriod : 0.0;
  }

  final rap = rap0();  // Should be tiny (< 0.01)
  final ppq = ppq0();  // Should be tiny (< 0.01)
  final ddp = 3 * rap; // Should be tiny (< 0.04)

  // --- Shimmer features ---
  final amplitudes = samples.map((e) => e.abs().toDouble()).toList();
  final ampMean = amplitudes.reduce((a, b) => a + b) / amplitudes.length;
  final shimmerRaw = amplitudes
          .map((a) => (a - ampMean).abs())
          .reduce((a, b) => a + b) / amplitudes.length / ampMean;
  final shimmer = shimmerRaw; // Should be ~0.02–0.05
  final shimmerDb = 20 * log(shimmerRaw + 1e-6) / ln10; // Should be ~0.02–0.07

  final apq3 = shimmerRaw; // Approximated, matches Python order
  final apq5 = shimmerRaw;
  final apq = shimmerRaw;
  final dda = 3 * apq3;

  // --- Noise to Harmonics Ratio ---
  final fft = FFT(samples.length);
  final freqs = fft.realFft(samples);
  final magnitudes = List<double>.generate(freqs.length ~/ 2, (i) {
    final abs = freqs[i].abs();
    return abs.x + abs.y;
  });
  final totalEnergy = magnitudes.fold(0.0, (a, b) => a + b);
  final maxIndex = magnitudes.indexWhere((m) => m == magnitudes.reduce(max));
  final harmonicEnergy = (maxIndex >= 0 && maxIndex < magnitudes.length)
      ? magnitudes[maxIndex]
      : 1.0;
  final nhr = harmonicEnergy > 0 ? (totalEnergy - harmonicEnergy) / harmonicEnergy : 0.0;
  final hnr = nhr > 0 ? 1 / nhr : 0.0;

  // Debug: Print all features
  debugPrint('🧠 Extracted features: [$fo, $fhi, $flo, $jitterPct, $jitterAbs, $rap, $ppq, $ddp, $shimmer, $shimmerDb, $apq3, $apq5, $apq, $dda, $nhr, $hnr]');

  return [
    fo,         // MDVP:Fo(Hz)
    fhi,        // MDVP:Fhi(Hz)
    flo,        // MDVP:Flo(Hz)
    jitterPct,  // MDVP:Jitter(%) [actually in ratio!]
    jitterAbs,  // MDVP:Jitter(Abs)
    rap,        // MDVP:RAP
    ppq,        // MDVP:PPQ
    ddp,        // Jitter:DDP
    shimmer,    // MDVP:Shimmer
    shimmerDb,  // MDVP:Shimmer(dB)
    apq3,       // Shimmer:APQ3
    apq5,       // Shimmer:APQ5
    apq,        // MDVP:APQ
    dda,        // Shimmer:DDA
    nhr,        // NHR
    hnr,        // HNR
  ];
}


}
