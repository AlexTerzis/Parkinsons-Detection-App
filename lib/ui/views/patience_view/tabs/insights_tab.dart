import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../../../models/raison_result.dart';

/// Shows simple reasoning and analytics placeholders.
class InsightsTab extends StatelessWidget {
  final Future<List<RaisonResult>>? resultsFuture;
  const InsightsTab({super.key, required this.resultsFuture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Text('🧠', style: TextStyle(fontSize: 28)),
            title: Text(l10n.aiSummaryTitle),
            subtitle: Text(l10n.aiSummarySubtitle),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: Text(l10n.testBreakdownTitle),
            subtitle: Text(l10n.testBreakdownSubtitle),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: Text(l10n.riskAlertsTitle),
            subtitle: Text(l10n.noAlertsSubtitle),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: FutureBuilder<List<RaisonResult>>(
            future: resultsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ListTile(
                  title: Text(l10n.argumentation),
                  subtitle: Text(l10n.loadingReasoning),
                );
              }
              final results = snapshot.data!;
              if (results.isEmpty) {
                return ListTile(
                  title: Text(l10n.argumentation),
                  subtitle: Text(l10n.takeQuestionnairePrompt),
                );
              }
              final solutions = results.where((r) => r.isSolution).toList(growable: false);
              if (solutions.isEmpty) {
                return ListTile(
                  title: Text(l10n.argumentation),
                  subtitle: Text(l10n.noArgumentationYet),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.argumentation, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (final r in solutions) ...[
                      Text(r.label, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      ...r.explanation.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 2),
                          child: Text('• $e'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ]
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: Text(l10n.aiSuggestionsTitle),
            subtitle: Text(l10n.retakeTremorSuggestion),
          ),
        ),
      ],
    );
  }
}
