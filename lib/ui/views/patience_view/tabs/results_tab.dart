import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/test_score_interpretation.dart';
import '../../../../models/test_type.dart';
import '../../../common/test_type_labels.dart';
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
    final averages = viewModel.averageConcernByType;

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
        SectionHeader(
          l10n.testResults,
          action: AppInfoButton(
            title: l10n.resultsInfoTitle,
            body: l10n.resultsInfoBody,
          ),
        ),
        for (final entry in grouped.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _testCard(
              context,
              type: entry.key,
              label: testTypeLabel(l10n, entry.key),
              points: entry.value
                  .map((e) => ScorePoint(e.performedAt, e.concernScore))
                  .toList(),
            ),
          ),
        const AppGap.lg(),
        SectionHeader(
          l10n.summary,
          action: AppInfoButton(
            title: l10n.summaryInfoTitle,
            body: l10n.summaryInfoBody,
          ),
        ),
        if (averages.length >= 3)
          ScoreRadarChart(
            scores: {
              for (final e in averages.entries)
                testTypeLabel(l10n, e.key): e.value,
            },
          )
        else
          Text(
            l10n.needThreeTests,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        const AppGap.lg(),
        _trendSection(context, l10n),
      ],
    );
  }

  /// The overall trend, with the period it covers stated rather than implied.
  ///
  /// The chart used to be an unlabelled line under a bare "7 days" dropdown,
  /// with no axes at all: there was no way to tell what a point meant, when it
  /// happened, or which way was bad.
  Widget _trendSection(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final points = viewModel.dailyAverages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          l10n.overallTrend,
          action: AppInfoButton(
            title: l10n.trendInfoTitle,
            body: l10n.trendInfoBody,
          ),
        ),
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.trendWindowLabel,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: viewModel.selectedAverageWindow,
              isExpanded: true,
              items: const [7, 14, 30, 90]
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(l10n.trendWindowLast(d)),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) viewModel.updateAverageWindow(val);
              },
            ),
          ),
        ),
        const AppGap.sm(),
        // A single point is a dot, not a trend, and drawing one invites reading
        // a slope into it that is not there.
        if (points.length < 2)
          Text(
            l10n.trendNeedsMoreDays,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ScoreTrendChart(
            spots: [
              for (int i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].value),
            ],
            curved: true,
            filled: true,
            labelAt: (index) {
              if (index < 0 || index >= points.length) return '';
              // Thin the labels out rather than letting them overlap: five
              // dates across the axis stays readable at any window length.
              final stride = (points.length / 5).ceil();
              if (points.length > 5 && index % stride != 0) return '';
              final d = points[index].key;
              return '${d.day}/${d.month}';
            },
          ),
      ],
    );
  }

  /// One test's latest score, with its history behind a disclosure.
  Widget _testCard(
    BuildContext context, {
    required TestType type,
    required String label,
    required List<ScorePoint> points,
  }) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final latest = points.first.score;
    final band = TestScoreInterpretation.bandOfConcern(type, latest);

    // The same three colours the result screen uses, so a score does not
    // change meaning between the screen that produced it and this one.
    final color = switch (band) {
      ScoreBand.reassuring => semantic.success,
      ScoreBand.borderline => semantic.warning,
      ScoreBand.notable => theme.colorScheme.error,
    };
    final bandLabel = switch (band) {
      ScoreBand.reassuring => l10n.bandLabelReassuring,
      ScoreBand.borderline => l10n.bandLabelBorderline,
      ScoreBand.notable => l10n.bandLabelNotable,
    };

    return Card(
      child: ExpansionTile(
        title: ScoreBar(label: label, value: latest, color: color),
        // The band in words, because a bare percentage gives no sense of
        // whether 41% is fine — and colour alone excludes anyone who cannot
        // separate these three hues.
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            bandLabel,
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
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
              return '${dt.day}/${dt.month}';
            },
          ),
        ],
      ),
    );
  }
}
