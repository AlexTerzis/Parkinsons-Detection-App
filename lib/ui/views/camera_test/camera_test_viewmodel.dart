import 'dart:async';

import '../../../services/hand_metrics.dart';
import '../../../models/landmark_point.dart';
import '../../../services/parkinson_config.dart';

import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../services/test_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../patience/hand_landmarker_screen.dart';

class CameraTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  final HandMetrics _metrics = locator<HandMetrics>();

  int countdown = 29;
  Timer? _timer;
  final List<FrameData> _frames = [];
  bool _handsDetected = false;
  bool _disposed = false;

  void start() {
    countdown = 29;
    _frames.clear();
    _handsDetected = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      notifyListeners();
      if (countdown == 0) {
        t.cancel();
        _finish();
      }
    });
  }

  void onFrame(FrameData frame) {
    _frames.add(frame);
    if (frame.hands.isNotEmpty) _handsDetected = true;
  }

  Future<void> _finish() async {
    if (!_handsDetected) {
      setBusy(false);
      locator<NavigationService>().back(result: false);
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setBusy(false);
      locator<NavigationService>().back(result: false);
      return;
    }

    final Map<String, dynamic> metrics = _analyzeFrames();
    final double score = metrics['parkinson_probability'] as double;
    final raw = _collectLandmarks();
    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.cameraDetection,
      performedAt: DateTime.now(),
      score: score,
      data: metrics,
    );
    await _tests.addResult(
      result: result,
      sensorData: raw,
    );
    if (_disposed) return;
    setBusy(false);
    locator<NavigationService>().back(result: true);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _analyzeFrames() {
    final leftHandLandmarks = List.generate(21, (_) => <LandmarkPoint>[]);
    final rightHandLandmarks = List.generate(21, (_) => <LandmarkPoint>[]);

    for (final frame in _frames) {
      for (final hand in frame.hands) {
        for (int i = 0; i < 21; i++) {
          if (i < hand.landmarks.length) {
            if (hand.handedness == 'Left') {
              leftHandLandmarks[i].add(hand.landmarks[i]);
            } else if (hand.handedness == 'Right') {
              rightHandLandmarks[i].add(hand.landmarks[i]);
            }
          }
        }
      }
    }

    double speedVarL = _metrics.speedVarianceAll(leftHandLandmarks);
    double speedVarR = _metrics.speedVarianceAll(rightHandLandmarks);
    double accelL = _metrics.accelerationVarianceAll(leftHandLandmarks);
    double accelR = _metrics.accelerationVarianceAll(rightHandLandmarks);
    double jerkL = _metrics.jerkVarianceAll(leftHandLandmarks);
    double jerkR = _metrics.jerkVarianceAll(rightHandLandmarks);
    double spreadL = _metrics.fingerSpread(leftHandLandmarks);
    double spreadR = _metrics.fingerSpread(rightHandLandmarks);
    double tremorL = _metrics.tremorAll(leftHandLandmarks);
    double tremorR = _metrics.tremorAll(rightHandLandmarks);

    double asymmetry = (speedVarL - speedVarR).abs();

    double avg(double a, double b) => (a + b) / 2;
    final double probability =
        ParkinsonConfig.wSpeed * avg(speedVarL, speedVarR) +
        ParkinsonConfig.wTremor * avg(tremorL, tremorR) +
        ParkinsonConfig.wAccel * avg(accelL, accelR) +
        ParkinsonConfig.wJerk * avg(jerkL, jerkR) +
        ParkinsonConfig.wSpread * avg(spreadL, spreadR) +
        ParkinsonConfig.wAsym * asymmetry;

    return {
      'frames': _frames.length,
      'hands_detected_frames': _frames.where((f) => f.hands.isNotEmpty).length,
      'speed_variance_left': speedVarL,
      'speed_variance_right': speedVarR,
      'accel_variance_left': accelL,
      'accel_variance_right': accelR,
      'jerk_variance_left': jerkL,
      'jerk_variance_right': jerkR,
      'finger_spread_left': spreadL,
      'finger_spread_right': spreadR,
      'tremor_left': tremorL,
      'tremor_right': tremorR,
      'asymmetry': asymmetry,
      'parkinson_probability': probability.clamp(0, 1),
    };
  }
   /// Converts [_frames] into a simple JSON structure for upload.
  Map<String, dynamic> _collectLandmarks() {
    final left = <List<double>>[];
    final right = <List<double>>[];
    for (final frame in _frames) {
      for (final hand in frame.hands) {
        for (final lm in hand.landmarks) {
          final triple = [lm.x, lm.y, lm.z];
          if (hand.handedness == 'Left') {
            left.add(triple);
          } else if (hand.handedness == 'Right') {
            right.add(triple);
          }
        }
      }
    }
    return {'leftHand': left, 'rightHand': right};
  }
}
