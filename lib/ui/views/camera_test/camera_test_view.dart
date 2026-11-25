import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:stacked/stacked.dart';

import '../../common/app_tokens.dart';
import '../patience/hand_landmarker_screen.dart';
import '../../../models/camera_task_protocol.dart';
import '../../../services/scoring/task_quality.dart';
import 'camera_results_view.dart';
import 'camera_test_viewmodel.dart';
import 'step_illustration.dart';

/// Guided, hands-free camera assessment, in landscape.
///
/// The camera preview stays mounted from setup to the last step, so the
/// permission prompt and the native landmarker are settled before anything is
/// recorded. Overlays are kept to thin strips at the top and bottom of the
/// picture so the hands in the middle stay visible to the patient.
class CameraTestView extends StackedView<CameraTestViewModel> {
  const CameraTestView({super.key});

  @override
  Widget builder(
    BuildContext context,
    CameraTestViewModel viewModel,
    Widget? child,
  ) {
    if (viewModel.phase == CameraTestPhase.results) {
      return CameraResultsView(viewModel: viewModel);
    }

    final l10n = AppLocalizations.of(context)!;
    _CameraVoice.instance.setLocale(Localizations.localeOf(context));
    viewModel.onCue = (cue) {
      final text = _cueText(l10n, cue);
      if (text.isNotEmpty) _CameraVoice.instance.say(text);
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          HandLandmarkerScreen(onFrame: viewModel.onFrame, landscape: true),
          SafeArea(
            child: switch (viewModel.phase) {
              CameraTestPhase.setup => _SetupOverlay(viewModel: viewModel),
              CameraTestPhase.preparing =>
                _PreparingOverlay(viewModel: viewModel),
              CameraTestPhase.running => _RunningOverlay(viewModel: viewModel),
              CameraTestPhase.paused => _PausedOverlay(viewModel: viewModel),
              CameraTestPhase.finishing => const _FinishingOverlay(),
              CameraTestPhase.results => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }

  @override
  void onDispose(CameraTestViewModel viewModel) {
    _CameraVoice.instance.stop();
    super.onDispose(viewModel);
  }

  @override
  CameraTestViewModel viewModelBuilder(BuildContext context) =>
      CameraTestViewModel();
}

/// Speaks the cues, so the patient never has to look at or reach the phone.
class _CameraVoice {
  _CameraVoice._();

  static final _CameraVoice instance = _CameraVoice._();

  final FlutterTts _tts = FlutterTts();
  String? _language;
  bool _configured = false;

  Future<void> setLocale(Locale locale) async {
    final language = locale.languageCode == 'el' ? 'el-GR' : 'en-US';
    if (language == _language) return;
    _language = language;
    try {
      await _tts.setLanguage(language);
      if (!_configured) {
        _configured = true;
        await _tts.setSpeechRate(0.45);
        // Queue rather than interrupt: "Stop" and the next instruction are
        // issued back to back and both need to be heard.
        await _tts.setQueueMode(1);
      }
    } catch (e) {
      debugPrint('Camera test voice unavailable: $e');
    }
  }

  void say(String text) {
    _tts.speak(text).catchError((Object e) {
      debugPrint('Camera test voice failed: $e');
      return null;
    });
  }

  void stop() {
    _tts.stop().catchError((Object _) => null);
  }
}

String _cueText(AppLocalizations l10n, CameraCue cue) {
  final task = cue.task;
  String describe(CameraTask t) =>
      '${t.handLabel(l10n)}. ${t.name(l10n)}. ${t.instruction(l10n)}';

  switch (cue.kind) {
    case CameraCueKind.instruction:
      return task == null ? '' : describe(task);
    case CameraCueKind.switchHands:
      if (task == null) return '';
      return '${l10n.cameraSwitchHands(task.handLabel(l10n).toLowerCase())} '
          '${task.name(l10n)}. ${task.instruction(l10n)}';
    case CameraCueKind.retry:
      return task == null
          ? l10n.cameraSayRetry
          : '${l10n.cameraSayRetry} ${describe(task)}';
    case CameraCueKind.go:
      return l10n.cameraSayGo;
    case CameraCueKind.stop:
      return l10n.cameraSayStop;
    case CameraCueKind.finished:
      return l10n.cameraSayFinished;
  }
}

/// Localized display strings for a protocol task.
extension CameraTaskL10n on CameraTask {
  String name(AppLocalizations l10n) => type.displayName(l10n);

  String instruction(AppLocalizations l10n) {
    switch (type) {
      case CameraTaskType.rest:
        return l10n.cameraInstructionRestBoth;
      case CameraTaskType.posture:
        return l10n.cameraInstructionPosture;
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

extension CameraTaskTypeL10n on CameraTaskType {
  String displayName(AppLocalizations l10n) {
    switch (this) {
      case CameraTaskType.rest:
        return l10n.cameraTaskRest;
      case CameraTaskType.posture:
        return l10n.cameraTaskPosture;
      case CameraTaskType.openClose:
        return l10n.cameraTaskOpenClose;
      case CameraTaskType.fingerTap:
        return l10n.cameraTaskFingerTap;
      case CameraTaskType.pronationSupination:
        return l10n.cameraTaskPronation;
    }
  }
}

/// Shared panel styling for anything laid over the live camera preview.
class _OverlayPanel extends StatelessWidget {
  const _OverlayPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTokens.overlayScrim,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }
}

TextStyle? _on(TextStyle? style) => style?.copyWith(color: AppTokens.onOverlay);

/// Setup: how to place the phone, and a live check of what the camera sees.
///
/// The instructions sit in a panel on the left; the right of the picture is
/// left clear so the patient can see their own hands while they position the
/// phone.
class _SetupOverlay extends StatelessWidget {
  const _SetupOverlay({required this.viewModel});

  final CameraTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    final steps = <(IconData, String)>[
      (Icons.screen_rotation, l10n.cameraSetupStep1),
      (Icons.stay_current_landscape, l10n.cameraSetupStep2),
      (Icons.straighten, l10n.cameraSetupStep3),
      (Icons.wb_sunny_outlined, l10n.cameraSetupStep4),
      (Icons.record_voice_over_outlined, l10n.cameraSetupStep5),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: (width * 0.5).clamp(280.0, 460.0),
          child: _OverlayPanel(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.cameraSetupTitle,
                      style: _on(theme.textTheme.titleLarge)),
                  const SizedBox(height: AppSpacing.xs),
                  for (final (icon, text) in steps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: 20, color: AppTokens.onOverlay),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(text,
                                style: _on(theme.textTheme.bodyMedium)),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    l10n.cameraSetupDuration('${viewModel.estimatedMinutes}',
                        '${viewModel.taskCount}'),
                    style: _on(theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: _OverlayPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SetupStatus(viewModel: viewModel),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: viewModel.start,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.cameraStart),
                  ),
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
        ),
      ],
    );
  }
}

class _SetupStatus extends StatelessWidget {
  const _SetupStatus({required this.viewModel});

