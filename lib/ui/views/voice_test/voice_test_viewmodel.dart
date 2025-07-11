import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../../../services/authentication_service.dart';
import '../../../services/test_service.dart';
import '../../../services/voice_predictor.dart';

/// ViewModel controlling the 5-second voice recording and analysis.
class VoiceTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  final VoicePredictor _predictor = VoicePredictor();
  final AudioRecorder _recorder = AudioRecorder();

  int secondsLeft = 0;
  bool isRecording = false;
  String status = 'Press start to begin';
  Timer? _timer;
  String _result = '';

  String get result => _result;

  double get progress => secondsLeft / 5.0;

  Future<void> startTest() async {
  if (isRecording) return;

  final hasPermission = await _recorder.hasPermission();
  if (!hasPermission) {
    status = 'Microphone permission denied';
    notifyListeners();
    return;
  }

  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/voice_test.wav';

  final config = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 44100,
    bitRate: 128000,
  );

  await _recorder.start(config, path: path);

  secondsLeft = 5;
  isRecording = true;
  status = 'Recording...';
  notifyListeners();

  _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
    secondsLeft--;
    notifyListeners();
    if (secondsLeft <= 0) {
      await stopTest();
    }
  });
}


  /// Stops the recording and runs prediction
  Future<void> stopTest() async {
  if (!isRecording) return;

  _timer?.cancel();
  final path = await _recorder.stop(); // Returns the path to recorded file
  isRecording = false;
  status = 'Processing...';
  notifyListeners();

  if (path != null) {
    final healthyScore = await _predictor.predict(File(path)); // model gives probability of healthy
    final pdScore = 1.0 - healthyScore; // inverse is Parkinson's likelihood

    _result = (pdScore * 100).toStringAsFixed(1);

    status = pdScore >= 0.5
        ? '⚠️ Possible Parkinson pattern ($_result%)'
        : '✅ Normal voice ($_result%)';

    notifyListeners();
    await _saveResult(pdScore); // save Parkinson's probability
  } else {
    status = 'Recording failed';
    notifyListeners();
  }
}


  /// Saves the test result to Firebase
  Future<void> _saveResult(double score) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.voice,
      performedAt: DateTime.now(),
      score: score.clamp(0, 1),
    );

    await _tests.addResult(result);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
