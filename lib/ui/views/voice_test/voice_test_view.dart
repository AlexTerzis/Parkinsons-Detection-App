import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../common/widgets/widgets.dart';
import 'voice_test_viewmodel.dart';

/// Records and analyses a short voice sample.
class VoiceTestView extends StackedView<VoiceTestViewModel> {
  const VoiceTestView({super.key});

  @override
  Widget builder(
      BuildContext context, VoiceTestViewModel viewModel, Widget? child) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.voiceTest,
      bottomAction: viewModel.isRecording
          ? SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: viewModel.stopTest,
                icon: const Icon(Icons.stop),
                label: Text(l10n.stop),
              ),
            )
          : PrimaryAction(
              label: l10n.startTest,
              icon: Icons.mic,
              onPressed: viewModel.startTest,
            ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            viewModel.statusText(l10n),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          if (viewModel.isRecording) ...[
            const AppGap.lg(),
            CountdownProgress(
              label: l10n.timeLeft(viewModel.secondsLeft),
              progress: viewModel.progress,
            ),
          ],
        ],
      ),
    );
  }

  @override
  VoiceTestViewModel viewModelBuilder(BuildContext context) =>
      VoiceTestViewModel();
}
