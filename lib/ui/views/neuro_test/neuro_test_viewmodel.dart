import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'steps/step_1.dart';
import 'steps/step_2.dart';
import 'steps/step_3.dart';

class NeuroTestViewModel extends BaseViewModel {
  int _currentStep = 0;
  int totalMocaScore = 0;
  late List<Widget> _steps;

  // ✅ Constructor: define the steps
  NeuroTestViewModel() {
    _steps = [
      NeuroStep1(
        onNext: nextStep,
        onScored: (score) {
          totalMocaScore += score;
          
        },
      ),
      NeuroStep2(onNext: nextStep,onScored: (score) {
          totalMocaScore += score;
        },),
      NeuroStep3(onNext: nextStep,onScored: (score) {
          totalMocaScore += score;
        },),
      // Add more here...
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
      // End of test
      print('Test complete!');
    }
  }
}
