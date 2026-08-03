import 'package:flutter/material.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/similarities.dart';
import 'package:stacked/stacked.dart';

import 'package:parkinsondetetion/ui/views/fab_test/steps/conflicting_instructions.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/fluency.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/gestures.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/go_no_go.dart';

import '../../../app/app.locator.dart';
import '../../../services/test_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../../../models/test_score_interpretation.dart';
import '../test_complete/test_complete_view.dart';

class FABTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();

  int _currentStep = 0;
  double totalFABScore = 0.0;
  bool hasStarted = false;
  bool isFinishing = false;
  bool showResults = false;
  bool resultSaved = false;
  double resultConcern = 0;
  late List<Widget> _steps;

  // ✅ Constructor: define the steps
  FABTestViewModel() {
    _steps = [
      // Define the steps for the FAB test
      GoNoGoStep(
        onNext: nextStep,
        onScored: (score) => totalFABScore += score,
      ),
      ConflictingInstructionsStep(
        onNext: nextStep,
        onScored: (score) => totalFABScore += score,
      ),
      FluencyStep(
        onNext: nextStep, 
        onScored: (score) => totalFABScore += score
        ),
      SimilaritiesStep(
        onNext: nextStep, 
        onScored: (score) => totalFABScore += score
        ),
      GesturesStep(
        onNext: nextStep, 
        onScored: (score) => totalFABScore += score
        ),
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
    // Stored as concern so it runs the same way as every other test; the
    // FAB's own scale stays in `data` and on screen.
    final double performance = (totalFABScore / 15.0).clamp(0.0, 1.0);
    final double concern =
        TestScoreInterpretation.concernFromNative(TestType.fab, performance);
    bool saved = false;

    if (uid != null) {
      try {
        final result = TestResult(
          id: '',
          patientId: uid,
          type: TestType.fab,
          performedAt: DateTime.now(),
          score: concern,
          data: {'fabScore': totalFABScore, 'fabMax': 15},
        );
        await _tests.addResult(result: result);
        saved = true;
      } catch (e) {
        // Getting the user out of the finished test matters more than the
        // write succeeding, so never let a failure here block the result
        // screen below.
        debugPrint('Could not save FAB result: $e');
      }
    }

    resultConcern = concern;
    resultSaved = saved;
    isFinishing = false;
    showResults = true;
    notifyListeners();
  }

  String get scoreDetail =>
      '${totalFABScore.toStringAsFixed(totalFABScore.truncateToDouble() == totalFABScore ? 0 : 1)} / 15';

  Future<void> continueToCompletion() => showTestComplete(
        type: TestType.fab,
        concern: resultConcern,
        detail: scoreDetail,
        saved: resultSaved,
      );
}
