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

  void recordTap() {
    if (isTesting && (_phase == 0 || _phase == 2)) {
      _tapTimes.add(DateTime.now());
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
    _startTimer(() async {
      resultHand1 = await _predictFromTaps(List.of(_tapTimes));
      _startPause();
    });
  }

  void _startPause() {
    _phase = 1;
    status = 'Switch hands';
    secondsLeft = pauseDuration;
    _tapTimes.clear();
    _startTimer(_startHand2);
  }

  void _startHand2() {
    _phase = 2;
    status = 'Tap with left hand';
    secondsLeft = testDuration;
    _tapTimes.clear();
    _startTimer(() async {
      resultHand2 = await _predictFromTaps(List.of(_tapTimes));
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

  Future<String> _predictFromTaps(List<DateTime> taps) async {
  if (!_modelLoaded || taps.length < 2) return 'Prediction not available';

  final durationSec = testDuration.toDouble();
  final freq = taps.length / durationSec;

  final intervals = <double>[];
  for (int i = 1; i < taps.length; i++) {
    intervals.add(taps[i].difference(taps[i - 1]).inMilliseconds / 1000);
  }

  final avg = intervals.reduce((a, b) => a + b) / intervals.length;
  final variance = intervals.map((d) => (d - avg) * (d - avg)).reduce((a, b) => a + b) / intervals.length;

  final max = intervals.reduce((a, b) => a > b ? a : b);
  final min = intervals.reduce((a, b) => a < b ? a : b);
  final range = max - min;
  final stdDev = variance == 0.0 ? 0.0 : sqrt(variance);

  final input = Float32List.fromList([
    avg.toDouble(),
    variance.toDouble(),
    freq.toDouble(),
    max.toDouble(),
    min.toDouble(),
    range.toDouble(),
    stdDev.toDouble()
  ]).reshape([1, 7]);

  final output = Float32List(1).reshape([1, 1]);

  print('Predicting with:\n'
      'avg=$avg var=$variance freq=$freq\n'
      'max=$max min=$min range=$range stdDev=$stdDev');

  try {
    _interpreter.run(input, output);
  } catch (e) {
    print('❌ Interpreter run failed: $e');
    return 'Prediction failed';
  }

  final prediction = output[0][0];
  final percent = (prediction * 100).toStringAsFixed(1);

  return prediction >= 0.5
      ? '🧠 Parkinson-like pattern ($percent%)'
      : '✅ Normal tapping ($percent%)';
}

  void stopTest() {
    _timer?.cancel();
    isTesting = false;
    status = 'Test stopped';
    notifyListeners();
  }
}
