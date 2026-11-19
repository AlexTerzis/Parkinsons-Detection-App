import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../models/test_type.dart';
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
      body: QuestionnaireForm(
        onSubmit: (responses) => _submit(context, viewModel, responses),
      ),
    );
  }

  /// Submits the answers, first offering the cognitive tests the patient has
  /// not taken, because the reasoning can use their results as well.
  Future<void> _submit(
    BuildContext context,
    QuestionnaireViewModel viewModel,
    Map<String, dynamic> responses,
  ) async {
    final missing = await viewModel.missingCognitiveTests();
    var testsFirst = false;
    if (missing.isNotEmpty && context.mounted) {
      testsFirst = await _askTestsFirst(context, missing) ?? false;
    }
    await viewModel.submitQuestionnaire(responses, testsFirst: testsFirst);
  }

  Future<bool?> _askTestsFirst(BuildContext context, List<TestType> missing) {
    final greek = Localizations.localeOf(context).languageCode == 'el';
    String t(String english, String greekText) => greek ? greekText : english;
    final names = [
      if (missing.contains(TestType.neuro))
        t('the cognitive test (MoCA-based)', 'το νευροψυχολογικό τεστ (MoCA)'),
      if (missing.contains(TestType.fab)) t('the FAB test', 'το τεστ FAB'),
    ].join(t(' and ', ' και '));

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('Add the cognitive tests?',
            'Να προστεθούν τα γνωστικά τεστ;')),
        content: Text(t(
          'The advice can also take into account your results in $names, '
              'which you have not taken yet. You can take them now and see '
              'the advice afterwards, or see the advice now from the '
              'questionnaire alone. Your answers are saved either way.',
          'Η σύσταση μπορεί να λάβει υπόψη και τα αποτελέσματά σας σε $names, '
              'που δεν έχετε κάνει ακόμη. Μπορείτε να τα κάνετε τώρα και να '
              'δείτε τη σύσταση μετά, ή να δείτε τη σύσταση τώρα μόνο από το '
              'ερωτηματολόγιο. Οι απαντήσεις σας αποθηκεύονται σε κάθε '
              'περίπτωση.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t('See the advice now', 'Σύσταση τώρα')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t('Take the tests first', 'Πρώτα τα τεστ')),
          ),
        ],
      ),
    );
  }

  @override
  QuestionnaireViewModel viewModelBuilder(BuildContext context) =>
      QuestionnaireViewModel();
}
