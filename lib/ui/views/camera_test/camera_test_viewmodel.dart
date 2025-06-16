import 'dart:async';
import 'dart:math' as math;

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

  int countdown = 29;
  late Timer _timer;
  final List<FrameData> _frames = [];
  bool _handsDetected = false;

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

    final Map<String, dynamic> metrics = _analyzeFrames();
    final double score = metrics['parkinson_probability'] as double;

    final result = TestResult(
      id: '',
      patientId: _auth.currentUser!.uid,
      type: TestType.cameraDetection,
      performedAt: DateTime.now(),
      score: score,
      data: metrics,
    );

    await _tests.addResult(result);
    setBusy(false);
    locator<NavigationService>().back(result: true);
  }

  Map<String, dynamic> _analyzeFrames() {
    // Prepare data structures for 21 landmarks for each hand over all frames
    final leftHandLandmarks = List.generate(21, (_) => <Map<String, double>>[]);
    final rightHandLandmarks = List.generate(21, (_) => <Map<String, double>>[]);

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

    double speedVarL = _computeSpeedVariance3D(leftHandLandmarks);
    double speedVarR = _computeSpeedVariance3D(rightHandLandmarks);

    double tremorL = _computeTremor3D(leftHandLandmarks);
    double tremorR = _computeTremor3D(rightHandLandmarks);

    double asymmetry = (speedVarL - speedVarR).abs();

    final double probability = ((speedVarL + speedVarR) / 2 * 0.4) +
        ((tremorL + tremorR) / 2 * 0.4) +
        (asymmetry * 0.2);

    return {
      'frames': _frames.length,
      'hands_detected_frames': _frames.where((f) => f.hands.isNotEmpty).length,
      'speed_variance_left': speedVarL,
      'speed_variance_right': speedVarR,
      'tremor_left': tremorL,
      'tremor_right': tremorR,
      'asymmetry': asymmetry,
      'parkinson_probability': probability.clamp(0, 1),
    };
  }

  // 3D distance between two points
  double _distance3D(Map<String, double> a, Map<String, double> b) {
    final dx = (a['x'] ?? 0) - (b['x'] ?? 0);
    final dy = (a['y'] ?? 0) - (b['y'] ?? 0);
    final dz = (a['z'] ?? 0) - (b['z'] ?? 0);
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  // Compute speed variance across all landmarks in 3D
  double _computeSpeedVariance3D(List<List<Map<String, double>>> landmarks) {
    List<double> allDisplacements = [];

    for (final positions in landmarks) {
      if (positions.length < 2) continue;
      for (int i = 1; i < positions.length; i++) {
        allDisplacements.add(_distance3D(positions[i], positions[i - 1]));
      }
    }
    return _variance(allDisplacements) * 10; // scale factor
  }

  // Compute tremor as average standard deviation of x,y,z across all landmarks
  double _computeTremor3D(List<List<Map<String, double>>> landmarks) {
    List<double> stdDevs = [];

    for (final positions in landmarks) {
      if (positions.length < 3) continue;
      final xs = positions.map((p) => p['x'] ?? 0).toList();
      final ys = positions.map((p) => p['y'] ?? 0).toList();
      final zs = positions.map((p) => p['z'] ?? 0).toList();

      final stdX = math.sqrt(_variance(xs));
      final stdY = math.sqrt(_variance(ys));
      final stdZ = math.sqrt(_variance(zs));

      // Average std dev for this landmark
      stdDevs.add((stdX + stdY + stdZ) / 3);
    }

    if (stdDevs.isEmpty) return 0;

    // Average tremor metric over all landmarks
    return stdDevs.reduce((a, b) => a + b) / stdDevs.length;
  }

  // Variance helper
  double _variance(List<double> data) {
    if (data.length < 2) return 0;
    final mean = data.reduce((a, b) => a + b) / data.length;
    final sqSum = data.map((d) => (d - mean) * (d - mean)).reduce((a, b) => a + b);
    return sqSum / data.length;
  }
}
