import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import '../../../app/app.locator.dart';
import '../../../services/test_service.dart';
import '../../../services/authentication_service.dart';
import '../../../services/tap_model_features.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../test_complete/test_complete_view.dart';

enum TapTestStatus { initial, starting, rightHand, switchHands, leftHand, completed, stopped }

class TapHandMetrics {
  const TapHandMetrics({required this.hand, required this.tapCount,
    required this.tapsPerSecond, required this.averageInterval,
    required this.consistency});
  final String hand;
  final int tapCount;
  final double tapsPerSecond;
  final double averageInterval;
  final double consistency;
}

class TapTestViewModel extends BaseViewModel {
  // Services used to persist results and fetch the current user
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  final int testDuration = 10; // seconds per hand
  final int pauseDuration = 5;

  int secondsLeft = 0;
  bool isTesting = false;
  bool isPadPressed = false;
  TapTestStatus status = TapTestStatus.initial;
  String resultHand1 = '';
  String resultHand2 = '';
  TapHandMetrics? rightMetrics;
  TapHandMetrics? leftMetrics;
  bool isSavingResult = false;
  bool _resultSaved = true;
  double _completionConcern = 0;

  /// Null until the model returns a prediction for that hand, so a run the
  /// model could not score is distinguishable from one it scored 0.
  double? _score1;
  double? _score2;

  /// False when neither hand produced a prediction. The result screen shows a
  /// concern band, and a band built from a missing score reads as a clean run.
  bool _hasScore = false;

  int _phase = 0; // 0=hand1,1=pause,2=hand2,3=done
  Timer? _timer;
  final List<DateTime> _tapTimes = [];
  final List<Map<String, DateTime>> _tapPairs = [];
  final List<Map<String, DateTime>> _historyHand1 = [];
  final List<Map<String, DateTime>> _historyHand2 = [];
  late final Interpreter _interpreter;
  bool _modelLoaded = false;

  double get progress {
    final total = _phase == 1 ? pauseDuration : testDuration;
    return ((total - secondsLeft) / total).clamp(0, 1).toDouble();
  }

  int get currentTapCount =>
      _tapPairs.where((pair) => pair.containsKey('up')).length;

  double get currentTapsPerSecond {
    final elapsed = testDuration - secondsLeft;
    return elapsed <= 0 ? 0 : currentTapCount / elapsed;
  }

