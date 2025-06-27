import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:stacked/stacked.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TapTestViewModel extends BaseViewModel {
  final int testDuration = 10; // seconds per hand
  final int pauseDuration = 5;

  int secondsLeft = 0;
  bool isTesting = false;
  String status = 'Press start to begin';
  String resultHand1 = '';
  String resultHand2 = '';

  int _phase = 0; // 0=hand1,1=pause,2=hand2,3=done
  Timer? _timer;
  final List<DateTime> _tapTimes = [];
  final List<Map<String, DateTime>> _tapPairs = [];

  late final Interpreter _interpreter;
  bool _modelLoaded = false;

  double get progress => secondsLeft / testDuration;

  Future<void> initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/tapping_model.tflite');
      _modelLoaded = true;
      print('✅ Model loaded');
    } catch (e) {
      print('❌ Failed to load model: $e');
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

  Future<void> startTest() async {
    if (!_modelLoaded) {
      await initModel();
    }
    _reset();
    _startHand1();
  }

  void _reset() {
    resultHand1 = '';
    resultHand2 = '';
    status = 'Starting test...';
    isTesting = true;
    _phase = 0;
    notifyListeners();
  }

  void _startHand1() {
    _phase = 0;
    status = 'Tap with right hand';
    secondsLeft = testDuration;
    _tapTimes.clear();
    _tapPairs.clear();

    _startTimer(() async {
      resultHand1 = await _predictFromTaps("Right hand", List.of(_tapPairs));
      _startPause();
    });
  }

  void _startPause() {
    _phase = 1;
    status = 'Switch hands';
    secondsLeft = pauseDuration;
    _tapTimes.clear();
    _tapPairs.clear();

    _startTimer(_startHand2);
  }

  void _startHand2() {
    _phase = 2;
    status = 'Tap with left hand';
    secondsLeft = testDuration;
    _tapTimes.clear();
    _tapPairs.clear();

    _startTimer(() async {
      resultHand2 = await _predictFromTaps("Left hand", List.of(_tapPairs));
      status = 'Test completed';
      isTesting = false;
      _phase = 3;
      notifyListeners();
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

  Future<String> _predictFromTaps(String label, List<Map<String, DateTime>> tapPairs) async {
    if (!_modelLoaded || tapPairs.length < 2) return 'Prediction not available';

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

    print('Predicting with:\n'
        'avg=$avg var=$variance freq=$freq\n'
        'max=$maxVal min=$minVal range=$range stdDev=$stdDev hold=$avgHold');

    try {
      _interpreter.run(input, output);
    } catch (e) {
      print('❌ Interpreter run failed: $e');
      return 'Prediction failed';
    }

    final prediction = output[0][0];
    final percent = (prediction * 100).toStringAsFixed(1);

    return prediction >= 0.5
        ? '$label: ⚠️ Parkinson-like pattern ($percent%)'
        : '$label: ✅ Normal tapping ($percent%)';
  }

  void stopTest() {
    _timer?.cancel();
    isTesting = false;
    status = 'Test stopped';
    notifyListeners();
  }
}
