import 'dart:async';
import 'dart:typed_data';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stacked/stacked.dart';
import 'package:fftea/fftea.dart';

class TremorTestViewModel extends BaseViewModel {
  final int testDuration = 11; // seconds per hand
  final int pauseDuration = 5; // seconds between hands

  List<double> accX = [];
  List<double> accY = [];
  List<double> accZ = [];

  List<double> gyroX = [];
  List<double> gyroY = [];
  List<double> gyroZ = [];

  List<double> spectrumX1 = [];
  List<double> spectrumY1 = [];
  List<double> spectrumZ1 = [];

  List<double> spectrumX2 = [];
  List<double> spectrumY2 = [];
  List<double> spectrumZ2 = [];

  double latestX = 0.0;
  double latestY = 0.0;
  double latestZ = 0.0;

  double latestGyroX = 0.0;
  double latestGyroY = 0.0;
  double latestGyroZ = 0.0;

  String resultHand1 = '';
  String resultHand2 = '';
  String tremorStatus = 'Press start to begin';
  int secondsLeft = 0;
  bool isTesting = false;

  int _phase = 0; // 0 = hand 1, 1 = pause, 2 = hand 2, 3 = done
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _countdownTimer;

  Future<void> startTest() async {
    _reset();
    await Future.delayed(const Duration(milliseconds: 200));
    _startHand1();
  }

  void _reset() {
    accX.clear(); accY.clear(); accZ.clear();
    gyroX.clear(); gyroY.clear(); gyroZ.clear();
    spectrumX1.clear(); spectrumY1.clear(); spectrumZ1.clear();
    spectrumX2.clear(); spectrumY2.clear(); spectrumZ2.clear();
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
    _startSensors();
    _startTimer(() {
      _stopSensors();
      resultHand1 = _analyzeData('Hand 1', storeInHand1: true);
      _startPause();
    });
  }

  void _startPause() {
    _phase = 1;
    tremorStatus = 'Switch hands';
    secondsLeft = pauseDuration;
    accX.clear(); accY.clear(); accZ.clear();
    gyroX.clear(); gyroY.clear(); gyroZ.clear();
    notifyListeners();
    _startTimer(() => _startHand2());
  }

  void _startHand2() {
    _phase = 2;
    tremorStatus = 'Testing Hand 2...';
    secondsLeft = testDuration;
    _startSensors();
    _startTimer(() {
      _stopSensors();
      resultHand2 = _analyzeData('Hand 2', storeInHand1: false);
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

  void _startSensors() {
    _accelSub = accelerometerEvents.listen((event) {
      latestX = event.x;
      latestY = event.y;
      latestZ = event.z;
      accX.add(event.x);
      accY.add(event.y);
      accZ.add(event.z);
      notifyListeners();
    });

    _gyroSub = gyroscopeEvents.listen((event) {
      latestGyroX = event.x;
      latestGyroY = event.y;
      latestGyroZ = event.z;
      gyroX.add(event.x);
      gyroY.add(event.y);
      gyroZ.add(event.z);
    });
  }

  void _stopSensors() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
  }

  String _analyzeData(String label, {required bool storeInHand1}) {
    List<double> analyzeAxis(List<double> data) {
      if (data.length < 32) return [];
      int paddedLength = _nextPowerOfTwo(data.length);
      List<double> padded = List.filled(paddedLength, 0.0);
      for (int i = 0; i < data.length; i++) {
        padded[i] = data[i];
      }
      final fft = FFT(paddedLength);
      final result = fft.realFft(Float64List.fromList(padded));
      return result.discardConjugates().magnitudes();
    }

    final magsX = analyzeAxis(accX);
    final magsY = analyzeAxis(accY);
    final magsZ = analyzeAxis(accZ);

    if (storeInHand1) {
      spectrumX1 = magsX;
      spectrumY1 = magsY;
      spectrumZ1 = magsZ;
    } else {
      spectrumX2 = magsX;
      spectrumY2 = magsY;
      spectrumZ2 = magsZ;
    }

    double peakFreq(List<double> mags) {
      if (mags.length < 2) return 0.0;
      final sublist = mags.sublist(1);
      final maxVal = sublist.reduce((a, b) => a > b ? a : b);
      final peakIndex = mags.indexOf(maxVal);
      return peakIndex * (mags.length / testDuration) / mags.length;
    }

    return '$label Results (Accelerometer):\n'
        'X Peak Frequency: ${peakFreq(magsX).toStringAsFixed(2)} Hz\n'
        'Y Peak Frequency: ${peakFreq(magsY).toStringAsFixed(2)} Hz\n'
        'Z Peak Frequency: ${peakFreq(magsZ).toStringAsFixed(2)} Hz';
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
    _stopSensors();
    isTesting = false;
    tremorStatus = 'Test stopped';
    notifyListeners();
  }
}
