import 'package:flutter/material.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/similarities.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import 'package:parkinsondetetion/ui/views/fab_test/steps/conflicting_instructions.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/fluency.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/gestures.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/go_no_go.dart';

import '../../../app/app.locator.dart';
import '../../../services/test_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';

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
    if (uid == null) return;

    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.fab,
      performedAt: DateTime.now(),
      score: (totalFABScore / 15.0).clamp(0.0, 1.0),
      data: {'fabScore': totalFABScore},
    );
    await _tests.addResult(result: result);
    locator<NavigationService>().back();
  }
}
