import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../services/test_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';

import 'steps/draw_cube.dart';
import 'steps/connect_cube.dart';
import 'steps/clock.dart';
import 'steps/naming.dart';
import 'steps/digits_forward.dart';
import 'steps/digits_backward.dart';
import 'steps/repeat_sentences.dart';
import 'steps/vigilance.dart';
import 'steps/subtract.dart';
import 'steps/similarities.dart';
import 'steps/orientation.dart';
import 'steps/fluency.dart';
import 'steps/trails.dart';
import 'steps/immediate_recall.dart';
import 'steps/delayed_recall.dart';
import '../../../models/test_score_interpretation.dart';
import '../test_complete/test_complete_view.dart';

class NeuroTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();

  int _currentStep = 0;
  double totalMocaScore = 0.0;
  bool hasStarted = false;
  bool isFinishing = false;
  bool showResults = false;
  bool resultSaved = false;
  double resultConcern = 0;
  late List<Widget> _steps;
  List<String> _immediateAnswers = [];

  // ✅ Constructor: define the steps
  NeuroTestViewModel() {
    _steps = [
      // Define the steps for the MoCA test
      // Each step is a widget that can handle scoring and navigation
      DigitsForwardStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      DigitsBackwardStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      ImmediateRecallStep(
        onFinished: (resp,__) {
          _immediateAnswers = resp;
          nextStep();
        },
      ),
      VigilanceStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      SubtractStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      SimilaritiesStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      OrientationStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      TrailsStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      ClockStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      NamingStep(        
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      FluencyStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      RepeatSentencesStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      DelayedRecallStep(
        onFinished: (score, result) {
          totalMocaScore += score.toDouble();
          nextStep();
        },
        immediateTrials: _immediateAnswers,
      ),
      DrawCubeStep(onNext: nextStep,onScored: (score) {
          totalMocaScore += score;
        },),
      ConnectCubeStep(onNext: nextStep,onScored: (score) {
          totalMocaScore += score;
        },),
    ];
  }

  // ✅ Getter to expose current step
  Widget get currentStepWidget => _steps[_currentStep];

  /// 1-based position and length of the battery, for the progress indicator.
  int get currentStepNumber => _currentStep + 1;
  int get stepCount => _steps.length;

  void startTest() {
    hasStarted = true;
    notifyListeners();
  }

  // ✅ Move to the next step
  void nextStep() {
    if (_currentStep < _steps.length - 1) {
      _currentStep++;
      notifyListeners();
    } else {
      // End of test: persist the result and leave the test flow.
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    if (isFinishing || showResults) return;
    isFinishing = true;
    notifyListeners();
    final uid = _auth.currentUser?.uid;
    // Stored as concern, like every other test: 0 is the best possible
    // result, 1 the most concerning. The MoCA's own scale is kept in `data`
    // and shown to the patient, but the stored score no longer runs backwards
    // relative to the sensor tests.
    final double performance = (totalMocaScore / 30.0).clamp(0.0, 1.0);
    final double concern =
        TestScoreInterpretation.concernFromNative(TestType.neuro, performance);
    bool saved = false;

    if (uid != null) {
      try {
        final result = TestResult(
          id: '',
          patientId: uid,
          type: TestType.neuro,
          performedAt: DateTime.now(),
          score: concern,
          data: {'mocaScore': totalMocaScore, 'mocaMax': 30},
        );
        await _tests.addResult(result: result);
        saved = true;
      } catch (e) {
        // Getting the user out of the finished test matters more than the
        // write succeeding, so a failure here must not block the navigation.
        debugPrint('Could not save neuro result: $e');
      }
    }

    resultConcern = concern;
    resultSaved = saved;
    isFinishing = false;
    showResults = true;
    notifyListeners();
  }

  String get scoreDetail =>
      '${totalMocaScore.toStringAsFixed(totalMocaScore.truncateToDouble() == totalMocaScore ? 0 : 1)} / 30';

  Future<void> continueToCompletion() => showTestComplete(
        type: TestType.neuro,
        concern: resultConcern,
        detail: scoreDetail,
        saved: resultSaved,
      );
}
