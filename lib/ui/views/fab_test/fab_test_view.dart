import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'fab_test_viewmodel.dart';

class FABTestView extends StatelessWidget {
  const FABTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<FABTestViewModel>.reactive(
      viewModelBuilder: () => FABTestViewModel(),
      builder: (context, model, child) {
        return Scaffold(
          body: model.currentStepWidget,
        );
      },
    );
  }
}
