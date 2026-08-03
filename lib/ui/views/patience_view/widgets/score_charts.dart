import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Charts for the results tab.
///
/// Every chart here wraps itself in `MediaQuery.withClampedTextScaling`. That
/// is load-bearing, not decoration: the app ships a user-facing text-size
/// setting, and fl_chart lays axis labels out against a fixed reserved size,
/// so an unclamped scaler pushes them over the plot area and out of the box.
const double _maxChartTextScale = 1.2;

/// A time series of scores, oldest to newest.
class ScoreTrendChart extends StatelessWidget {
  const ScoreTrendChart({
    super.key,
    required this.spots,
    this.labelAt,
    this.height = 200,
    this.curved = false,
    this.filled = false,
  });

  final List<FlSpot> spots;

  /// Bottom-axis label for a point index, or null for no bottom labels.
  final String Function(int index)? labelAt;

  final double height;
  final bool curved;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxChartTextScale,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (spots.length - 1).toDouble(),
            minY: 0,
            maxY: 1,
            titlesData: labelAt == null
                ? const FlTitlesData(show: false)
                : FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Text(
                          labelAt!(value.toInt()),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 0.25,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) => Text(
                          '${(value * 100).round()}%',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
              getDrawingVerticalLine: (_) =>
                  FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: curved,
                color: theme.colorScheme.primary,
                barWidth: 3,
                dotData: FlDotData(show: !filled),
                belowBarData: BarAreaData(
                  show: filled,
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Per-test scores as a radar, for comparing strengths at a glance.
class ScoreRadarChart extends StatelessWidget {
  const ScoreRadarChart({super.key, required this.scores});

  /// Test label to score in 0..1. Needs at least three entries to form a shape.
  final Map<String, double> scores;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = scores.keys.toList();

    return SizedBox(
      height: 220,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxChartTextScale,
        child: RadarChart(
          RadarChartData(
            dataSets: [
              RadarDataSet(
                fillColor: theme.colorScheme.primary.withValues(alpha: 0.25),
                borderColor: theme.colorScheme.primary,
                entryRadius: 3,
                dataEntries:
                    scores.values.map((v) => RadarEntry(value: v)).toList(),
              ),
            ],
            radarBackgroundColor: Colors.transparent,
            radarBorderData: const BorderSide(color: Colors.transparent),
            tickCount: 10,
            ticksTextStyle: theme.textTheme.labelSmall,
            tickBorderData: BorderSide(color: theme.colorScheme.outlineVariant),
            titleTextStyle: theme.textTheme.labelMedium,
            getTitle: (index, angle) {
              if (index < 0 || index >= labels.length) {
                return const RadarChartTitle(text: '');
              }
              return RadarChartTitle(text: labels[index], angle: angle);
            },
          ),
        ),
      ),
    );
  }
}

/// A point on a score trend, carrying the date its label is drawn from.
class ScorePoint {
  const ScorePoint(this.time, this.score);

  final DateTime time;
  final double score;
}

/// Turns newest-first results into oldest-first chart spots.
///
/// The stored order is newest-first (that is what the lists show), but a trend
/// only reads correctly left-to-right in time.
List<FlSpot> spotsFromNewestFirst(List<ScorePoint> newestFirst) {
  return List.generate(
    newestFirst.length,
    (i) => FlSpot(
      i.toDouble(),
      newestFirst[newestFirst.length - 1 - i].score,
    ),
  );
}
