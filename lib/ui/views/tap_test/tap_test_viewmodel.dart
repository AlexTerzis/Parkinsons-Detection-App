import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:stacked/stacked.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import '../../../app/app.locator.dart';
import '../../../services/test_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';

enum TapTestStatus { initial, starting, rightHand, switchHands, leftHand, completed, stopped }

class TapTestViewModel extends BaseViewModel {
  // Services used to persist results and fetch the current user
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  final int testDuration = 10; // seconds per hand
  final int pauseDuration = 5;

  int secondsLeft = 0;
  bool isTesting = false;
  TapTestStatus status = TapTestStatus.initial;
  String resultHand1 = '';
  String resultHand2 = '';

  double _score1 = 0.0;
  double _score2 = 0.0;

  int _phase = 0; // 0=hand1,1=pause,2=hand2,3=done
  Timer? _timer;
  final List<DateTime> _tapTimes = [];
  final List<Map<String, DateTime>> _tapPairs = [];
  final List<Map<String, DateTime>> _historyHand1 = [];
  final List<Map<String, DateTime>> _historyHand2 = [];
  late final Interpreter _interpreter;
  bool _modelLoaded = false;

  double get progress => secondsLeft / testDuration;

  String statusText(AppLocalizations l10n) {
    switch (status) {
      case TapTestStatus.initial:
        return l10n.pressStart;
      case TapTestStatus.starting:
        return l10n.startingTest;
      case TapTestStatus.rightHand:
        return l10n.tapRightHand;
      case TapTestStatus.switchHands:
        return l10n.switchHands;
      case TapTestStatus.leftHand:
        return l10n.tapLeftHand;
      case TapTestStatus.completed:
        return l10n.testCompleted;
      case TapTestStatus.stopped:
        return l10n.testStopped;
    }
  }