  double get currentConsistency => _metricsFrom(
        _phase == 2 ? 'left' : 'right', List.of(_tapPairs)).consistency;

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
      isPadPressed = true;
      _tapPairs.add({'down': DateTime.now()});
      notifyListeners();
    }
  }

  void onTapUp() {
    isPadPressed = false;
    if (isTesting && (_phase == 0 || _phase == 2)) {
      if (_tapPairs.isNotEmpty && !_tapPairs.last.containsKey('up')) {
        _tapPairs.last['up'] = DateTime.now();
      }
    }
    notifyListeners();
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
    _score1 = null;
    _score2 = null;
    _hasScore = false;
    rightMetrics = null;
    leftMetrics = null;
    isSavingResult = false;
    status = TapTestStatus.starting;
    isTesting = true;
    isPadPressed = false;
    _phase = 0;
    notifyListeners();
  }

  void _startHand1(AppLocalizations l10n) {
    _phase = 0;
    status = TapTestStatus.rightHand;
    secondsLeft = testDuration;
    _tapTimes.clear();
    _tapPairs.clear();
    // The model's half-counts are offsets into the run, so the run needs a
    // zero. Captured here rather than held as a field so the second hand
    // cannot be measured against the first hand's start.
    final handStart = DateTime.now();

    _startTimer(() async {
      rightMetrics = _metricsFrom('right', List.of(_tapPairs));
      resultHand1 = await _predictFromTaps(
        l10n.rightHandLabel,
        List.of(_tapPairs),
        l10n,
        handStart: handStart,
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
    isPadPressed = false;

    _startTimer(() => _startHand2(l10n));
  }

  void _startHand2(AppLocalizations l10n) {
    _phase = 2;
    status = TapTestStatus.leftHand;
    secondsLeft = testDuration;
    _tapTimes.clear();
    _tapPairs.clear();
    final handStart = DateTime.now();

    _startTimer(() async {
      leftMetrics = _metricsFrom('left', List.of(_tapPairs));
      resultHand2 = await _predictFromTaps(
        l10n.leftHandLabel,
        List.of(_tapPairs),
        l10n,
        handStart: handStart,
        storeInHand1: false,
      );
      _historyHand2.addAll(List.of(_tapPairs));
      status = TapTestStatus.completed;
      isTesting = false;
      _phase = 3;

      final scored = [_score1, _score2].whereType<double>();
      if (scored.isEmpty) {
        // Neither hand produced a prediction. This used to fall through to
        // `max(0.0, 0.0)` and store a score of 0 — indistinguishable in the
        // history charts from a flawless run.
        _hasScore = false;
        _resultSaved = false;
        isSavingResult = false;
        notifyListeners();
        return;
      }

      isSavingResult = true;
      notifyListeners();
      await _saveResult(scored.reduce(max));
    });
  }

  TapHandMetrics _metricsFrom(
      String hand, List<Map<String, DateTime>> tapPairs) {
    final completed = tapPairs
        .where((pair) => pair['down'] != null && pair['up'] != null)
        .toList();
    final intervals = <double>[];
    for (var i = 1; i < completed.length; i++) {
      intervals.add(completed[i]['down']!
          .difference(completed[i - 1]['down']!)
          .inMicroseconds / 1000000);
    }
    final average = intervals.isEmpty
        ? 0.0
        : intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.isEmpty
        ? 0.0
        : intervals.map((v) => (v - average) * (v - average))
            .reduce((a, b) => a + b) / intervals.length;
    final consistency = average <= 0
        ? 0.0
        : (1 - sqrt(variance) / average).clamp(0, 1).toDouble();
    return TapHandMetrics(
      hand: hand,
      tapCount: completed.length,
      tapsPerSecond: completed.length / testDuration,
      averageInterval: average,
      consistency: consistency,
    );
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
    required DateTime handStart,
    required bool storeInHand1,
  }) async {
    if (!_modelLoaded) return l10n.predictionNotAvailable;

    final offsets = <double>[
      for (final pair in tapPairs)
        if (pair['down'] != null)
          pair['down']!.difference(handStart).inMicroseconds / 1000,
    ];
    final features = tapModelFeatures(
      offsets,
      testDurationMs: testDuration * 1000,
    );
    if (features == null) return l10n.predictionNotAvailable;

    final input = Float32List.fromList(features).reshape([1, 7]);
    final output = Float32List(1).reshape([1, 1]);

    debugPrint('Predicting with ${features.join(', ')}');

    try {
      _interpreter.run(input, output);
    } catch (e) {
      debugPrint('❌ Interpreter run failed: $e');
      return l10n.predictionFailed;
    }

    final prediction = (output[0][0] as num).toDouble();
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
    final result = TestResult(
      id: '',
      patientId: uid ?? '',
      type: TestType.tap,
      performedAt: DateTime.now(),
      score: score.clamp(0, 1).toDouble(),
      data: {
        'rightTapCount': rightMetrics?.tapCount,
        'leftTapCount': leftMetrics?.tapCount,
        'rightTapsPerSecond': rightMetrics?.tapsPerSecond,
        'leftTapsPerSecond': leftMetrics?.tapsPerSecond,
        'rightConsistency': rightMetrics?.consistency,
        'leftConsistency': leftMetrics?.consistency,
      },
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

    bool saved = uid != null;
    if (uid != null) {
      try {
        await _tests.addResult(
        result: result,
        sensorData: {'hand1': hand1, 'hand2': hand2},
        );
      } catch (e) {
        saved = false;
        debugPrint('Could not save tap result: $e');
      }
    }

    _resultSaved = saved;
    _hasScore = true;
    _completionConcern = result.concernScore;
    isSavingResult = false;
    notifyListeners();
  }

  Future<void> continueToCompletion() async {
    if (!_hasScore) {
      // Nothing was scored, so there is no concern band to show. Going back is
      // what the voice test does with an unscored recording.
      locator<NavigationService>().back();
      return;
    }
    await showTestComplete(
      type: TestType.tap,
      concern: _completionConcern,
      saved: _resultSaved,
    );
  }

  void stopTest() {
    _timer?.cancel();
    isTesting = false;
    isPadPressed = false;
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
