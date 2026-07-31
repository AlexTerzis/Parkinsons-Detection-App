import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../patience/patience_viewmodel.dart';
import '../../../../models/test_result.dart';

/// Displays historical scores and trend charts.
class ResultsTab extends StatelessWidget {
  final PatienceViewModel viewModel;
  const ResultsTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = viewModel.groupedResults;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(AppLocalizations.of(context)!.testResults,
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        ...grouped.entries.map((entry) {
          final label = viewModel.labelForType(entry.key);
          final latest = entry.value.first.score;
          final data = entry.value
              .map((e) => _ScorePoint(e.performedAt, e.score))
              .toList();
          final spots = data
              .asMap()
              .entries
              .map((e) =>
                  FlSpot(e.key.toDouble(), data[data.length - 1 - e.key].score))
              .toList();
          return Card(
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(child: Text(label)),
                  SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                      value: latest,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(latest * 100).round()}%'),
                ],
              ),
              children: [
                SizedBox(
                  height: 200,
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.2,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (spots.length - 1).toDouble(),
                        minY: 0,
                        maxY: 1,
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= data.length) {
                                  return const SizedBox.shrink();
                                }
                                final dt = data[data.length - 1 - index].time;
                                return Text('${dt.month}/${dt.day}',
                                    style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 0.25,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) => Text(
                                '${(value * 100).round()}%',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: false,
                            color: theme.colorScheme.primary,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (grouped.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.summary,
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (viewModel.resultsSummary.length >= 3)
            SizedBox(
              height: 220,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.2,
                child: RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        fillColor:
                            theme.colorScheme.primary.withValues(alpha: 0.25),
                        borderColor: theme.colorScheme.primary,
                        entryRadius: 3,
                        dataEntries: viewModel.resultsSummary.values
                            .map((v) => RadarEntry(value: v))
                            .toList(),
                      ),
                    ],
                    radarBackgroundColor: Colors.transparent,
                    radarBorderData:
                        const BorderSide(color: Colors.transparent),
                    tickCount: 10,
                    ticksTextStyle: const TextStyle(fontSize: 10),
                    tickBorderData: BorderSide(color: theme.dividerColor),
                    titleTextStyle: const TextStyle(fontSize: 12),
                    getTitle: (index, angle) {
                      final keys = viewModel.resultsSummary.keys.toList();
                      if (index < 0 || index >= keys.length) {
                        return const RadarChartTitle(text: '');
                      }
                      return RadarChartTitle(text: keys[index], angle: angle);
                    },
                  ),
                ),
              ),
            )
          else
            Text(
              AppLocalizations.of(context)!.needThreeTests,
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
        ],
        if (viewModel.results.isNotEmpty) ...[
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: DropdownButton<int>(
              value: viewModel.selectedAverageWindow,
              items: const [3, 7, 14, 30]
                  .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(AppLocalizations.of(context)!.days(d))))
                  .toList(),
              onChanged: (val) {
                if (val != null) viewModel.updateAverageWindow(val);
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (viewModel.getAverageTrend().length - 1).toDouble(),
                  minY: 0,
                  maxY: 1,
                  titlesData: const FlTitlesData(show: false),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: viewModel.getAverageTrend(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download),
          label: Text(AppLocalizations.of(context)!.exportResults),
        ),
      ],
    );
  }
}

class _ScorePoint {
  final DateTime time;
  final double score;
  _ScorePoint(this.time, this.score);
}
