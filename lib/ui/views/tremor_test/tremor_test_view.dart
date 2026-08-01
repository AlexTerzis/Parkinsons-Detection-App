import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../common/widgets/widgets.dart';
import 'fft_chart_combined.dart';
import 'tremor_test_viewmodel.dart';

/// Measures tremor from the device's accelerometer and gyroscope.
class TremorTestView extends StatelessWidget {
  const TremorTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TremorTestViewModel>.reactive(
      viewModelBuilder: () => TremorTestViewModel(),
      builder: (context, model, child) {
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context)!;
        final hasResults =
            model.resultHand1.isNotEmpty || model.resultHand2.isNotEmpty;

        return AppScaffold(
          title: l10n.tremorTest,
          bottomAction: model.isTesting
              ? null
              : PrimaryAction(
                  label: l10n.startTest,
                  icon: Icons.play_arrow,
                  onPressed: () => model.startTest(l10n),
                ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                model.tremorStatus.isEmpty
                    ? l10n.pressStart
                    : model.tremorStatus,
                style: theme.textTheme.titleMedium,
              ),
              if (model.isTesting) ...[
                const AppGap.md(),
                CountdownProgress(
                  label: l10n.timeLeft(model.secondsLeft),
                  progress: model.progress,
                ),
              ],
              // Both readouts are gated together. Previously only the
              // accelerometer line was inside the `if` — the gyroscope line
              // sat outside it despite the indentation, so it rendered zeroes
              // before the test had started.
              if (model.isTesting || hasResults) ...[
                const AppGap.md(),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accelerometerReadout(
                          model.latestX.toStringAsFixed(2),
                          model.latestY.toStringAsFixed(2),
                          model.latestZ.toStringAsFixed(2),
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const AppGap.xxs(),
                      Text(
                        l10n.gyroscopeReadout(
                          model.latestGyroX.toStringAsFixed(2),
                          model.latestGyroY.toStringAsFixed(2),
                          model.latestGyroZ.toStringAsFixed(2),
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
              if (model.resultHand1.isNotEmpty) ...[
                const AppGap.lg(),
                FFTChartCombined(
                  label: l10n.handOneFftSpectrum,
                  spectrumX: model.spectrumX1,
                  spectrumY: model.spectrumY1,
                  spectrumZ: model.spectrumZ1,
                ),
              ],
              if (model.resultHand2.isNotEmpty) ...[
                const AppGap.lg(),
                FFTChartCombined(
                  label: l10n.handTwoFftSpectrum,
                  spectrumX: model.spectrumX2,
                  spectrumY: model.spectrumY2,
                  spectrumZ: model.spectrumZ2,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
