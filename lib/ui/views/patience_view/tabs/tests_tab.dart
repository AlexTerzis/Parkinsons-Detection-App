import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/test_result.dart';
import '../../../../models/test_type.dart';
import '../../../../services/test_series_analysis.dart';
import '../../../common/widgets/widgets.dart';
import '../../patience/patience_viewmodel.dart';
import '../test_catalogue.dart';
import '../widgets/doctor_picker_sheet.dart';

/// Lists the available tests and the action for sending results on.
class TestsTab extends StatelessWidget {
  const TestsTab({super.key, required this.viewModel});

  final PatienceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: orderedTestTypes.length,
              separatorBuilder: (_, __) => const AppGap.sm(),
              itemBuilder: (context, index) {
                final type = orderedTestTypes[index];
                return AppTileCard(
                  icon: type.icon,
                  title: type.label(l10n),
                  trailing: _completionMarker(context, type),
                  onTap: () => _openTest(context, type),
                );
              },
            ),
          ),
          // Hidden for guests. This is a second, independent entry point into
          // the same flow as the Doctor tab, so hiding that tab alone would
          // leave it reachable.
          if (!viewModel.isGuest) ...[
            const AppGap.sm(),
            PrimaryAction(
              label: l10n.sendResultsToDoctor,
              icon: Icons.send,
              // Scoped to the send, so the progress shows on the button the
              // patient pressed instead of blanking the screen they are on.
              busy: viewModel.isSendingResults,
              onPressed: () => _onSendResultsPressed(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openTest(BuildContext context, TestType type) async {
    if (!await _confirmRepeat(context, type)) return;
    if (!context.mounted) return;

    await type.open(context, viewModel);

    // The camera test used to resolve `false` for "never saw a hand", which
    // this turned into a snackbar after the screen had already closed. It now
    // ends on its own results screen, which reports what was and was not
    // measured while the patient is still there to read it — and can offer the
    // test again, which a snackbar could not.
  }

  /// Asks before repeating one of the baseline assessments.
  ///
  /// Discouraged, not blocked. Repeating the same MoCA or FAB form inflates the
  /// score — the word list, the animals and the Luria sequences are all
  /// remembered — so a patient can appear to improve cognitively while
  /// declining. That is worth saying out loud, but it is not worth taking the
  /// decision away: a first attempt interrupted halfway, or a year having
  /// passed, are both good reasons to go again.
  ///
  /// Returns true when the test should open.
  Future<bool> _confirmRepeat(BuildContext context, TestType type) async {
    if (!TestSeriesAnalysis.isBaseline(type)) return true;

    final previous = viewModel.results
        .where((r) => r.type == type)
        .fold<TestResult?>(
          null,
          (latest, r) => latest == null || r.performedAt.isAfter(latest.performedAt)
              ? r
              : latest,
        );
    if (previous == null) return true;

    final l10n = AppLocalizations.of(context)!;
    final taken = MaterialLocalizations.of(context)
        .formatMediumDate(previous.performedAt.toLocal());

    final again = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.repeatTestTitle(type.label(l10n))),
        content: Text(
          '${l10n.repeatTestTakenOn(taken)}\n\n'
          // The reason differs: the batteries are distorted by familiarity,
          // the questionnaire simply has not had time to change.
          '${type == TestType.questionnaire ? l10n.repeatQuestionnaireBody : l10n.repeatBatteryBody}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.repeatTestConfirm),
          ),
        ],
      ),
    );
    return again ?? false;
  }

  /// The date a test was last completed, or a chevron if it never has been.
  Widget _completionMarker(BuildContext context, TestType type) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);

    final matched = viewModel.results.firstWhere(
      (r) => r.type == type,
      orElse: () => TestResult(
        id: '',
        patientId: '',
        type: type,
        performedAt: DateTime(0),
        score: 0,
      ),
    );

    if (matched.performedAt.year == 0) {
      return const Icon(Icons.chevron_right);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon plus colour, never colour alone: red/green deficiency is
        // common enough that hue cannot be the only signal.
        Icon(Icons.check_circle, color: semantic.success),
        Text(
          '${matched.performedAt.month}/${matched.performedAt.day}',
          style: theme.textTheme.labelMedium,
        ),
      ],
    );
  }

  void _onSendResultsPressed(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (viewModel.clinicalResults.isEmpty) {
      AppFeedback.info(context, l10n.completeOneTest);
      return;
    }

    showDoctorPicker(
      context,
      viewModel,
      onSelect: (doctor) => viewModel.sendResultsToDoctor(doctor.uid),
      confirmationMessage: (doctor) =>
          l10n.resultsSentTo(doctor.name ?? doctor.email),
    );
  }
}
