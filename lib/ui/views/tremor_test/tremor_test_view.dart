import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'tremor_test_viewmodel.dart';

class TremorTestView extends StackedView<TremorTestViewModel> {
  const TremorTestView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    TremorTestViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tremor Test')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              viewModel.tremorStatus,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text('⏳ Time left: ${viewModel.secondsLeft}s',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            Text('📈 Accel: ${viewModel.latestAcc.toStringAsFixed(2)}'),
            Text('🌀 Gyro: ${viewModel.latestGyro.toStringAsFixed(2)}'),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                viewModel.startDetection(() {
                  Navigator.of(context).pop(); // Go back after test
                });
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start 10s Test'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: viewModel.stopDetection,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Test'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  @override
  TremorTestViewModel viewModelBuilder(BuildContext context) =>
      TremorTestViewModel();
}
