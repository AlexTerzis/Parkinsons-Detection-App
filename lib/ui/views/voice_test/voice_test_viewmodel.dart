import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../../../services/authentication_service.dart';
import '../../../services/test_service.dart';
import '../../../services/voice_api_service.dart';
import '../test_complete/test_complete_view.dart';

enum VoiceStatus {
  initial,
  permissionDenied,
  countdown,
  recording,
  review,
  processing,
  result,
  recordingFailed,
  processingFailed,
}

enum VoiceRecordingQuality { good, tooShort, tooQuiet, clipped, unstable }

class VoiceTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  final VoiceApiService _api = locator<VoiceApiService>();
  final AudioRecorder _recorder = AudioRecorder();

  static const int recordingSeconds = 5;
  VoiceStatus status = VoiceStatus.initial;
  VoiceRecordingQuality quality = VoiceRecordingQuality.good;
  int secondsLeft = 0;
  int countdownValue = 3;
  bool isRecording = false;
  bool isSavingResult = false;
  bool resultSaved = false;
  double resultScore = 0;
  VoicePrediction? prediction;
  double recordedDuration = 0;
  double volumeLevel = 0;
  final List<double> waveform = [];

  Timer? _timer;
  Timer? _amplitudeTimer;
  final Stopwatch _recordingClock = Stopwatch();
  final List<double> _decibels = [];
  File? _pendingFile;

  double get progress => ((recordingSeconds - secondsLeft) / recordingSeconds)
      .clamp(0, 1)
      .toDouble();
  bool get hasResult => status == VoiceStatus.result;
  bool get canUseRecording => quality == VoiceRecordingQuality.good;
  bool get resultConclusive => prediction?.isUsable ?? false;
  VoiceAcousticAnalysis? get acousticAnalysis => prediction?.acousticAnalysis;
  bool get hasAcousticResult => acousticAnalysis != null;
  double? get experimentalModelScore => prediction?.experimentalModelScore;
  bool get experimentalAboveThreshold =>
      (experimentalModelScore ?? 0) >= resultDecisionThreshold;
  double get resultDecisionThreshold => prediction?.decisionThreshold ?? .7;
  String get resultStatus => prediction?.status ?? 'invalid_response';

  Future<void> startTest() async {
    if (isRecording || status == VoiceStatus.countdown) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      status = VoiceStatus.permissionDenied;
      notifyListeners();
      return;
    }
    await _deletePendingFile();
    status = VoiceStatus.countdown;
    countdownValue = 3;
    waveform.clear();
    notifyListeners();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      countdownValue--;
      notifyListeners();
      if (countdownValue <= 0) {
        timer.cancel();
        await _beginRecording();
      }
    });
  }

  Future<void> _beginRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_test_${DateTime.now().millisecondsSinceEpoch}.wav';
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        bitRate: 128000,
      );
      await _recorder.start(config, path: path);
      _pendingFile = File(path);
      secondsLeft = recordingSeconds;
      isRecording = true;
      status = VoiceStatus.recording;
      _decibels.clear();
      waveform.clear();
      _recordingClock
        ..reset()
        ..start();
      _startAmplitudeSampling();
      notifyListeners();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        secondsLeft--;
        notifyListeners();
        if (secondsLeft <= 0) await stopRecording();
      });
    } catch (error) {
      debugPrint('Could not start voice recording: $error');
      status = VoiceStatus.recordingFailed;
      isRecording = false;
      notifyListeners();
    }
  }

  void _startAmplitudeSampling() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!isRecording) return;
      try {
        final amplitude = await _recorder.getAmplitude();
        final db = amplitude.current.isFinite ? amplitude.current : -160.0;
        _decibels.add(db);
        volumeLevel = ((db + 60) / 60).clamp(0, 1).toDouble();
        waveform.add(volumeLevel);
        if (waveform.length > 50) waveform.removeAt(0);
        notifyListeners();
      } catch (_) {}
    });
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _recordingClock.stop();
    final path = await _recorder.stop();
    isRecording = false;
    recordedDuration = _recordingClock.elapsedMilliseconds / 1000;
    if (path == null) {
      status = VoiceStatus.recordingFailed;
      notifyListeners();
      return;
    }
    _pendingFile = File(path);
    quality = _assessQuality();
    status = VoiceStatus.review;
    notifyListeners();
  }

  VoiceRecordingQuality _assessQuality() {
    if (recordedDuration < 4.5) return VoiceRecordingQuality.tooShort;
    if (_decibels.isEmpty) return VoiceRecordingQuality.tooQuiet;
    final voiced = _decibels.where((db) => db > -45).length / _decibels.length;
    final clipped = _decibels.where((db) => db > -2).length / _decibels.length;
    if (voiced < .55) return VoiceRecordingQuality.tooQuiet;
    if (clipped > .05) return VoiceRecordingQuality.clipped;
    final active = _decibels.where((db) => db > -45).toList();
    if (active.length > 3) {
      final mean = active.reduce((a, b) => a + b) / active.length;
      final deviation = math.sqrt(active
              .map((db) => (db - mean) * (db - mean))
              .reduce((a, b) => a + b) /
          active.length);
      if (deviation > 10) return VoiceRecordingQuality.unstable;
    }
    return VoiceRecordingQuality.good;
  }

  Future<void> recordAgain() async {
    await _deletePendingFile();
    status = VoiceStatus.initial;
    quality = VoiceRecordingQuality.good;
    resultScore = 0;
    resultSaved = false;
    prediction = null;
    volumeLevel = 0;
    waveform.clear();
    notifyListeners();
  }

  Future<void> useRecording() async {
    final file = _pendingFile;
    if (file == null) {
      status = VoiceStatus.recordingFailed;
      notifyListeners();
      return;
    }
    status = VoiceStatus.processing;
    notifyListeners();
    try {
      final outcome =
          await _api.predict(file).timeout(const Duration(seconds: 90));
      prediction = outcome;
      if (outcome.isUsable) {
        resultScore = outcome.screeningScore!;
        await _saveResult(outcome, file);
      } else if (outcome.acousticAnalysis != null &&
          outcome.experimentalModelScore != null) {
        resultScore = outcome.acousticAnalysis!.overallScore;
        await _saveExperimentalResult(outcome);
      } else {
        // Do not insert a neutral or extrapolated score into the patient's
        // history. It would contaminate trends and could look reassuring or
        // concerning even though the model explicitly abstained.
        resultScore = outcome.acousticAnalysis?.overallScore ?? 0;
        resultSaved = false;
        await _deletePendingFile();
      }
      status = VoiceStatus.result;
    } on TimeoutException {
      status = VoiceStatus.processingFailed;
    } catch (error) {
      debugPrint('Voice prediction failed: $error');
      status = VoiceStatus.processingFailed;
    }
    notifyListeners();
  }

  Future<void> retryProcessing() => useRecording();

  Future<void> _saveResult(VoicePrediction outcome, File wavFile) async {
    final uid = _auth.currentUser?.uid;
    final score = outcome.screeningScore!;
    isSavingResult = true;
    notifyListeners();
    final result = TestResult(
      id: '',
      patientId: uid ?? '',
      type: TestType.voice,
      performedAt: DateTime.now(),
      score: score.clamp(0, 1).toDouble(),
      data: {
        'task': 'sustained_a_vowel',
        'durationSeconds': recordedDuration,
        'recordingQuality': quality.name,
        'sampleRateHz': 44100,
        'scoreType': 'research_voice_pattern_score',
        'modelVersion': outcome.modelVersion,
        'validatedForClinicalUse': outcome.validatedForClinicalUse,
        'decisionThreshold': outcome.decisionThreshold,
        'resultStatus': outcome.status,
      },
    );
    var saved = uid != null;
    if (uid != null) {
      try {
        await _tests.addResult(result: result, audioWav: wavFile);
      } catch (error) {
        saved = false;
        debugPrint('Could not save voice result: $error');
      }
    }
    resultSaved = saved;
    isSavingResult = false;
    await _deletePendingFile();
  }

  Future<void> _saveExperimentalResult(VoicePrediction outcome) async {
    final uid = _auth.currentUser?.uid;
    final analysis = outcome.acousticAnalysis!;
    final experimentalScore = outcome.experimentalModelScore!;
    isSavingResult = true;
    notifyListeners();

    final result = TestResult(
      id: '',
      patientId: uid ?? '',
      type: TestType.voice,
      performedAt: DateTime.now(),
      score: experimentalScore,
      data: {
        'task': 'sustained_a_vowel',
        'durationSeconds': recordedDuration,
        'recordingQuality': quality.name,
        'sampleRateHz': 44100,
        'scoreType': 'experimental_voice_pattern_score',
        'displayAsExperimentalPrototype': true,
        'validatedForClinicalUse': false,
        'modelVersion': outcome.modelVersion,
        'decisionThreshold': outcome.decisionThreshold,
        'resultStatus': outcome.status,
        'experimentalModelScore': experimentalScore,
        'experimentalAboveThreshold':
            experimentalScore >= outcome.decisionThreshold,
        'acousticStabilityScore': analysis.overallScore,
        'pitchSteadiness': analysis.pitchSteadiness,
        'amplitudeSteadiness': analysis.amplitudeSteadiness,
        'tonalClarity': analysis.tonalClarity,
        'sustainQuality': analysis.sustainQuality,
        'meanPitchHz': analysis.meanPitchHz,
        'jitterPercent': analysis.jitterPercent,
        'shimmerPercent': analysis.shimmerPercent,
        'hnrDb': analysis.hnrDb,
        'warnings': outcome.warnings,
      },
    );

    var saved = uid != null;
    if (uid != null) {
      try {
        // Save derived prototype metrics only. The WAV remains temporary and
        // is never uploaded to Storage for an unvalidated model result.
        await _tests.addResult(result: result);
      } catch (error) {
        saved = false;
        debugPrint('Could not save experimental voice result: $error');
      }
    }
    resultSaved = saved;
    isSavingResult = false;
    await _deletePendingFile();
  }

  Future<void> continueToCompletion() async {
    if (hasAcousticResult) {
      await showTestComplete(
        type: TestType.voice,
        concern: resultScore.clamp(0, 1).toDouble(),
        saved: resultSaved,
        researchOnly: true,
      );
      return;
    }
    if (!resultConclusive) {
      locator<NavigationService>().back();
      return;
    }
    await showTestComplete(
      type: TestType.voice,
      concern: resultScore.clamp(0, 1).toDouble(),
      saved: resultSaved,
      researchOnly: true,
    );
  }

  Future<void> _deletePendingFile() async {
    final file = _pendingFile;
    _pendingFile = null;
    if (file != null && await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
