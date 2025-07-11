import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'voice_test_viewmodel.dart';

/// Simple UI for recording and analyzing a short voice sample.
class VoiceTestView extends StackedView<VoiceTestViewModel> {
  const VoiceTestView({super.key});

  @override
  Widget builder(
      BuildContext context, VoiceTestViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Test')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              viewModel.status,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (viewModel.isRecording)
              Column(
                children: [
                  Text('Time left: ${viewModel.secondsLeft}s'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: viewModel.progress, minHeight: 8),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: viewModel.isRecording ? null : viewModel.startTest,
              icon: const Icon(Icons.mic),
              label: const Text('Start Test'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: viewModel.stopTest,
              icon: const Icon(Icons.stop),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              label: const Text('Stop'),
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