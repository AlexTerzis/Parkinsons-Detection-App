import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:stacked/stacked.dart';

import '../../common/app_tokens.dart';
import '../patience/hand_landmarker_screen.dart';
import '../../../models/camera_task_protocol.dart';
import '../../../services/scoring/task_quality.dart';
import 'camera_results_view.dart';
import 'camera_test_viewmodel.dart';

/// Guided camera assessment.
///
/// The camera preview stays mounted for the whole session — including the setup
/// screen — so the permission prompt and the native landmarker are settled
/// before the first task's timer starts.
class CameraTestView extends StackedView<CameraTestViewModel> {
  const CameraTestView({super.key});

  @override
  Widget builder(
    BuildContext context,
    CameraTestViewModel viewModel,
    Widget? child,
  ) {
    // The results screen replaces the preview rather than covering it, so the
    // camera and the native detector are torn down as soon as there is nothing
    // left to record.
    if (viewModel.phase == CameraTestPhase.results) {
      return CameraResultsView(viewModel: viewModel);
    }

    return Scaffold(
      body: Stack(
        children: [
          HandLandmarkerScreen(onFrame: viewModel.onFrame),
          SafeArea(
            child: switch (viewModel.phase) {
              CameraTestPhase.setup => _SetupOverlay(viewModel: viewModel),
              CameraTestPhase.preparing =>
                _PreparingOverlay(viewModel: viewModel),
              CameraTestPhase.running => _RunningOverlay(viewModel: viewModel),
              CameraTestPhase.paused => _PausedOverlay(viewModel: viewModel),
              CameraTestPhase.taskReview =>
                _TaskReviewOverlay(viewModel: viewModel),
              CameraTestPhase.finishing => const _FinishingOverlay(),
              // Handled above, before the preview is built.
              CameraTestPhase.results => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }

  @override
  CameraTestViewModel viewModelBuilder(BuildContext context) =>
      CameraTestViewModel();
}

/// Localized display strings for a protocol task.
extension _CameraTaskL10n on CameraTask {
  String name(AppLocalizations l10n) {
    switch (type) {
      case CameraTaskType.rest:
        return l10n.cameraTaskRest;
      case CameraTaskType.openClose:
        return l10n.cameraTaskOpenClose;
      case CameraTaskType.fingerTap:
        return l10n.cameraTaskFingerTap;
      case CameraTaskType.pronationSupination:
        return l10n.cameraTaskPronation;
    }
  }

  String instruction(AppLocalizations l10n) {
    switch (type) {
      case CameraTaskType.rest:
        return l10n.cameraInstructionRest;
      case CameraTaskType.openClose:
        return l10n.cameraInstructionOpenClose;
      case CameraTaskType.fingerTap:
        return l10n.cameraInstructionFingerTap;
      case CameraTaskType.pronationSupination:
        return l10n.cameraInstructionPronation;
    }
  }

  String handLabel(AppLocalizations l10n) {
    if (isBothHands) return l10n.cameraHandBoth;
    return hands.first == 'Left' ? l10n.cameraHandLeft : l10n.cameraHandRight;
  }
}

/// Shared panel styling for anything laid over the live camera preview.
///
/// Uses the scrim tokens rather than theme surfaces: this content sits on
/// arbitrary camera imagery, so it needs guaranteed contrast of its own.
class _OverlayPanel extends StatelessWidget {
  const _OverlayPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTokens.overlayScrim,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }
}

class _SetupOverlay extends StatelessWidget {
  const _SetupOverlay({required this.viewModel});

  final CameraTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        child: _OverlayPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.cameraTestTitle,
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.cameraSetupBody,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.cameraTestLength,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final mode in CameraTestMode.values)
                    ChoiceChip(
                      label: Text(mode == CameraTestMode.full
                          ? l10n.cameraModeFull
                          : l10n.cameraModeShort),
                      selected: viewModel.mode == mode,
                      onSelected: (_) => viewModel.setMode(mode),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.cameraPacingLabel,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final pacing in CameraPacing.values)
                    ChoiceChip(
                      label: Text(pacing == CameraPacing.selfPaced
                          ? l10n.cameraPacingSelf
                          : l10n.cameraPacingTimed),
                      selected: viewModel.pacing == pacing,
                      onSelected: (_) => viewModel.setPacing(pacing),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                // Self-paced has no fixed length — the patient decides how long
                // they spend reading — so a single number would be a fiction.
                viewModel.pacing == CameraPacing.selfPaced
                    ? '${l10n.cameraApproxDurationRange(viewModel.estimatedMinutesLow, viewModel.estimatedMinutesHigh)}'
                        '\n${l10n.cameraPacingSelfNote}'
                    : '${l10n.cameraApproxDuration(viewModel.totalDuration.inSeconds)}'
                        '\n${l10n.cameraPacingTimedNote}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              if (viewModel.mode == CameraTestMode.short) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.cameraModeShortNote,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTokens.onOverlay),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: viewModel.start,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.cameraStart),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: AppTokens.onOverlay),
                onPressed: viewModel.cancel,
                child: Text(l10n.cameraExit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown before a step records: what to do, and when to begin.
///
/// The whole instruction is on screen with nothing being measured yet. That is
/// deliberate — the slowest part of this assessment is understanding the task,
/// and the previous version started the clock while the patient was still
/// reading, so the first seconds of every step were them arranging their hand
/// and were measured as a hesitant start.
class _PreparingOverlay extends StatelessWidget {
  const _PreparingOverlay({required this.viewModel});

  final CameraTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final task = viewModel.currentTask;
    if (task == null) return const SizedBox.shrink();

    final int? countdown = viewModel.leadInCountdown;

    return Column(
      children: [
        _OverlayPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.cameraStepOf(viewModel.taskIndex + 1, viewModel.taskCount),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: viewModel.overallProgress,
                minHeight: 6,
                backgroundColor:
                    AppTokens.onOverlay.withValues(alpha: AppOpacity.muted),
              ),
            ],
          ),
        ),
        const Spacer(),
        _OverlayPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${task.handLabel(l10n)} · ${task.name(l10n)}',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                task.instruction(l10n),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.md),
              if (viewModel.isAwaitingReady) ...[
                Text(
                  l10n.cameraStepReady,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppTokens.onOverlay),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: viewModel.startCurrentStep,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.cameraStartStep),
                ),
              ] else if (viewModel.awaitingHand)
                // The countdown is held, not running down, until the detector
                // can actually see a hand.
                Row(
                  children: [
                    const Icon(Icons.front_hand_outlined,
                        color: AppTokens.onOverlay),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.cameraShowHandToBegin,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: AppTokens.onOverlay),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Text(
                      '${countdown ?? 0}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: AppTokens.onOverlay,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.cameraGetReady,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: AppTokens.onOverlay),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: AppTokens.onOverlay),
                onPressed: viewModel.cancel,
                child: Text(l10n.cameraExit),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunningOverlay extends StatelessWidget {
  const _RunningOverlay({required this.viewModel});

  final CameraTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final task = viewModel.currentTask;
    if (task == null) return const SizedBox.shrink();

    return Column(
      children: [
        _OverlayPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.cameraStepOf(
                          viewModel.taskIndex + 1, viewModel.taskCount),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: AppTokens.onOverlay),
                    ),
                  ),
                  if (task.mdsUpdrsItem != null)
                    Text(
                      l10n.cameraMdsItem(task.mdsUpdrsItem!),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppTokens.onOverlay),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: viewModel.overallProgress,
                minHeight: 6,
                backgroundColor:
                    AppTokens.onOverlay.withValues(alpha: AppOpacity.muted),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${task.handLabel(l10n)} · ${task.name(l10n)}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                task.instruction(l10n),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.md),
              // Countdown paired with a bar: a number alone is easy to lose
              // track of while concentrating on the movement.
              Row(
                children: [
                  Text(
                    '${viewModel.countdown}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppTokens.onOverlay,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: viewModel.taskProgress,
                      minHeight: 10,
                      backgroundColor: AppTokens.onOverlay
                          .withValues(alpha: AppOpacity.muted),
                    ),
                  ),
                ],
              ),
              if (!viewModel.targetHandVisible) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.front_hand_outlined,
                        color: AppTokens.onOverlay),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.cameraHandNotVisible(task.handLabel(l10n)),
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
        _OverlayPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (viewModel.pausePending) ...[
                Text(
                  l10n.cameraPausePending,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppTokens.onOverlay),
                ),
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.onOverlay,
                    side: const BorderSide(color: AppTokens.onOverlay),
                  ),
                  onPressed: viewModel.cancelPauseRequest,
                  child: Text(l10n.cameraCancelPause),
                ),
              ] else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.onOverlay,
                    side: const BorderSide(color: AppTokens.onOverlay),
                  ),
                  onPressed: viewModel.requestPause,
                  icon: const Icon(Icons.pause),
                  label: Text(l10n.cameraPause),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({required this.viewModel});

  final CameraTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final next = viewModel.currentTask;

    return Center(
      child: SingleChildScrollView(
        child: _OverlayPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.cameraPausedTitle,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.cameraPausedBody,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              if (next != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.cameraNextUp(
                      '${next.handLabel(l10n)} · ${next.name(l10n)}'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppTokens.onOverlay),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: viewModel.resume,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.cameraResume),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: AppTokens.onOverlay),
                onPressed: viewModel.cancel,
                child: Text(l10n.cameraExit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Localized text for a failed quality check.
///
/// The validator returns an enum plus an English fallback rather than a
/// finished sentence, so the message can be translated here where the locale
/// lives. Keeping the wording out of the service is also what stops clinical
/// language creeping into it: these strings are reviewed alongside the rest of
/// the patient-facing copy.
String _qualityMessage(AppLocalizations l10n, QualityFailure failure) {
  switch (failure.check) {
    case QualityCheck.usableFrames:
      return l10n.cameraQualityUsableFrames;
    case QualityCheck.handInFrame:
      return l10n.cameraQualityHandInFrame;
    case QualityCheck.handedness:
      return l10n.cameraQualityHandedness;
    case QualityCheck.trackingContinuity:
      return l10n.cameraQualityContinuity;
    case QualityCheck.effectiveFps:
      return l10n.cameraQualityFps;
    case QualityCheck.usableDuration:
      return l10n.cameraQualityDuration;
    case QualityCheck.landmarkCompleteness:
      return l10n.cameraQualityLandmarks;
    case QualityCheck.handSizeStability:
      return l10n.cameraQualityHandSize;
  }
}

/// Offered when a step was not recorded well enough to measure.
///
/// Says what went wrong with the *recording* and what to do about it, and never
/// anything about what the movement looked like. Continuing is always available
/// — a patient who cannot produce a clean recording must still be able to
/// finish the test rather than be trapped on one step.
class _TaskReviewOverlay extends StatelessWidget {
  const _TaskReviewOverlay({required this.viewModel});

  final CameraTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final task = viewModel.currentTask;
    final quality = viewModel.currentQuality;
    if (task == null || quality == null) return const SizedBox.shrink();

    // The worst failure first; the rest are listed beneath so a patient with
    // two problems is not told to fix only one of them.
    final failures = List<QualityFailure>.of(quality.failures);

    return Center(
      child: SingleChildScrollView(
        child: _OverlayPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.replay_circle_filled_outlined,
                      color: AppTokens.onOverlay),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.cameraRetryTitle,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: AppTokens.onOverlay),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.cameraRetryBody(
                    '${task.handLabel(l10n)} · ${task.name(l10n)}'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final failure in failures)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 20, color: AppTokens.onOverlay),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _qualityMessage(l10n, failure),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppTokens.onOverlay),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                viewModel.canRetryCurrentTask
                    ? l10n.cameraRetryAttempt(
                        viewModel.currentAttempt,
                        CameraTestViewModel.maxAttemptsPerTask,
                      )
                    : l10n.cameraRetryExhausted(viewModel.currentAttempt),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: AppTokens.onOverlay),
              ),
              const SizedBox(height: AppSpacing.md),
              if (viewModel.canRetryCurrentTask)
                ElevatedButton.icon(
                  onPressed: viewModel.retryCurrentTask,
                  icon: const Icon(Icons.replay),
                  label: Text(l10n.cameraRetryAgain),
                ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTokens.onOverlay,
                  side: const BorderSide(color: AppTokens.onOverlay),
                ),
                onPressed: viewModel.keepAndContinue,
                child: Text(l10n.cameraRetryKeep),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinishingOverlay extends StatelessWidget {
  const _FinishingOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: _OverlayPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTokens.onOverlay),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.cameraFinishing,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: AppTokens.onOverlay),
            ),
          ],
        ),
      ),
    );
  }
}
