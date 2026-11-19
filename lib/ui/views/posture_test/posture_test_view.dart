import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:stacked/stacked.dart';

import '../../../models/hand_posture.dart';
import '../../common/widgets/widgets.dart';
import '../patience/hand_landmarker_screen.dart';
import 'posture_result_view.dart';
import 'posture_test_viewmodel.dart';

/// Copying hand and finger postures shown on screen.
///
/// The camera preview is only mounted while a posture is actually being
/// watched for. Unmounting it is what releases the camera, and there is no
/// reason to hold it open while the patient reads an instruction.
class PostureTestView extends StackedView<PostureTestViewModel> {
  const PostureTestView({super.key});

  @override
  Widget builder(
    BuildContext context,
    PostureTestViewModel viewModel,
    Widget? child,
  ) {
    switch (viewModel.phase) {
      case PostureTestPhase.setup:
        return _SetupScreen(viewModel: viewModel);
      case PostureTestPhase.preparing:
        return _PrepareScreen(viewModel: viewModel);
      case PostureTestPhase.running:
        return _WatchingScreen(viewModel: viewModel);
      case PostureTestPhase.finishing:
        return const _FinishingScreen();
      case PostureTestPhase.results:
        return PostureResultView(viewModel: viewModel);
    }
  }

  @override
  PostureTestViewModel viewModelBuilder(BuildContext context) =>
      PostureTestViewModel();
}

/// The shape to copy, drawn large.
class PostureGlyph extends StatelessWidget {
  const PostureGlyph({super.key, required this.posture, this.size = 96});

  final HandPosture posture;
  final double size;

  @override
  Widget build(BuildContext context) {
    // An emoji rather than a line drawing. It is legible at a glance and needs
    // no assets; the written instruction beside it carries the detail, because
    // several of these shapes have no emoji that is exactly right.
    return Text(
      posture.emoji,
      style: TextStyle(fontSize: size),
      textAlign: TextAlign.center,
    );
  }
}

class _SetupScreen extends StatelessWidget {
  const _SetupScreen({required this.viewModel});

  final PostureTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppScaffold(
      title: l10n.postureTest,
      bottomAction: PrimaryAction(
        label: l10n.postureStart,
        icon: Icons.play_arrow,
        onPressed: viewModel.start,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.postureIntroTitle,
                    style: theme.textTheme.titleMedium),
                const AppGap.sm(),
                Text(l10n.postureIntroBody),
              ],
            ),
          ),
          const AppGap.md(),
          AppCard(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final posture in viewModel.sequence)
                  PostureGlyph(posture: posture, size: 40),
              ],
            ),
          ),
          const AppGap.md(),
          AppCard(child: Text(l10n.postureIntroNote)),
        ],
      ),
    );
  }
}

/// Between postures: shows what is coming, with no camera running.
class _PrepareScreen extends StatelessWidget {
  const _PrepareScreen({required this.viewModel});

  final PostureTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final posture = viewModel.currentPosture;
    if (posture == null) return const SizedBox.shrink();

    return AppScaffold(
      title: l10n.postureTest,
      showBackButton: false,
      bottomAction: PrimaryAction(
        label: l10n.postureReady,
        icon: Icons.videocam,
        onPressed: viewModel.beginWatching,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.postureStepOf(viewModel.index + 1, viewModel.total),
            style: theme.textTheme.labelLarge,
          ),
          const AppGap.xs(),
          LinearProgressIndicator(value: viewModel.progress, minHeight: 6),
          const AppGap.lg(),
          AppCard(
            child: Column(
              children: [
                Text(
                  viewModel.isRetry
                      ? l10n.postureSecondTry
                      : l10n.postureCopyThis,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const AppGap.md(),
                PostureGlyph(posture: posture),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The live phase. Overlays sit on the camera preview, so they use the fixed
/// overlay colours rather than theme roles, which risk dark-on-dark here.
class _WatchingScreen extends StatelessWidget {
  const _WatchingScreen({required this.viewModel});

  final PostureTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final posture = viewModel.currentPosture;
    if (posture == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          HandLandmarkerScreen(onFrame: viewModel.onFrame),
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTokens.overlayScrim,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          PostureGlyph(posture: posture, size: 56),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              l10n.postureHoldIt,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(color: AppTokens.onOverlay),
                            ),
                          ),
                          Text(
                            l10n.postureSecondsLeft(viewModel.secondsLeft),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: AppTokens.onOverlay),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Fills as the posture is held, so the patient can see
                      // that it is being recognised before it is accepted.
                      LinearProgressIndicator(
                        value: viewModel.holdProgress,
                        minHeight: 10,
                        backgroundColor: AppTokens.onOverlay
                            .withValues(alpha: AppOpacity.muted),
                      ),
                      if (!viewModel.handVisible) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(Icons.front_hand_outlined,
                                color: AppTokens.onOverlay),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                l10n.postureHandNotVisible,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: AppTokens.onOverlay),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.onOverlay,
                      side: const BorderSide(color: AppTokens.onOverlay),
                    ),
                    onPressed: viewModel.skipCurrent,
                    child: Text(l10n.postureSkip),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishingScreen extends StatelessWidget {
  const _FinishingScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.postureTest,
      showBackButton: false,
      body: AppLoading(message: l10n.cameraFinishing),
    );
  }
}
