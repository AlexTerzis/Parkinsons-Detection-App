import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'steps/step_1.dart';
import 'steps/step_2.dart';
import 'steps/step_3.dart';
import 'steps/step_4.dart';
import 'steps/step_5.dart';
import 'steps/step_6.dart';
import 'steps/step_7.dart';
import 'steps/step_8.dart';
import 'steps/step_9.dart';
import 'steps/step_10.dart';
import 'steps/step_11.dart';
import 'steps/step_12.dart';

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
      NeuroStep4(
        onNext: nextStep,
        onScored: (num score) {
          totalMocaScore += score.toInt(); // or however you wish to handle it
        },
      ),
      NeuroStep5(
        onNext: nextStep,
        onScored: (num score) {
          totalMocaScore += score.toInt(); // or however you wish to handle it
        },
      ),
      NeuroStep6(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      NeuroStep7(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      NeuroStep8(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      NeuroStep9(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      NeuroStep10(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      NeuroStep11(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      
      NeuroStep12(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
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
      // End of test
      print('Test complete!');
    }
  }
}
