import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'tap_test_viewmodel.dart';

class TapTestView extends StackedView<TapTestViewModel> {
  const TapTestView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    TapTestViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tap Test')),
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
            if (viewModel.isTesting)
              Column(
                children: [
                  Text('Time left: ${viewModel.secondsLeft}s'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: viewModel.progress,
                    minHeight: 8,
                  ),
                ],
              ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: viewModel.recordTap,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: viewModel.isTesting
                      ? Colors.blueAccent
                      : Colors.grey.shade400,
                ),
                child: const Center(
                  child: Text(
                    'TAP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed:
                  viewModel.isTesting ? null : () => viewModel.startTest(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Test'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: viewModel.stopTest,
              icon: const Icon(Icons.stop),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              label: const Text('Stop'),
            ),
            const SizedBox(height: 30),
            if (viewModel.resultHand1.isNotEmpty)
              Text(viewModel.resultHand1,
                  style: const TextStyle(fontSize: 16)),
            if (viewModel.resultHand2.isNotEmpty)
              Text(viewModel.resultHand2,
                  style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  TapTestViewModel viewModelBuilder(BuildContext context) => TapTestViewModel();
  /*@override
  void onViewModelReady(TapTestViewModel viewModel) {
    viewModel.loadModel();
    super.onViewModelReady(viewModel);
  }*/
}