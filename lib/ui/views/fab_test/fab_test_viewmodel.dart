import 'package:flutter/material.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/similarities.dart';
import 'package:stacked/stacked.dart';

import 'package:parkinsondetetion/ui/views/fab_test/steps/conflicting_instructions.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/fluency.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/gestures.dart';
import 'package:parkinsondetetion/ui/views/fab_test/steps/go_no_go.dart';


class FABTestViewModel extends BaseViewModel {
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
      print('Total FAB Score: $totalFABScore');
      notifyListeners();
    } else {
      // End of test
      print('Test complete!');
      
      print('Total FAB Score: $totalFABScore');
    }
  }
}
