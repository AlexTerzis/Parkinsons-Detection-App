import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
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

  /// Loads the TFLite model from assets if it hasn't been loaded yet.
  Future<void> _ensureModel() async {
    if (_loaded) return;
    _interpreter =
        await Interpreter.fromAsset('assets/models/kalo.tflite');
    final normJson =
        await rootBundle.loadString('assets/models/voice_norm.json');
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
    final features = _normalizeFeatures(rawFeatures);

    // 🧪 Debugging logs
    print('🧠 Extracted features: $rawFeatures');
    print('🧪 Normalized features: $features');
    print('🔢 Feature count: ${features.length}');
    print('🔢 Raw Feature count: ${rawFeatures.length}');
    print('✅ All finite: ${features.every((v) => v.isFinite)}');


    final input = Float32List.fromList(features).reshape([1, 16]);
    final output = Float32List(1).reshape([1, 1]);
    print('📤 Final input to model: ${input[0]}');
    _interpreter.run(input, output);

    
    print('📤 Final input to model: ${input[0]}');
    print('📈 raw Model output: $output');
    
    print('📈 Raw output: ${output[0][0]}');
    return output[0][0];

  }

  /// Normalizes features using the same means and stds used in training.
  /// The parameters are loaded from [voice_norm.json] when the model is
  /// initialized so that Flutter and Python share identical values.
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

  /// Extracts a simplified set of voice features from the WAV bytes.
  Future<List<double>> _extractFeatures(File wav) async {
    final bytes = await wav.readAsBytes();
    final samples = bytes.buffer
        .asInt16List(44)
        .map((e) => e.toDouble())
        .toList();

    if (samples.isEmpty) {
      return List.filled(16, 0);
    }

    // 🎧 Debug audio levels
    print('🔊 Max sample: ${samples.reduce(max)}');
    print('🔊 Min sample: ${samples.reduce(min)}');

    final rate = bytes.buffer.asByteData().getUint32(24, Endian.little);

    final fft = FFT(samples.length);
    final freqs = fft.realFft(samples);
    final magnitudes = List<double>.generate(freqs.length ~/ 2, (i) {
      final abs = freqs[i].abs();
      return abs.x + abs.y;
    });

    int maxIndex = 0;
    for (int i = 1; i < magnitudes.length; i++) {
      if (magnitudes[i] > magnitudes[maxIndex]) maxIndex = i;
    }

    final fo = maxIndex * rate / samples.length;
    final fhi = (magnitudes.lastIndexWhere((m) => m > 0.01)) * rate / samples.length;
    final flo = (magnitudes.indexWhere((m) => m > 0.01)) * rate / samples.length;

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

    final avgPeriod = periods.isNotEmpty
        ? periods.reduce((a, b) => a + b) / periods.length
        : 0.0;

    final jitterAbs = periods.isNotEmpty
        ? periods.map((p) => (p - avgPeriod).abs()).reduce((a, b) => a + b) / periods.length
        : 0.0;

    final jitterPct = avgPeriod > 0 ? jitterAbs / avgPeriod : 0.0;

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

    final amplitudes = samples.map((e) => e.abs().toDouble()).toList();
    final ampMean = amplitudes.reduce((a, b) => a + b) / amplitudes.length;

    final shimmer = amplitudes
            .map((a) => (a - ampMean).abs())
            .reduce((a, b) => a + b) / amplitudes.length / ampMean;

    final shimmerDb = 20 * log(shimmer + 1e-6) / ln10;
    final apq3 = shimmer;
    final apq5 = shimmer;
    final apq = shimmer;
    final dda = 3 * apq3;

    final totalEnergy = magnitudes.reduce((a, b) => a + b);
    final harmonicEnergy = magnitudes[maxIndex];
    final nhr = harmonicEnergy > 0 ? (totalEnergy - harmonicEnergy) / harmonicEnergy : 0.0;
    final hnr = nhr > 0 ? 1 / nhr : 0.0;

    print("fo: $fo");
    print("fhi: $fhi");
    print("flo: $flo");
    print("jitterAbs: $jitterAbs");
    print("jitterPct: $jitterPct");
    print("rap: $rap");
    print("ppq: $ppq");
    print("ddp: $ddp");
    print("shimmer: $shimmer");
    print("shimmerDb: $shimmerDb");
    print("apq3: $apq3");
    print("apq5: $apq5");
    print("apq: $apq");
    print("dda: $dda");
    print("nhr: $nhr");
    print("hnr: $hnr");
// ...

    return [
      fo, fhi, flo,
      jitterPct, jitterAbs,
      rap, ppq, ddp,
      shimmer, shimmerDb,
      apq3, apq5, apq, dda,
      nhr, hnr,
    ];
  }
}
