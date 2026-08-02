import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';
import '../../patience/patience_viewmodel.dart';
import '../widgets/score_charts.dart';

/// Historical scores and trends, per test and overall.
class ResultsTab extends StatelessWidget {
  const ResultsTab({super.key, required this.viewModel});

  final PatienceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grouped = viewModel.groupedResults;

    if (grouped.isEmpty) {
      return AppEmptyState(
        icon: Icons.insights_outlined,
        title: l10n.testResults,
        message: l10n.completeOneTest,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SectionHeader(l10n.testResults),
        for (final entry in grouped.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _testCard(
              context,
              label: viewModel.labelForType(entry.key),
              points: entry.value
                  .map((e) => ScorePoint(e.performedAt, e.concernScore))
                  .toList(),
            ),
          ),
        const AppGap.lg(),
        SectionHeader(l10n.summary),
        if (viewModel.resultsSummary.length >= 3)
          ScoreRadarChart(scores: viewModel.resultsSummary)
        else
          Text(
            l10n.needThreeTests,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        if (viewModel.results.isNotEmpty) ...[
          const AppGap.lg(),
          Align(
            alignment: Alignment.centerLeft,
            child: DropdownButton<int>(
              value: viewModel.selectedAverageWindow,
              items: const [3, 7, 14, 30]
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(l10n.days(d)),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) viewModel.updateAverageWindow(val);
              },
            ),
          ),
          const AppGap.xs(),
          ScoreTrendChart(
            spots: viewModel.getAverageTrend(),
            curved: true,
            filled: true,
          ),
        ],
      ],
    );
  }

  /// One test's latest score, with its history behind a disclosure.
  Widget _testCard(
    BuildContext context, {
    required String label,
    required List<ScorePoint> points,
  }) {
    final latest = points.first.score;

    return Card(
      child: ExpansionTile(
        title: ScoreBar(label: label, value: latest),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        children: [
          ScoreTrendChart(
            spots: spotsFromNewestFirst(points),
            labelAt: (index) {
              if (index < 0 || index >= points.length) return '';
              final dt = points[points.length - 1 - index].time;
              return '${dt.month}/${dt.day}';
            },
          ),
        ],
      ),
    );
  }
}
