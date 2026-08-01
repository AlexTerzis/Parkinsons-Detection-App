import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// FAB motor programming: perform four hand gestures in front of the camera.
///
/// Recognition runs natively behind a platform view; this widget only drives
/// the phases and reports the score.
class GesturesStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(double score) onScored;

  const GesturesStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<GesturesStep> createState() => _GesturesStepState();
}

class _GesturesStepState extends State<GesturesStep> {
  MethodChannel? _channel;
  Timer? _timeout;
  bool _hasPermission = false;
  bool _askedPermission = false;
  bool _testStarted = false;
  bool _testEnded = false;
  bool _success = false;

  final Map<String, int> _gestureCounts = {
    'Thumb_Up': 0,
    'Open_Palm': 0,
    'Pointing_Up': 0,
    'Closed_Fist': 0,
  };
  final Map<String, bool> _gestureDone = {
    'Thumb_Up': false,
    'Open_Palm': false,
    'Pointing_Up': false,
    'Closed_Fist': false,
  };
  String? _lastDetectedGesture;
  double _finalScore = 0.0;

  /// Consecutive frames a gesture must hold before it counts, so a hand
  /// passing through a pose does not register.
  static const int _framesNeeded = 4;

  /// Emoji plus the gesture's name. Not localised: the emoji carries the
  /// meaning and the names match what the native recognizer reports.
  static const gestureLabels = {
    'Thumb_Up': '👍 Thumbs Up',
    'Open_Palm': '🖐️ Open Palm',
    'Pointing_Up': '☝️ Pointing Up',
    'Closed_Fist': '✊ Closed Fist',
  };

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      _askedPermission = true;
    }
    if (!mounted) return;
    setState(() => _hasPermission = status.isGranted);
  }

  void _startTest() {
    setState(() {
      _testStarted = true;
      _testEnded = false;
      _success = false;
      _lastDetectedGesture = null;
      for (final key in _gestureCounts.keys) {
        _gestureCounts[key] = 0;
        _gestureDone[key] = false;
      }
    });
    _timeout = Timer(const Duration(minutes: 1), _finish);
  }

  void _finish() {
    if (_testEnded) return;
    _testEnded = true;
    _timeout?.cancel();
    _timeout = null;

    // 0.75 per gesture, so all four make the full 3.00.
    final score = _gestureDone.values.where((v) => v).length * 0.75;
    _finalScore = score;
    widget.onScored(score);

    setState(() => _success = score == 3.0);

    // Drop the channel so the native side releases the camera.
    _releaseChannel();
  }

  void _releaseChannel() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _releaseChannel();
    super.dispose();
  }

  void _onViewCreated(int id) {
    _channel = MethodChannel('gesture_recognizer_channel_$id');
    _channel!.setMethodCallHandler((call) async {
      if (_testEnded) return;
      if (call.method != 'onGestures') return;

      final List<dynamic> gestures = call.arguments;
      bool updated = false;

      for (final g in _gestureCounts.keys) {
        if (_gestureDone[g]!) continue;
        if (gestures.contains(g)) {
          _gestureCounts[g] = _gestureCounts[g]! + 1;
          if (_gestureCounts[g]! >= _framesNeeded) {
            _gestureDone[g] = true;
            _lastDetectedGesture = g;
            updated = true;
            setState(() {});
            // Clear the confirmation banner after it has been seen.
            Future.delayed(const Duration(milliseconds: 900), () {
              if (mounted && !_testEnded) {
                setState(() => _lastDetectedGesture = null);
              }
            });
          }
        } else {
          // The gesture has to be held; a broken run starts over.
          _gestureCounts[g] = 0;
        }
      }

      if (_gestureDone.values.every((v) => v)) {
        _finish();
      } else if (updated) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);

    if (!_hasPermission) {
      return AppScaffold(
        title: l10n.stepTitleGestures,
        showBackButton: false,
        body: AppErrorState(
          message: _askedPermission
              ? '${l10n.stepCameraPermissionRequired}\n\n'
                  '${l10n.stepCameraPermissionSettings}'
              : l10n.stepCameraPermissionRequired,
          onRetry: _checkPermission,
          retryLabel: l10n.stepCameraPermissionRecheck,
        ),
      );
    }

    if (!_testStarted) {
      return TestStepScaffold(
        title: l10n.stepTitleGestures,
        instruction: l10n.stepInstructionGesturesIntro,
        nextLabel: l10n.stepStart,
        onNext: _startTest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final label in gestureLabels.values)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(label, style: theme.textTheme.titleMedium),
              ),
          ],
        ),
      );
    }

    if (_testEnded) {
      // No platform view in this subtree, which is what releases the camera.
      return TestStepScaffold(
        title: l10n.stepResults,
        nextLabel: l10n.stepContinue,
        onNext: widget.onNext,
        child: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _success ? Icons.check_circle_outline : Icons.info_outline,
                  size: 64,
                  color: _success
                      ? semantic.success
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const AppGap.md(),
                Text(
                  _success
                      ? l10n.stepGesturesAllDetected
                      : l10n.stepTimeUpScore(_finalScore.toStringAsFixed(2)),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Live phase. Content sits over the camera preview, so it uses the fixed
    // overlay colours rather than theme roles, which risk dark-on-dark here.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox.expand(
            child: AndroidView(
              viewType: 'gesture_recognizer_view',
              layoutDirection: TextDirection.ltr,
              onPlatformViewCreated: _onViewCreated,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppTokens.overlayScrim,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.stepInstructionGesturesPerformAll,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: AppTokens.onOverlay),
                    ),
                    const AppGap.sm(),
                    for (final g in _gestureCounts.keys)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            gestureLabels[g]!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTokens.onOverlay,
                              // Struck through once done, so completion does
                              // not rely on the check icon alone.
                              decoration: _gestureDone[g]!
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (_gestureDone[g]!) ...[
                            const AppGap.wide(AppSpacing.xs),
                            const Icon(
                              Icons.check_circle,
                              color: AppTokens.onOverlay,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_lastDetectedGesture != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: semantic.success,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  l10n.stepGestureRecognised(
                    gestureLabels[_lastDetectedGesture!]!,
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: semantic.onSuccess),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
