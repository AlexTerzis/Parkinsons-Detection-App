import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/raison_result.dart';
import '../../../common/widgets/widgets.dart';

/// Reasoning output and analytics summaries.
class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key, required this.resultsFuture});

  final Future<List<RaisonResult>>? resultsFuture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _summaryCard(
          context,
          leading: const Text('🧠', style: TextStyle(fontSize: 28)),
          title: l10n.aiSummaryTitle,
          body: l10n.aiSummarySubtitle,
        ),
        const AppGap.sm(),
        _summaryCard(
          context,
          title: l10n.testBreakdownTitle,
          body: l10n.testBreakdownSubtitle,
        ),
        const AppGap.sm(),
        _summaryCard(
          context,
          title: l10n.riskAlertsTitle,
          body: l10n.noAlertsSubtitle,
        ),
        const AppGap.sm(),
        _argumentation(context),
        const AppGap.sm(),
        _summaryCard(
          context,
          title: l10n.aiSuggestionsTitle,
          body: l10n.retakeTremorSuggestion,
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    required String body,
    Widget? leading,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading,
            const AppGap.wide(AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const AppGap.xxs(),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The reasoning engine's conclusions, once they resolve.
  Widget _argumentation(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<RaisonResult>>(
      future: resultsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _summaryCard(
            context,
            title: l10n.argumentation,
            body: l10n.noArgumentationYet,
          );
        }
        if (!snapshot.hasData) {
          return _summaryCard(
            context,
            title: l10n.argumentation,
            body: l10n.loadingReasoning,
          );
        }

        final results = snapshot.data!;
        if (results.isEmpty) {
          return _summaryCard(
            context,
            title: l10n.argumentation,
            body: l10n.takeQuestionnairePrompt,
          );
        }

        final solutions =
            results.where((r) => r.isSolution).toList(growable: false);
        if (solutions.isEmpty) {
          return _summaryCard(
            context,
            title: l10n.argumentation,
            body: l10n.noArgumentationYet,
          );
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.argumentation, style: theme.textTheme.titleMedium),
              const AppGap.xs(),
              for (final r in solutions) ...[
                Text(r.label, style: theme.textTheme.titleSmall),
                const AppGap.xxs(),
                for (final e in r.explanation)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      bottom: AppSpacing.xxs,
                    ),
                    child: Text('• $e', style: theme.textTheme.bodyMedium),
                  ),
                const AppGap.sm(),
              ],
            ],
          ),
        );
      },
    );
  }
}
