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
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                viewModel.tremorStatus,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (viewModel.isTesting)
                Text('⏳ Time left: ${viewModel.secondsLeft}s'),
              const SizedBox(height: 16),
              Text('📈 Accel X: ${viewModel.latestX.toStringAsFixed(2)}'),
              Text('📈 Accel Y: ${viewModel.latestY.toStringAsFixed(2)}'),
              Text('📈 Accel Z: ${viewModel.latestZ.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: viewModel.isTesting
                    ? null
                    : () => viewModel.startTest(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start 2-Hand Test'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: viewModel.stopTest,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Test'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      ),
    );
  }

  @override
  TremorTestViewModel viewModelBuilder(BuildContext context) =>
      TremorTestViewModel();
}
