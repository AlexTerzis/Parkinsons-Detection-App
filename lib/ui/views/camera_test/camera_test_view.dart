import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'camera_test_viewmodel.dart';
import '../patience/hand_landmarker_screen.dart';

class CameraTestView extends StackedView<CameraTestViewModel> {
  const CameraTestView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    CameraTestViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera with landmark detection
          HandLandmarkerScreen(onFrame: viewModel.onFrame),

          // Countdown overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Place both hands in view',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${viewModel.countdown}s',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (viewModel.isBusy)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  @override
  CameraTestViewModel viewModelBuilder(BuildContext context) =>
      CameraTestViewModel();

  @override
  void onViewModelReady(CameraTestViewModel viewModel) {
    viewModel.start();
    super.onViewModelReady(viewModel);
  }
}
