import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'neuro_test_viewmodel.dart';

class NeuroTestView extends StatelessWidget {
  const NeuroTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<NeuroTestViewModel>.reactive(
      viewModelBuilder: () => NeuroTestViewModel(),
      builder: (context, model, child) {
        return Scaffold(
          body: model.currentStepWidget,
        );
      },
    );
  }
}
