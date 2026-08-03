import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../../../services/authentication_service.dart';
import '../../../services/test_service.dart';
import '../test_complete/test_complete_view.dart';

class TremorHandResult {
  const TremorHandResult({
    required this.hand,
    required this.spectrumX,
    required this.spectrumY,
    required this.spectrumZ,
    required this.binWidthHz,
    required this.sampleRateHz,
    required this.dominantFrequencyHz,
    required this.confidence,
    required this.rmsMovement,
    required this.quality,
    required this.retryRecommended,
  });

  final String hand;
  final List<double> spectrumX;
  final List<double> spectrumY;
  final List<double> spectrumZ;
  final double binWidthHz;
  final double sampleRateHz;
  final double dominantFrequencyHz;
  final double confidence;
  final double rmsMovement;
  final TremorRecordingQuality quality;
  final bool retryRecommended;
}

enum TremorRecordingQuality { good, excessiveMovement, insufficientData }

class _TimedSample {
  const _TimedSample(this.seconds, this.x, this.y, this.z);
  final double seconds;
  final double x;
  final double y;
  final double z;

  List<double> toJson() => [seconds, x, y, z];
}

class TremorTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  final FlutterTts _tts = FlutterTts();

  final int testDuration = 10;
  final int pauseDuration = 5;

  bool leftFirst = true;
  bool spokenCues = false;
  bool hapticCues = true;

  final List<_TimedSample> _currentAcc = [];
  final List<_TimedSample> _currentGyro = [];
  final Map<String, List<_TimedSample>> _accByHand = {};
  final Map<String, List<_TimedSample>> _gyroByHand = {};
  final Stopwatch _sensorClock = Stopwatch();
  String _captureHand = 'left';
  int _largeMovementEvents = 0;

  TremorHandResult? firstResult;
  TremorHandResult? secondResult;

  List<double> get spectrumX1 => firstResult?.spectrumX ?? const [];
  List<double> get spectrumY1 => firstResult?.spectrumY ?? const [];
  List<double> get spectrumZ1 => firstResult?.spectrumZ ?? const [];
  List<double> get spectrumX2 => secondResult?.spectrumX ?? const [];
  List<double> get spectrumY2 => secondResult?.spectrumY ?? const [];
  List<double> get spectrumZ2 => secondResult?.spectrumZ ?? const [];
  String get resultHand1 => firstResult == null ? '' : firstResult!.hand;
  String get resultHand2 => secondResult == null ? '' : secondResult!.hand;

  String get firstHandKey => leftFirst ? 'left' : 'right';
  String get secondHandKey => leftFirst ? 'right' : 'left';
  String get activeHandKey => phase == 2 ? secondHandKey : firstHandKey;

  double latestX = 0;
  double latestY = 0;
  double latestZ = 0;
  double latestGyroX = 0;
  double latestGyroY = 0;
  double latestGyroZ = 0;

  double get motionX => (latestGyroX / 4).clamp(-1.0, 1.0).toDouble();
  double get motionY => (latestGyroY / 4).clamp(-1.0, 1.0).toDouble();
  double get movementAcceleration {
    final magnitude =
        math.sqrt(latestX * latestX + latestY * latestY + latestZ * latestZ);
    return (magnitude - 9.81).abs();
  }

  double get accelerationLevel =>
      (movementAcceleration / 8).clamp(0, 1).toDouble();

  double? get asymmetry {
    if (firstResult == null || secondResult == null) return null;
    final high = math.max(firstResult!.rmsMovement, secondResult!.rmsMovement);
    if (high <= 0) return 0;
    return ((firstResult!.rmsMovement - secondResult!.rmsMovement).abs() / high)
        .clamp(0, 1)
        .toDouble();
  }

  String tremorStatus = '';
  int secondsLeft = 0;
  bool isTesting = false;
  bool isSavingResult = false;
  bool _resultSaved = true;
  double _completionConcern = 0;
  int phase = 0; // 0 first hand, 1 switch, 2 second hand, 3 complete

  double get progress {
    final total = phase == 1 ? pauseDuration : testDuration;
    return total == 0
        ? 0
        : ((total - secondsLeft) / total).clamp(0, 1).toDouble();
  }

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _countdownTimer;

  void setLeftFirst(bool value) {
    leftFirst = value;
    notifyListeners();
  }

  void setSpokenCues(bool value) {
    spokenCues = value;
    notifyListeners();
  }

  void setHapticCues(bool value) {
    hapticCues = value;
    notifyListeners();
  }

  Future<void> startTest(AppLocalizations l10n) async {
    _reset(l10n);
    await _cue(l10n.startingTest);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _startHand1(l10n);
  }

  void _reset(AppLocalizations l10n) {
    _currentAcc.clear();
    _currentGyro.clear();
    _accByHand.clear();
    _gyroByHand.clear();
    firstResult = null;
    secondResult = null;
    tremorStatus = l10n.startingTest;
    phase = 0;
    isTesting = true;
    isSavingResult = false;
    notifyListeners();
  }

  Future<void> _startHand1(AppLocalizations l10n) async {
    phase = 0;
    tremorStatus = l10n.testingHand1;
    secondsLeft = testDuration;
    await _cue(tremorStatus);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _beginCapture(firstHandKey);
    _startTimer(() {
      _stopSensors();
      firstResult = _analyze(firstHandKey);
      _startPause(l10n);
    });
  }

  void _startPause(AppLocalizations l10n) {
    phase = 1;
    tremorStatus = l10n.switchHands;
    secondsLeft = pauseDuration;
    _zeroReadouts();
    _cue(tremorStatus);
    notifyListeners();
    _startTimer(() => _startHand2(l10n));
  }

  Future<void> _startHand2(AppLocalizations l10n) async {
    phase = 2;
    tremorStatus = l10n.testingHand2;
    secondsLeft = testDuration;
    await _cue(tremorStatus);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _beginCapture(secondHandKey);
    _startTimer(() async {
      _stopSensors();
      secondResult = _analyze(secondHandKey);
      tremorStatus = l10n.testCompleted;
      isTesting = false;
      isSavingResult = true;
      phase = 3;
      await _cue(tremorStatus);
      notifyListeners();
      await _saveResult(_overallScore());
    });
  }

  Future<void> _cue(String words) async {
    if (hapticCues) await HapticFeedback.mediumImpact();
    if (spokenCues) {
      await _tts.stop();
      await _tts.speak(words);
    }
  }

  void _beginCapture(String hand) {
    _captureHand = hand;
    _currentAcc.clear();
    _currentGyro.clear();
    _largeMovementEvents = 0;
    _sensorClock
      ..reset()
      ..start();
    _startSensors();
  }

  void _startTimer(FutureOr<void> Function() onFinish) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      secondsLeft--;
      notifyListeners();
      if (secondsLeft <= 0) {
        timer.cancel();
        await onFinish();
      }
    });
  }

  void _startSensors() {
    _accelSub = accelerometerEvents.listen((event) {
      latestX = event.x;
      latestY = event.y;
      latestZ = event.z;
      final sample = _TimedSample(
          _sensorClock.elapsedMicroseconds / 1000000, event.x, event.y, event.z);
      _currentAcc.add(sample);
      if (movementAcceleration > 25) _largeMovementEvents++;
      notifyListeners();
    });
    _gyroSub = gyroscopeEvents.listen((event) {
      latestGyroX = event.x;
      latestGyroY = event.y;
      latestGyroZ = event.z;
      _currentGyro.add(_TimedSample(
          _sensorClock.elapsedMicroseconds / 1000000, event.x, event.y, event.z));
      final rotation =
          math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (rotation > 8) _largeMovementEvents++;
    });
  }

  void _stopSensors() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    if (_sensorClock.isRunning) {
      _sensorClock.stop();
      _accByHand[_captureHand] = List<_TimedSample>.from(_currentAcc);
      _gyroByHand[_captureHand] = List<_TimedSample>.from(_currentGyro);
    }
  }

  TremorHandResult _analyze(String hand) {
    final samples = List<_TimedSample>.from(_currentAcc);
    final duration = samples.length > 1 ? samples.last.seconds - samples.first.seconds : 0.0;
    final sampleRate = duration > 0 ? (samples.length - 1) / duration : 0.0;
    final paddedLength = _nextPowerOfTwo(math.max(samples.length, 2).toInt());
    final binWidth = sampleRate > 0 ? sampleRate / paddedLength : 0.0;

    List<double> spectrum(double Function(_TimedSample) axis) {
      if (samples.length < 32) return const [];
      final values = samples.map(axis).toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      final windowed = List<double>.filled(paddedLength, 0);
      for (var i = 0; i < values.length; i++) {
        final hann = values.length == 1
            ? 1.0
            : 0.5 * (1 - math.cos(2 * math.pi * i / (values.length - 1)));
        windowed[i] = (values[i] - mean) * hann;
      }
      return FFT(paddedLength)
          .realFft(Float64List.fromList(windowed))
          .discardConjugates()
          .magnitudes();
    }

    final sx = spectrum((s) => s.x);
    final sy = spectrum((s) => s.y);
    final sz = spectrum((s) => s.z);
    final peak = _dominantPeak([sx, sy, sz], binWidth);
    final movement = samples.map((s) {
      final magnitude = math.sqrt(s.x * s.x + s.y * s.y + s.z * s.z);
      return magnitude - 9.81;
    }).toList();
    final rms = movement.isEmpty
        ? 0.0
        : math.sqrt(movement.map((v) => v * v).reduce((a, b) => a + b) /
            movement.length);
    final insufficient = samples.length < 100 || duration < testDuration * .75 || sampleRate < 15;
    final excessive = _largeMovementEvents > math.max(3, samples.length * .03);
    final quality = insufficient
        ? TremorRecordingQuality.insufficientData
        : excessive
            ? TremorRecordingQuality.excessiveMovement
            : TremorRecordingQuality.good;
    return TremorHandResult(
      hand: hand,
      spectrumX: sx,
      spectrumY: sy,
      spectrumZ: sz,
      binWidthHz: binWidth,
      sampleRateHz: sampleRate,
      dominantFrequencyHz: peak.$1,
      confidence: peak.$2,
      rmsMovement: rms,
      quality: quality,
      retryRecommended: quality != TremorRecordingQuality.good,
    );
  }

  (double, double) _dominantPeak(List<List<double>> spectra, double binWidth) {
    if (binWidth <= 0 || spectra.every((s) => s.isEmpty)) return (0, 0);
    var bestMagnitude = 0.0;
    var bestIndex = 0;
    final bandValues = <double>[];
    for (final spectrum in spectra) {
      for (var i = 1; i < spectrum.length; i++) {
        final hz = i * binWidth;
        if (hz < 2.5 || hz > 12.5) continue;
        bandValues.add(spectrum[i]);
        if (spectrum[i] > bestMagnitude) {
          bestMagnitude = spectrum[i];
          bestIndex = i;
        }
      }
    }
    if (bandValues.isEmpty || bestMagnitude == 0) return (0, 0);
    bandValues.sort();
    final baseline = bandValues[bandValues.length ~/ 2];
    final ratio = baseline > 0 ? bestMagnitude / baseline : 1.0;
    return (
      bestIndex * binWidth,
      ((ratio - 1) / 5).clamp(0, 1).toDouble(),
    );
  }

  int _nextPowerOfTwo(int n) {
    var power = 1;
    while (power < n) power *= 2;
    return power;
  }

  double _overallScore() {
    final values = [firstResult, secondResult]
        .whereType<TremorHandResult>()
        .map((r) => (r.dominantFrequencyHz / 20).clamp(0, 1).toDouble());
    return values.isEmpty ? 0 : values.reduce((a, b) => math.max(a, b));
  }

  void stopTest(AppLocalizations l10n) {
    _countdownTimer?.cancel();
    _stopSensors();
    isTesting = false;
    tremorStatus = l10n.testStopped;
    _tts.stop();
    notifyListeners();
  }

  Future<void> _saveResult(double score) async {
    final uid = _auth.currentUser?.uid;
    isSavingResult = true;
    notifyListeners();
    final result = TestResult(
      id: '', patientId: uid ?? '', type: TestType.tremor,
      performedAt: DateTime.now(), score: score.clamp(0, 1).toDouble(),
      data: {
        'firstHand': firstHandKey,
        'leftFrequencyHz': _resultFor('left')?.dominantFrequencyHz,
        'rightFrequencyHz': _resultFor('right')?.dominantFrequencyHz,
        'leftConfidence': _resultFor('left')?.confidence,
        'rightConfidence': _resultFor('right')?.confidence,
        'asymmetry': asymmetry,
      },
    );
    var saved = uid != null;
    if (uid != null) {
      try {
        await _tests.addResult(result: result, sensorData: {
        'format': 'seconds_x_y_z',
        // Keep the legacy flat fields for existing exports and readers.
        'accelerometer': [
          ...?_accByHand[firstHandKey]?.map((s) => [s.x, s.y, s.z]),
          ...?_accByHand[secondHandKey]?.map((s) => [s.x, s.y, s.z]),
        ],
        'gyroscope': [
          ...?_gyroByHand[firstHandKey]?.map((s) => [s.x, s.y, s.z]),
          ...?_gyroByHand[secondHandKey]?.map((s) => [s.x, s.y, s.z]),
        ],
        'accelerometerByHand': _accByHand.map(
            (hand, samples) => MapEntry(hand, samples.map((s) => s.toJson()).toList())),
        'gyroscopeByHand': _gyroByHand.map(
            (hand, samples) => MapEntry(hand, samples.map((s) => s.toJson()).toList())),
        });
      } catch (e) {
        saved = false;
        debugPrint('Could not save tremor result: $e');
      }
    }
    _resultSaved = saved;
    _completionConcern = result.concernScore;
    isSavingResult = false;
    notifyListeners();
  }

  /// Called explicitly from the results screen so the FFT charts remain
  /// visible until the patient chooses to continue.
  Future<void> continueToCompletion() => showTestComplete(
        type: TestType.tremor,
        concern: _completionConcern,
        saved: _resultSaved,
      );

  TremorHandResult? _resultFor(String hand) {
    if (firstResult?.hand == hand) return firstResult;
    if (secondResult?.hand == hand) return secondResult;
    return null;
  }

  void _zeroReadouts() {
    latestX = latestY = latestZ = 0;
    latestGyroX = latestGyroY = latestGyroZ = 0;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stopSensors();
    _tts.stop();
    super.dispose();
  }
}
