import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stacked/stacked.dart';
import 'package:fftea/fftea.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import '../../../app/app.locator.dart';
import '../../../services/test_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import 'package:flutter/foundation.dart';
import '../test_complete/test_complete_view.dart';

class TremorTestViewModel extends BaseViewModel {
  // Services used for storing results
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  final int testDuration = 10; // seconds per hand
  final int pauseDuration = 5; // seconds between hands

  List<double> accX = [];
  List<double> accY = [];
  List<double> accZ = [];

  List<double> gyroX = [];
  List<double> gyroY = [];
  List<double> gyroZ = [];

  // Raw sensor capture for upload
  final List<List<double>> _accData = [];
  final List<List<double>> _gyroData = [];

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

  double _score1 = 0.0;
  double _score2 = 0.0;
  String tremorStatus = '';
  int secondsLeft = 0;

  /// Elapsed fraction of the countdown currently running, for the progress bar.
  ///
  /// The denominator follows [phase]: the pause between hands counts down from
  /// [pauseDuration], not [testDuration], so sharing one divisor would make the
  /// bar jump backwards when the pause starts.
  double get progress {
    final total = phase == 1 ? pauseDuration : testDuration;
    if (total == 0) return 0;
    return ((total - secondsLeft) / total).clamp(0.0, 1.0);
  }

  bool isTesting = false;

  /// Which leg of the two-hand sequence is running: 0 = hand 1, 1 = pause,
  /// 2 = hand 2, 3 = done. Exposed because the value is only ever written
  /// internally, and a private field the analyzer sees no reads of is flagged
  /// as dead — but the state is real and worth surfacing to the view.
  int phase = 0;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _countdownTimer;

  Future<void> startTest(AppLocalizations l10n) async {
    _reset(l10n);
    await Future.delayed(const Duration(milliseconds: 200));
    _startHand1(l10n);
  }

  void _reset(AppLocalizations l10n) {
    accX.clear(); accY.clear(); accZ.clear();
    gyroX.clear(); gyroY.clear(); gyroZ.clear();
    spectrumX1.clear(); spectrumY1.clear(); spectrumZ1.clear();
    spectrumX2.clear(); spectrumY2.clear(); spectrumZ2.clear();
    resultHand1 = '';
    resultHand2 = '';
    _score1 = 0.0;
    _score2 = 0.0;
    tremorStatus = l10n.startingTest;
    phase = 0;
    _accData.clear();
    _gyroData.clear();
    isTesting = true;
    notifyListeners();
  }

  void _startHand1(AppLocalizations l10n) {
    phase = 0;
    tremorStatus = l10n.testingHand1;
    secondsLeft = testDuration;
    _startSensors();
    _startTimer(() {
      _stopSensors();
      resultHand1 = _analyzeData(l10n.handOneLabel, l10n, storeInHand1: true);
      _startPause(l10n);
    });
  }

  void _startPause(AppLocalizations l10n) {
    phase = 1;
    tremorStatus = l10n.switchHands;
    secondsLeft = pauseDuration;
    accX.clear(); accY.clear(); accZ.clear();
    gyroX.clear(); gyroY.clear(); gyroZ.clear();
    notifyListeners();
    _startTimer(() => _startHand2(l10n));
  }

  void _startHand2(AppLocalizations l10n) {
    phase = 2;
    tremorStatus = l10n.testingHand2;
    secondsLeft = testDuration;
    _startSensors();
    _startTimer(() async {
      _stopSensors();
      resultHand2 = _analyzeData(l10n.handTwoLabel, l10n, storeInHand1: false);
      tremorStatus = l10n.testCompleted;
      isTesting = false;
      phase = 3;
      notifyListeners();
      await _saveResult(math.max(_score1, _score2));
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
      _accData.add([event.x, event.y, event.z]);
      notifyListeners();
    });

    _gyroSub = gyroscopeEvents.listen((event) {
      latestGyroX = event.x;
      latestGyroY = event.y;
      latestGyroZ = event.z;
      gyroX.add(event.x);
      gyroY.add(event.y);
      gyroZ.add(event.z);
      _gyroData.add([event.x, event.y, event.z]);
    });
  }

  void _stopSensors() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
  }

  // Analyzes the captured sensor values and calculates a simple tremor score.
  // The frequency with the highest magnitude is used as an indicator.
  String _analyzeData(String label, AppLocalizations l10n,
      {required bool storeInHand1}) {
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

    final fx = peakFreq(magsX);
    final fy = peakFreq(magsY);
    final fz = peakFreq(magsZ);
    final score = (math.max(fx, math.max(fy, fz)) / 20).clamp(0.0, 1.0);
    if (storeInHand1) {
      _score1 = score;
    } else {
      _score2 = score;
    }

    return l10n.fftResultsTemplate(
      label,
      fx.toStringAsFixed(2),
      fy.toStringAsFixed(2),
      fz.toStringAsFixed(2),
    );
  }

  int _nextPowerOfTwo(int n) {
    int power = 1;
    while (power < n) {
      power *= 2;
    }
    return power;
  }

  void stopTest(AppLocalizations l10n) {
    _countdownTimer?.cancel();
    _stopSensors();
    isTesting = false;
    tremorStatus = l10n.testStopped;
    notifyListeners();
  }

  // Saves the greater of the two hand scores to Firestore
  Future<void> _saveResult(double score) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.tremor,
      performedAt: DateTime.now(),
      score: score.clamp(0, 1),
    );
    bool saved = true;
    try {
      await _tests.addResult(
        result: result,
        sensorData: {
          'accelerometer': _accData,
          'gyroscope': _gyroData,
        },
      );
    } catch (e) {
      saved = false;
      debugPrint('Could not save tremor result: $e');
    }

    await showTestComplete(
      type: TestType.tremor,
      score: result.score,
      saved: saved,
    );
  }
  
  @override
  void dispose() {
    // Ensure countdown timer and sensor streams are cleaned up
    _countdownTimer?.cancel();
    _stopSensors();
    super.dispose();
  }
}
