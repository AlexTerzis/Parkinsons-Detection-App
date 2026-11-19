import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../../models/hand_posture.dart';
import '../../../models/posture_test_result.dart';
import '../../common/widgets/widgets.dart';
import 'posture_test_view.dart' show PostureGlyph;
import 'posture_test_viewmodel.dart';

/// What the patient sees after copying the postures.
///
/// Leads with the count copied and how well the run was recorded. There is no
/// interpretation of what a given total means: the instrument this is modelled
/// on is scored by a trained examiner against paediatric norms, and an
/// automated version has none to appeal to, so a band or a verdict here would
/// be inventing one.
class PostureResultView extends StatelessWidget {
  const PostureResultView({super.key, required this.viewModel});

  final PostureTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final result = viewModel.result;

    return AppScaffold(
      title: l10n.postureResultsTitle,
      showBackButton: false,
      bottomAction: PrimaryAction(
        label: l10n.postureNext,
        icon: Icons.arrow_forward,
        onPressed: viewModel.finishFromResults,
      ),
      body: result == null || !result.hasUsableRecording
          ? _nothingRecorded(context, l10n)
          : _results(context, l10n, theme, result),
    );
  }

  Widget _nothingRecorded(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.videocam_off_outlined,
                  color: theme.colorScheme.onSurfaceVariant),
              const AppGap.wide(AppSpacing.sm),
              Expanded(child: Text(l10n.postureNothingRecorded)),
            ],
          ),
        ),
        const AppGap.md(),
        OutlinedButton.icon(
          onPressed: viewModel.repeatTest,
          icon: const Icon(Icons.replay),
          label: Text(l10n.postureRepeat),
        ),
      ],
    );
  }

  Widget _results(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    PostureTestResult result,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.postureScore(result.points, result.maximumPoints),
                style: theme.textTheme.headlineMedium,
              ),
              const AppGap.sm(),
              Row(
                children: [
                  Expanded(child: Text(l10n.postureQuality)),
                  Text(
                    '${(result.recordingQuality * 100).round()}%',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
              if (result.unrecordedItems.isNotEmpty) ...[
                const AppGap.sm(),
                // Said explicitly, because these items scored zero without the
                // patient having got anything wrong.
                Text(
                  l10n.postureUnrecordedNote(result.unrecordedItems.length),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const AppGap.sm(),
              Row(
                children: [
                  Icon(
                    viewModel.resultSaved
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const AppGap.wide(AppSpacing.xs),
                  Expanded(
                    child: Text(
                      viewModel.resultSaved
                          ? l10n.postureSaved
                          : l10n.postureNotSaved,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const AppGap.md(),
        for (final item in result.items) _itemRow(context, l10n, theme, item),
        const AppGap.md(),
        OutlinedButton.icon(
          onPressed: viewModel.repeatTest,
          icon: const Icon(Icons.replay),
          label: Text(l10n.postureRepeat),
        ),
      ],
    );
  }

  Widget _itemRow(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    PostureItemResult item,
  ) {
    final posture = HandPostures.all.firstWhere(
      (p) => p.id == item.postureId,
      orElse: () => HandPostures.point,
    );

    final (String label, IconData icon) = switch ((
      item.copiedOnTrial,
      item.neverRecorded,
    )) {
      (1, _) => (l10n.postureCopiedFirst, Icons.check_circle_outline),
      (2, _) => (l10n.postureCopiedSecond, Icons.check_circle_outline),
      // A zero that came from never seeing the hand is reported as exactly
      // that, never as a failure to copy the shape.
      (null, true) => (l10n.postureNotRecorded, Icons.videocam_off_outlined),
      _ => (l10n.postureNotCopied, Icons.remove_circle_outline),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        child: Row(
          children: [
            PostureGlyph(posture: posture, size: 34),
            const AppGap.wide(AppSpacing.md),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
            const AppGap.wide(AppSpacing.sm),
            Text('${item.points}', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
