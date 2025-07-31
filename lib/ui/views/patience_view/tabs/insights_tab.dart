import 'package:flutter/material.dart';

import '../../../../models/raison_result.dart';

/// Shows simple reasoning and analytics placeholders.
class InsightsTab extends StatelessWidget {
  final Future<List<RaisonResult>>? resultsFuture;
  const InsightsTab({super.key, required this.resultsFuture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Text('🧠', style: TextStyle(fontSize: 28)),
            title: const Text('Overall AI Summary'),
            subtitle: const Text('Low risk – more advanced analytics will appear here.'),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text('Test-by-Test Breakdown'),
            subtitle: const Text('Charts of tapping, tremor and other tests will be added.'),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text('Risk Alerts or Anomalies'),
            subtitle: const Text('No alerts detected recently.'),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: FutureBuilder<List<RaisonResult>>(
            future: resultsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(
                  title: Text('Argumentation'),
                  subtitle: Text('Loading reasoning...'),
                );
              }
              final results = snapshot.data!;
              if (results.isEmpty) {
                return const ListTile(
                  title: Text('Argumentation'),
                  subtitle: Text('Take the questionnaire to see the results'),
                );
              }
              final solutions = results.where((r) => r.isSolution).toList(growable: false);
              if (solutions.isEmpty) {
                return const ListTile(
                  title: Text('Argumentation'),
                  subtitle: Text(
                      'Cannot give clear argumentation yet from the questionnaire results. If you have any questions, please contact your doctor.'),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Argumentation', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (final r in solutions) ...[
                      Text(r.label, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      ...r.explanation.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 2),
                          child: Text('• ' + e),
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
            title: const Text('AI Test Suggestions'),
            subtitle: const Text('Please retake the Tremor Test – last result was inconclusive.'),
          ),
        ),
      ],
    );
  }
}