  Future<void> initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/tapping_model.tflite');
      _modelLoaded = true;
      debugPrint('✅ Model loaded');
    } catch (e) {
      debugPrint('❌ Failed to load model: $e');
    }
  }

  Future<void> loadModel() => initModel();

  void onTapDown() {
    if (isTesting && (_phase == 0 || _phase == 2)) {
      _tapPairs.add({'down': DateTime.now()});
    }
  }

  void onTapUp() {
    if (isTesting && (_phase == 0 || _phase == 2)) {
      if (_tapPairs.isNotEmpty && !_tapPairs.last.containsKey('up')) {
        _tapPairs.last['up'] = DateTime.now();
      }
    }
  }

  Future<void> startTest(AppLocalizations l10n) async {
    if (!_modelLoaded) {
      await initModel();
    }
    _reset();
    _startHand1(l10n);
  }

  void _reset() {
    resultHand1 = '';
    resultHand2 = '';
    _historyHand1.clear();
    _historyHand2.clear();
    _score1 = 0.0;
    _score2 = 0.0;
    status = TapTestStatus.starting;
    isTesting = true;
    _phase = 0;
    notifyListeners();
  }

  void _startHand1(AppLocalizations l10n) {
    _phase = 0;
    status = TapTestStatus.rightHand;
    secondsLeft = testDuration;
    _tapTimes.clear();
    _tapPairs.clear();

    _startTimer(() async {
      resultHand1 = await _predictFromTaps(
        l10n.rightHandLabel,
        List.of(_tapPairs),
        l10n,
        storeInHand1: true,
      );
      _historyHand1.addAll(List.of(_tapPairs));
      _startPause(l10n);
    });
  }

  void _startPause(AppLocalizations l10n) {
    _phase = 1;
    status = TapTestStatus.switchHands;
    secondsLeft = pauseDuration;
    _tapTimes.clear();
    _tapPairs.clear();

    _startTimer(() => _startHand2(l10n));
  }

  void _startHand2(AppLocalizations l10n) {
    _phase = 2;
    status = TapTestStatus.leftHand;
    secondsLeft = testDuration;
    _tapTimes.clear();
    _tapPairs.clear();

    _startTimer(() async {
      resultHand2 = await _predictFromTaps(
        l10n.leftHandLabel,
        List.of(_tapPairs),
        l10n,
        storeInHand1: false,
      );
      _historyHand2.addAll(List.of(_tapPairs));
      status = TapTestStatus.completed;
      isTesting = false;
      _phase = 3;
      notifyListeners();
      await _saveResult(max(_score1, _score2));
    });
  }

  void _startTimer(Function onFinish) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      notifyListeners();

      if (secondsLeft <= 0) {
        timer.cancel();
        onFinish();
      }
    });
  }

  // Runs the ML model on the collected tap data. The score is stored so
  // we can later upload it to Firestore. The method still returns a
  // human readable string for display.
  Future<String> _predictFromTaps(
    String label,
    List<Map<String, DateTime>> tapPairs,
    AppLocalizations l10n, {
    required bool storeInHand1,
  }) async {
    if (!_modelLoaded || tapPairs.length < 2) return l10n.predictionNotAvailable;

    final intervals = <double>[];
    final holdTimes = <double>[];

    for (int i = 1; i < tapPairs.length; i++) {
      final currentDown = tapPairs[i]['down']!;
      final prevDown = tapPairs[i - 1]['down']!;
      final interval = currentDown.difference(prevDown).inMilliseconds / 1000;
      intervals.add(interval);
    }

    for (final pair in tapPairs) {
      if (pair.containsKey('down') && pair.containsKey('up')) {
        final hold = pair['up']!.difference(pair['down']!).inMilliseconds / 1000;
        holdTimes.add(hold);
      }
    }

    final durationSec = testDuration.toDouble();
    final freq = tapPairs.length / durationSec;

    final avg = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((d) => (d - avg) * (d - avg)).reduce((a, b) => a + b) / intervals.length;
    final maxVal = intervals.reduce(max);
    final minVal = intervals.reduce(min);
    final range = maxVal - minVal;
    final stdDev = sqrt(variance);
    final avgHold = holdTimes.isNotEmpty ? holdTimes.reduce((a, b) => a + b) / holdTimes.length : 0.0;

    final input = Float32List.fromList([
      avg,
      variance,
      freq,
      maxVal,
      minVal,
      range,
      stdDev
    ]).reshape([1, 7]);

    final output = Float32List(1).reshape([1, 1]);

    debugPrint('Predicting with:\n'
        'avg=$avg var=$variance freq=$freq\n'
        'max=$maxVal min=$minVal range=$range stdDev=$stdDev hold=$avgHold');

    try {
      _interpreter.run(input, output);
    } catch (e) {
      debugPrint('❌ Interpreter run failed: $e');
      return l10n.predictionFailed;
    }

    final prediction = output[0][0];
    if (storeInHand1) {
      _score1 = prediction;
    } else {
      _score2 = prediction;
    }
    final percent = (prediction * 100).toStringAsFixed(1);

    return prediction >= 0.5
        ? l10n.tapParkinsonPattern(label, percent)
        : l10n.tapNormalPattern(label, percent);
  }

  // Persists the normalized score to Firestore
  Future<void> _saveResult(double score) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.tap,
      performedAt: DateTime.now(),
      score: score.clamp(0, 1),
    );
    final hand1 = _historyHand1
        .map((p) => {
              'down': p['down']?.millisecondsSinceEpoch,
              'up': p['up']?.millisecondsSinceEpoch,
            })
        .toList();
    final hand2 = _historyHand2
        .map((p) => {
              'down': p['down']?.millisecondsSinceEpoch,
              'up': p['up']?.millisecondsSinceEpoch,
            })
        .toList();

    await _tests.addResult(
      result: result,
      sensorData: {'hand1': hand1, 'hand2': hand2},
    );
  }

  void stopTest() {
    _timer?.cancel();
    isTesting = false;
    status = TapTestStatus.stopped;
    notifyListeners();
  }
  @override
  void dispose() {
    // Cancel any running timer so it doesn't trigger after dispose
    _timer?.cancel();
    // Close the interpreter only if the model was loaded to free resources
    if (_modelLoaded) {
      _interpreter.close();
    }
    super.dispose();
  }
}
