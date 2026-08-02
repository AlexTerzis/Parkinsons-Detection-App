import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:stacked/stacked.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../../app/app.locator.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../../../services/authentication_service.dart';
import '../../../services/test_service.dart';
import '../../../services/voice_api_service.dart';
import 'package:flutter/foundation.dart';
import '../test_complete/test_complete_view.dart';

enum VoiceStatus {
  initial,
  permissionDenied,
  recording,
  processing,
  resultWarning,
  resultNormal,
  recordingFailed,
}

/// ViewModel controlling the 5-second voice recording and analysis.
class VoiceTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  // Handles network calls to the Python model
  final VoiceApiService _api = locator<VoiceApiService>();
  final AudioRecorder _recorder = AudioRecorder();

  int secondsLeft = 0;
  bool isRecording = false;
  VoiceStatus status = VoiceStatus.initial;
  Timer? _timer;
  String _result = '';

  String get result => _result;

  double get progress => secondsLeft / 5.0;

  String statusText(AppLocalizations l10n) {
    switch (status) {
      case VoiceStatus.initial:
        return l10n.pressStart;
      case VoiceStatus.permissionDenied:
        return l10n.microphonePermissionDenied;
      case VoiceStatus.recording:
        return l10n.recording;
      case VoiceStatus.processing:
        return l10n.processing;
      case VoiceStatus.resultWarning:
        return l10n.possibleParkinson(_result);
      case VoiceStatus.resultNormal:
        return l10n.normalVoice(_result);
      case VoiceStatus.recordingFailed:
        return l10n.recordingFailed;
    }
  }

  Future<void> startTest() async {
    if (isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      status = VoiceStatus.permissionDenied;
      notifyListeners();
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_test.wav';

    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 44100,
      bitRate: 128000,
    );

    await _recorder.start(config, path: path);

    secondsLeft = 5;
    isRecording = true;
    status = VoiceStatus.recording;
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
    status = VoiceStatus.processing;
    notifyListeners();

    if (path != null) {
      // Send the audio to the backend and retrieve the PD probability
      final wavFile = File(path);
      final pdScore = await _api.predict(wavFile);

      _result = (pdScore * 100).toStringAsFixed(1);

      status = pdScore >= 0.5
          ? VoiceStatus.resultWarning
          : VoiceStatus.resultNormal;

      notifyListeners();
      await _saveResult(pdScore, wavFile); // persist probability and audio
    } else {
      status = VoiceStatus.recordingFailed;
      notifyListeners();
    }
  }

  /// Saves the test result to Firebase
  Future<void> _saveResult(double score, File wavFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.voice,
      performedAt: DateTime.now(),
      score: score.clamp(0, 1),
    );

    // The result screen reports whether the save worked rather than implying
    // success, and a failed upload must never strand the patient here.
    bool saved = true;
    try {
      await _tests.addResult(result: result, audioWav: wavFile);
    } catch (e) {
      saved = false;
      debugPrint('Could not save voice result: $e');
    }

    await showTestComplete(
      type: TestType.voice,
      score: result.score,
      saved: saved,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}