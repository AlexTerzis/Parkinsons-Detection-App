import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FFTChartCombined extends StatelessWidget {
  final String label;
  final List<double> spectrumX;
  final List<double> spectrumY;
  final List<double> spectrumZ;

  const FFTChartCombined({
    super.key,
    required this.label,
    required this.spectrumX,
    required this.spectrumY,
    required this.spectrumZ,
  });

  List<FlSpot> _toSpots(List<double> data) {
    final int limit = data.length > 20 ? 20 : data.length;
    return List.generate(limit - 1, (i) => FlSpot((i + 1).toDouble(), data[i + 1]));
  }

  FlSpot _getPeak(List<double> data) {
    double maxVal = data.length > 1 ? data[1] : 0.0;
    int maxIndex = 1;
    for (int i = 2; i < data.length && i < 20; i++) {
      if (data[i] > maxVal) {
        maxVal = data[i];
        maxIndex = i;
      }
    }
    return FlSpot(maxIndex.toDouble(), maxVal);
  }

  @override
  Widget build(BuildContext context) {
    final peakX = _getPeak(spectrumX);
    final peakY = _getPeak(spectrumY);
    final peakZ = _getPeak(spectrumZ);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.square, size: 10, color: Colors.blue),
            SizedBox(width: 4),
            Text("X-axis", style: TextStyle(fontSize: 12)),
            SizedBox(width: 12),
            Icon(Icons.square, size: 10, color: Colors.green),
            SizedBox(width: 4),
            Text("Y-axis", style: TextStyle(fontSize: 12)),
            SizedBox(width: 12),
            Icon(Icons.square, size: 10, color: Colors.red),
            SizedBox(width: 4),
            Text("Z-axis", style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 20,
              minY: 0,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 5,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()} Hz', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: _toSpots(spectrumX),
                  isCurved: false,
                  color: Colors.blue,
                  dotData: FlDotData(show: true, checkToShowDot: (spot, _) => spot == peakX),
                  belowBarData: BarAreaData(show: false),
                  barWidth: 2,
                ),
                LineChartBarData(
                  spots: _toSpots(spectrumY),
                  isCurved: false,
                  color: Colors.green,
                  dotData: FlDotData(show: true, checkToShowDot: (spot, _) => spot == peakY),
                  belowBarData: BarAreaData(show: false),
                  barWidth: 2,
                ),
                LineChartBarData(
                  spots: _toSpots(spectrumZ),
                  isCurved: false,
                  color: Colors.red,
                  dotData: FlDotData(show: true, checkToShowDot: (spot, _) => spot == peakZ),
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
