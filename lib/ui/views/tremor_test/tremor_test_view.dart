import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'tremor_test_viewmodel.dart';
import 'fft_chart_combined.dart';

class TremorTestView extends StatelessWidget {
  const TremorTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TremorTestViewModel>.reactive(
      viewModelBuilder: () => TremorTestViewModel(),
      builder: (context, model, child) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.tremorTest)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  model.tremorStatus.isEmpty
                      ? l10n.pressStart
                      : model.tremorStatus,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(l10n.timeLeft(model.secondsLeft)),
                const SizedBox(height: 10),
                if (model.isTesting || model.resultHand1.isNotEmpty || model.resultHand2.isNotEmpty)
                  Text(l10n.accelerometerReadout(
                    model.latestX.toStringAsFixed(2),
                    model.latestY.toStringAsFixed(2),
                    model.latestZ.toStringAsFixed(2),
                  )),
                  Text(
                    l10n.gyroscopeReadout(
                      model.latestGyroX.toStringAsFixed(2),
                      model.latestGyroY.toStringAsFixed(2),
                      model.latestGyroZ.toStringAsFixed(2),
                    ),
                  ),
                const SizedBox(height: 10),
                if (!model.isTesting)
                  ElevatedButton(
                    onPressed: () => model.startTest(l10n),
                    child: Text(l10n.startTest),
                  ),
                const SizedBox(height: 20),
                if (model.resultHand1.isNotEmpty) ...[
                  FFTChartCombined(
                    label: l10n.handOneFftSpectrum,
                    spectrumX: model.spectrumX1,
                    spectrumY: model.spectrumY1,
                    spectrumZ: model.spectrumZ1,
                  ),
                  const SizedBox(height: 24),
                ],
                if (model.resultHand2.isNotEmpty) ...[
                  FFTChartCombined(
                    label: l10n.handTwoFftSpectrum,
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
