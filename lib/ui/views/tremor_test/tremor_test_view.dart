import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'tremor_test_viewmodel.dart';
import 'fft_chart_combined.dart';

class TremorTestView extends StatelessWidget {
  const TremorTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TremorTestViewModel>.reactive(
      viewModelBuilder: () => TremorTestViewModel(),
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Tremor Test')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  model.tremorStatus,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text('Time left: ${model.secondsLeft}s'),
                const SizedBox(height: 10),
                if (model.isTesting || model.resultHand1.isNotEmpty || model.resultHand2.isNotEmpty)
                  Text('Accelerometer: X=${model.latestX.toStringAsFixed(2)} Y=${model.latestY.toStringAsFixed(2)} Z=${model.latestZ.toStringAsFixed(2)}'),
                  Text(
                    'Live Gyroscope meter: X=${model.latestGyroX.toStringAsFixed(2)}  '
                    'Y=${model.latestGyroY.toStringAsFixed(2)}  '
                    'Z=${model.latestGyroZ.toStringAsFixed(2)}',
                  ),
                const SizedBox(height: 10),
                if (!model.isTesting)
                  ElevatedButton(
                    onPressed: model.startTest,
                    child: const Text('Start Tremor Test'),
                  ),
                const SizedBox(height: 20),
                if (model.resultHand1.isNotEmpty) ...[
                  FFTChartCombined(
                    label: 'Hand 1 FFT Spectrum',
                    spectrumX: model.spectrumX1,
                    spectrumY: model.spectrumY1,
                    spectrumZ: model.spectrumZ1,
                  ),
                  const SizedBox(height: 24),
                ],
                if (model.resultHand2.isNotEmpty) ...[
                  FFTChartCombined(
                    label: 'Hand 2 FFT Spectrum',
                    spectrumX: model.spectrumX2,
                    spectrumY: model.spectrumY2,
                    spectrumZ: model.spectrumZ2,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