  final CameraTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (!viewModel.cameraLive) {
      return Text(l10n.cameraSetupWaitingCamera,
          style: _on(theme.textTheme.titleSmall));
    }

    final hint = viewModel.setupHint;
    final bool ok = hint == SetupHint.ready;
    final String text = switch (hint) {
      SetupHint.noHands => l10n.cameraSetupHintNoHands,
      SetupHint.oneHand => l10n.cameraSetupHintOneHand,
      SetupHint.tooFar => l10n.cameraSetupHintTooFar,
      SetupHint.tooClose => l10n.cameraSetupHintTooClose,
      SetupHint.ready => l10n.cameraSetupHintReady,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.front_hand_outlined,
                color: ok ? AppTokens.success : AppTokens.onOverlay),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(text, style: _on(theme.textTheme.titleSmall))),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          l10n.cameraSetupFps('${viewModel.measuredFps.round()}'),
          style: _on(theme.textTheme.bodySmall),
        ),
        if (viewModel.cameraIsSlow)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(l10n.cameraSetupSlow,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFFFFD27A))),
          ),
      ],
    );
  }
}

/// Top strip: which step, which hand, how far through the test.
class _StepHeader extends StatelessWidget {
  const _StepHeader(
      {required this.viewModel, required this.task, this.trailing});

  final CameraTestViewModel viewModel;
  final CameraTask task;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return _OverlayPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.cameraStepOf(viewModel.taskIndex + 1, viewModel.taskCount)}'
                  '  ·  ${task.handLabel(l10n)}  ·  ${task.name(l10n)}',
                  style: _on(theme.textTheme.titleMedium),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) trailing!,
              IconButton(
                tooltip: l10n.cameraExit,
                onPressed: viewModel.cancel,
                icon: const Icon(Icons.close, color: AppTokens.onOverlay),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: viewModel.overallProgress,
            minHeight: 4,
            backgroundColor:
                AppTokens.onOverlay.withValues(alpha: AppOpacity.muted),
          ),
        ],
      ),
    );
  }
}

