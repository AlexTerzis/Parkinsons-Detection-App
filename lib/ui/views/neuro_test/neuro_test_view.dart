import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../common/widgets/widgets.dart';
import 'neuro_test_viewmodel.dart';

/// Host for the MoCA battery. Owns nothing but the step frame: each step
/// supplies its own [TestStepScaffold].
class NeuroTestView extends StatelessWidget {
  const NeuroTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<NeuroTestViewModel>.reactive(
      viewModelBuilder: () => NeuroTestViewModel(),
      builder: (context, model, child) {
        return TestStepProgress(
          index: model.currentStepNumber,
          count: model.stepCount,
          child: model.currentStepWidget,
        );
      },
    );
  }
}
