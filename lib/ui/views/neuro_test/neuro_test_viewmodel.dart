import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'steps/gestures.dart';
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

class NeuroTestViewModel extends BaseViewModel {
  int _currentStep = 0;
  double totalMocaScore = 0.0;
  late List<Widget> _steps;
  List<String> _immediateAnswers = [];

  // ✅ Constructor: define the steps
  NeuroTestViewModel() {
    _steps = [
      
      DigitsForwardStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
      ),
      DigitsBackwardStep(
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,
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
      GesturesStep(        
        onNext: nextStep,
        onScored: (score) => totalMocaScore += score,),
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
      ImmediateRecallStep(
        onFinished: (resp,__) {
          _immediateAnswers = resp;
          nextStep();
        },
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

  // ✅ Move to the next step
  void nextStep() {
    if (_currentStep < _steps.length - 1) {
      _currentStep++;
      print('Total MoCA Score: $totalMocaScore');
      notifyListeners();
    } else {
      // End of test
      print('Test complete!');
      
      print('Total MoCA Score: $totalMocaScore');
    }
  }
}
