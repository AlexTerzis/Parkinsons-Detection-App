import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import 'voice_test_viewmodel.dart';

/// Simple UI for recording and analyzing a short voice sample.
class VoiceTestView extends StackedView<VoiceTestViewModel> {
  const VoiceTestView({super.key});

  @override
  Widget builder(
      BuildContext context, VoiceTestViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.voiceTest)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              viewModel.statusText(AppLocalizations.of(context)!),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (viewModel.isRecording)
              Column(
                children: [
                  Text(AppLocalizations.of(context)!
                      .timeLeft(viewModel.secondsLeft)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: viewModel.progress, minHeight: 8),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: viewModel.isRecording ? null : viewModel.startTest,
              icon: const Icon(Icons.mic),
              label: Text(AppLocalizations.of(context)!.startTest),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: viewModel.stopTest,
              icon: const Icon(Icons.stop),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              label: Text(AppLocalizations.of(context)!.stop),
            ),
          ],
        ),
      ),
    );
  }

  @override
  VoiceTestViewModel viewModelBuilder(BuildContext context) =>
      VoiceTestViewModel();
}