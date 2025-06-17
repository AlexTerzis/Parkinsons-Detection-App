import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stacked/stacked.dart';

class TremorTestViewModel extends BaseViewModel {
  List<double> accMagnitudes = [];
  List<double> gyroMagnitudes = [];

  double latestAcc = 0.0;
  double latestGyro = 0.0;
  int secondsLeft = 0;

  String tremorStatus = 'Press Start to begin test';

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _countdownTimer;

  DateTime _lastUIUpdate = DateTime.now();

  void startDetection(Function onFinish) {
    stopDetection();
    secondsLeft = 10;
    tremorStatus = 'Collecting data...';
    notifyListeners();

    _accelSub = accelerometerEvents.listen((event) {
      latestAcc = _calcMagnitude(event.x, event.y, event.z);
      accMagnitudes.add(latestAcc);

      _throttleNotify();
    });

    _gyroSub = gyroscopeEvents.listen((event) {
      latestGyro = _calcMagnitude(event.x, event.y, event.z);
      gyroMagnitudes.add(latestGyro);

      _throttleNotify();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      if (secondsLeft <= 0) {
        timer.cancel();
        _finalizeDetection(onFinish);
      }
      notifyListeners(); // UI update for timer only
    });
  }

  void _throttleNotify() {
    if (DateTime.now().difference(_lastUIUpdate).inMilliseconds > 300) {
      _lastUIUpdate = DateTime.now();
      notifyListeners();
    }
  }

  void _finalizeDetection(Function onFinish) {
    _accelSub?.cancel();
    _gyroSub?.cancel();

    double accStd = _stdDev(accMagnitudes);
    double gyroStd = _stdDev(gyroMagnitudes);

    tremorStatus = (accStd > 1.5 && gyroStd > 0.8)
        ? 'Tremor Detected'
        : 'No Tremor Detected';

    notifyListeners();

    Future.delayed(const Duration(seconds: 2), () {
      onFinish();
    });
  }

  void stopDetection() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _countdownTimer?.cancel();

    accMagnitudes.clear();
    gyroMagnitudes.clear();
    latestAcc = 0.0;
    latestGyro = 0.0;
    secondsLeft = 0;

    tremorStatus = 'Test stopped.';
    notifyListeners();
  }

  double _calcMagnitude(double x, double y, double z) =>
      sqrt(x * x + y * y + z * z);

  double _stdDev(List<double> data) {
    if (data.isEmpty) return 0;
    double mean = data.reduce((a, b) => a + b) / data.length;
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    return sqrt(variance);
  }
}
