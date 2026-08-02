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
import '../test_complete/test_complete_view.dart';

class FABTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();

  int _currentStep = 0;
  double totalFABScore = 0.0;
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
    final uid = _auth.currentUser?.uid;
    final double normalised = (totalFABScore / 15.0).clamp(0.0, 1.0);
    bool saved = false;

    if (uid != null) {
      try {
        final result = TestResult(
          id: '',
          patientId: uid,
          type: TestType.fab,
          performedAt: DateTime.now(),
          score: normalised,
          data: {'fabScore': totalFABScore},
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

    // Out of 15, matching the five items this app implements rather than the
    // clinical FAB's six, so the number shown is the one that was measured.
    await showTestComplete(
      type: TestType.fab,
      score: normalised,
      detail: '${totalFABScore.toStringAsFixed(totalFABScore.truncateToDouble() == totalFABScore ? 0 : 1)} / 15',
      saved: saved,
    );
  }
}
