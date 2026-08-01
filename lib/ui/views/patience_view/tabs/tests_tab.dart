import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/test_result.dart';
import '../../../../models/test_type.dart';
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
              onPressed: () => _onSendResultsPressed(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openTest(BuildContext context, TestType type) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await type.open(context, viewModel);

    // Only the camera test reports a failure this way: false means it never
    // saw a hand, so there is nothing to score.
    if (context.mounted && result == false) {
      AppFeedback.error(context, l10n.noHandsDetected);
    }
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

    if (viewModel.results.isEmpty) {
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