class _PreparingOverlay extends StatelessWidget {
  const _PreparingOverlay({required this.viewModel});

  final CameraTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final task = viewModel.currentTask;
    if (task == null) return const SizedBox.shrink();

    final retry = viewModel.retryReason;
    final String waiting = task.isBothHands
        ? l10n.cameraShowHandsToBegin
        : l10n.cameraHandNotVisible(task.handLabel(l10n).toLowerCase());

    return Column(
      children: [
        _StepHeader(viewModel: viewModel, task: task),
        Expanded(
          child: Center(
            child: viewModel.awaitingHand
                ? _OverlayPanel(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.front_hand_outlined,
                            color: AppTokens.onOverlay),
                        const SizedBox(width: AppSpacing.xs),
                        Text(waiting, style: _on(theme.textTheme.titleMedium)),
                      ],
                    ),
                  )
                // Scales down rather than overflowing when the panels above
                // and below leave little height (large system font sizes).
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${viewModel.leadInCountdown ?? 0}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: AppTokens.onOverlay,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(blurRadius: 12, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        _OverlayPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StepIllustration(
                key: ValueKey(task.id),
                type: task.type,
                hand: task.isBothHands ? null : task.hands.single,
                size: const Size(150, 120),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (task.switchesHand && retry == null)
                    Text(
                      l10n.cameraSwitchHands(
                          task.handLabel(l10n).toLowerCase()),
                      style: _on(theme.textTheme.titleMedium),
                    ),
                  if (retry != null) ...[
                    Text(l10n.cameraRetryNotice,
                        style: _on(theme.textTheme.titleMedium)),
                    for (final failure in retry.failures.take(2))
                      Text(_qualityMessage(l10n, failure),
                          style: _on(theme.textTheme.bodySmall)),
                  ],
                  Text(task.instruction(l10n),
                      style: _on(theme.textTheme.bodyLarge)),
                ],
              )),
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
        _StepHeader(
          viewModel: viewModel,
          task: task,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fiber_manual_record,
                  color: AppTokens.error, size: 16),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '${l10n.cameraRecording}  ${viewModel.countdown}s',
                style: _on(theme.textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.bold),
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
              LinearProgressIndicator(
                value: viewModel.taskProgress,
                minHeight: 8,
                backgroundColor:
                    AppTokens.onOverlay.withValues(alpha: AppOpacity.muted),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  StepIllustration(
                    key: ValueKey(task.id),
                    type: task.type,
                    hand: task.isBothHands ? null : task.hands.single,
                    size: const Size(70, 56),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      viewModel.targetHandVisible
                          ? task.instruction(l10n)
                          : (task.isBothHands
                              ? l10n.cameraShowHandsToBegin
                              : l10n.cameraHandNotVisible(
                                  task.handLabel(l10n).toLowerCase())),
                      style: _on(theme.textTheme.bodyMedium),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.onOverlay,
                      side: const BorderSide(color: AppTokens.onOverlay),
                    ),
                    onPressed: viewModel.pausePending
                        ? viewModel.cancelPauseRequest
                        : viewModel.requestPause,
                    icon: Icon(viewModel.pausePending
                        ? Icons.play_arrow
                        : Icons.pause),
                    label: Text(viewModel.pausePending
                        ? l10n.cameraCancelPause
                        : l10n.cameraPause),
                  ),
                ],
              ),
              if (viewModel.pausePending)
                Text(l10n.cameraPausePending,
                    style: _on(theme.textTheme.bodySmall)),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: _OverlayPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.cameraPausedTitle,
                    style: _on(theme.textTheme.headlineSmall)),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.cameraPausedBody,
                    style: _on(theme.textTheme.bodyMedium)),
                if (next != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.cameraNextUp(
                        '${next.handLabel(l10n)} · ${next.name(l10n)}'),
                    style: _on(theme.textTheme.titleMedium),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: viewModel.resume,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.cameraResume),
                ),
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
      ),
    );
  }
}

/// Localized text for a failed quality check.
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
            Text(l10n.cameraFinishing, style: _on(theme.textTheme.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
