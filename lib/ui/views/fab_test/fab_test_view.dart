import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../common/widgets/widgets.dart';
import 'fab_test_viewmodel.dart';

/// Host for the FAB battery. Owns nothing but the step frame: each step
/// supplies its own [TestStepScaffold].
class FABTestView extends StatelessWidget {
  const FABTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<FABTestViewModel>.reactive(
      viewModelBuilder: () => FABTestViewModel(),
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
