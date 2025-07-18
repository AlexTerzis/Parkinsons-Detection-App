import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'questionnaire_viewmodel.dart';
import 'questionnaire_form.dart';

/// View containing the [QuestionnaireForm].
class QuestionnaireView extends StackedView<QuestionnaireViewModel> {
  const QuestionnaireView({super.key});

  @override
  Widget builder(
    BuildContext context,
    QuestionnaireViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      
      body: QuestionnaireForm(onSubmit: viewModel.submitQuestionnaire),
    );
  }

  @override
  QuestionnaireViewModel viewModelBuilder(BuildContext context) =>
      QuestionnaireViewModel();
}