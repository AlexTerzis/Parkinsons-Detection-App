import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

class FFTChartCombined extends StatelessWidget {
  final String label;
  final List<double> spectrumX;
  final List<double> spectrumY;
  final List<double> spectrumZ;
  final double binWidthHz;

  const FFTChartCombined({
    super.key,
    required this.label,
    required this.spectrumX,
    required this.spectrumY,
    required this.spectrumZ,
    required this.binWidthHz,
  });

  List<FlSpot> _toSpots(List<double> data) {
    final List<FlSpot> spots = [];
    for (int i = 1; i < data.length; i++) {
      final hz = i * binWidthHz;
      if (hz >= 2.5 && hz <= 12.5) spots.add(FlSpot(hz, data[i]));
    }
    return spots;
  }

  FlSpot _getPeak(List<double> data) {
    if (data.length <= 1 || binWidthHz <= 0) return const FlSpot(0, 0);
    double maxVal = 0;
    int maxIndex = 0;
    for (int i = 1; i < data.length; i++) {
      final hz = i * binWidthHz;
      if (hz < 2.5 || hz > 12.5) continue;
      if (data[i] > maxVal) {
        maxVal = data[i];
        maxIndex = i;
      }
    }
    return FlSpot(maxIndex * binWidthHz, maxVal);
  }

  bool get _hasData =>
      binWidthHz > 0 && spectrumX.length > 2 && spectrumY.length > 2 && spectrumZ.length > 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.insufficientSensorData,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    final peakX = _getPeak(spectrumX);
    final peakY = _getPeak(spectrumY);
    final peakZ = _getPeak(spectrumZ);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.square, size: 10, color: Colors.blue),
            const SizedBox(width: 4),
            Text(l10n.xAxisLabel, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            const Icon(Icons.square, size: 10, color: Colors.green),
            const SizedBox(width: 4),
            Text(l10n.yAxisLabel, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            const Icon(Icons.square, size: 10, color: Colors.red),
            const SizedBox(width: 4),
            Text(l10n.zAxisLabel, style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: 2.5,
              maxX: 12.5,
              minY: 0,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 2.5,
                    getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(1)} Hz', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 100,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: _toSpots(spectrumX),
                  isCurved: false,
                  color: Colors.blue,
                  dotData: FlDotData(show: true, checkToShowDot: (spot, _) => spot.x == peakX.x),
                  belowBarData: BarAreaData(show: false),
                  barWidth: 2,
                ),
                LineChartBarData(
                  spots: _toSpots(spectrumY),
                  isCurved: false,
                  color: Colors.green,
                  dotData: FlDotData(show: true, checkToShowDot: (spot, _) => spot.x == peakY.x),
                  belowBarData: BarAreaData(show: false),
                  barWidth: 2,
                ),
                LineChartBarData(
                  spots: _toSpots(spectrumZ),
                  isCurved: false,
                  color: Colors.red,
                  dotData: FlDotData(show: true, checkToShowDot: (spot, _) => spot.x == peakZ.x),
                  belowBarData: BarAreaData(show: false),
                  barWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
