import 'dart:async';
import 'dart:typed_data';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stacked/stacked.dart';
import 'package:fftea/fftea.dart';

class TremorTestViewModel extends BaseViewModel {
  final int testDuration = 10; // seconds per hand
  final int pauseDuration = 5; // seconds between hands

  List<double> accX = [];
  List<double> accY = [];
  List<double> accZ = [];

  double latestX = 0.0;
  double latestY = 0.0;
  double latestZ = 0.0;

  String resultHand1 = '';
  String resultHand2 = '';
  String tremorStatus = 'Press start to begin';
  int secondsLeft = 0;
  bool isTesting = false;

  int _phase = 0; // 0 = hand 1, 1 = pause, 2 = hand 2, 3 = done
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _countdownTimer;

  void startTest() {
    _reset();
    _startHand1();
  }

  void _reset() {
    accX.clear();
    accY.clear();
    accZ.clear();
    resultHand1 = '';
    resultHand2 = '';
    tremorStatus = 'Starting test...';
    _phase = 0;
    isTesting = true;
    notifyListeners();
  }

  void _startHand1() {
    _phase = 0;
    tremorStatus = 'Testing Hand 1...';
    secondsLeft = testDuration;
    _startSensor();
    _startTimer(() {
      _stopSensor();
      resultHand1 = _analyzeData('Hand 1');
      _startPause();
    });
  }

  void _startPause() {
    _phase = 1;
    tremorStatus = 'Switch hands';
    secondsLeft = pauseDuration;
    accX.clear();
    accY.clear();
    accZ.clear();
    notifyListeners();
    _startTimer(() => _startHand2());
  }

  void _startHand2() {
    _phase = 2;
    tremorStatus = 'Testing Hand 2...';
    secondsLeft = testDuration;
    _startSensor();
    _startTimer(() {
      _stopSensor();
      resultHand2 = _analyzeData('Hand 2');
      tremorStatus = 'Test completed';
      isTesting = false;
      _phase = 3;
      notifyListeners();
    });
  }

  void _startTimer(Function onFinish) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      notifyListeners();
      if (secondsLeft <= 0) {
        timer.cancel();
        onFinish();
      }
    });
  }

  void _startSensor() {
    _accelSub = accelerometerEvents.listen((event) {
      latestX = event.x;
      latestY = event.y;
      latestZ = event.z;

      accX.add(event.x);
      accY.add(event.y);
      accZ.add(event.z);

      notifyListeners();
    });
  }

  void _stopSensor() {
    _accelSub?.cancel();
  }

  String _analyzeData(String label) {
    String analyzeAxis(List<double> data, String axis) {
      if (data.length < 32) return '$axis: Not enough data';

      int paddedLength = _nextPowerOfTwo(data.length);
      List<double> padded = List<double>.filled(paddedLength, 0.0);
      for (int i = 0; i < data.length; i++) {
        padded[i] = data[i];
      }

      final fft = FFT(paddedLength);
      final result = fft.realFft(Float64List.fromList(padded));
      final mags = result.discardConjugates().magnitudes();

      final samplingRate = data.length / testDuration;
      final sublist = mags.sublist(1); // skip DC
      final maxVal = sublist.reduce((a, b) => a > b ? a : b);
      final peakIndex = mags.indexOf(maxVal);
      final peakFreq = peakIndex * samplingRate / mags.length;

      return '$axis Peak Frequency: ${peakFreq.toStringAsFixed(2)} Hz';
    }

    return '$label Results:\n'
        '${analyzeAxis(accX, 'X')}\n'
        '${analyzeAxis(accY, 'Y')}\n'
        '${analyzeAxis(accZ, 'Z')}';
  }

  int _nextPowerOfTwo(int n) {
    int power = 1;
    while (power < n) {
      power *= 2;
    }
    return power;
  }

  void stopTest() {
    _countdownTimer?.cancel();
    _stopSensor();
    isTesting = false;
    tremorStatus = 'Test stopped';
    notifyListeners();
  }
}
