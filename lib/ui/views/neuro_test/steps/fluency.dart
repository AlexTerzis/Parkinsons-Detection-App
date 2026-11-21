import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/continuous_word_listener.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA verbal fluency: name as many words starting with Χ as possible in one
/// minute. The target letter and the "τέλος" stop word belong to the Greek
/// instrument and are matched against `el_GR` speech, so both stay Greek.
class FluencyStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(int score) onScored;

  const FluencyStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<FluencyStep> createState() => _FluencyStepState();
}

class _FluencyStepState extends State<FluencyStep> {
  late final ContinuousWordListener _listener = ContinuousWordListener(
    localeId: 'el_GR',
    stopWord: 'τέλος',
    onStopWord: _finish,
    onChanged: () {
      if (mounted) setState(() {});
    },
    onFailure: _onMicFailure,
  );
  bool _available = false;
  Timer? _timer;
  int _secondsLeft = 60;
  bool _micFailed = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _available = await _listener.initialize();
    if (mounted) setState(() {});
  }

  void _onMicFailure() {
    if (!mounted) return;
    setState(() => _micFailed = true);
    AppFeedback.error(context, AppLocalizations.of(context)!.stepMicProblem);
  }

  static bool _isValid(String w) =>
      w.length > 1 && w.toLowerCase().startsWith('χ');

  Future<void> _toggleListening() async {
    if (!_available || _secondsLeft == 0 || _finished) return;

    if (_listener.isListening) {
      await _finish();
      return;
    }

    setState(() => _micFailed = false);

    // One countdown for the whole attempt: restarting the mic after a dropout
    // must not hand back time.
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 0) setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _finish();
    });

    await _listener.start();
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    // Awaited so a word being said as time runs out is still counted.
    await _listener.stop();

    final count =
        _listener.words.where(_isValid).map((w) => w.toLowerCase()).toSet().length;
    widget.onScored(count >= 11 ? 1 : 0);
    if (mounted) setState(() {});
    // User presses Next to continue
  }

  @override
  void dispose() {
    _timer?.cancel();
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);
    final listening = _listener.isListening;
    final started = listening || _secondsLeft < 60;

    return TestStepScaffold(
      title: l10n.stepTitleFluency,
      instruction: l10n.stepInstructionFluency,
      // The word chips scroll in their own list below.
      scrollable: false,
      onNext: widget.onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (started)
            Column(
              children: [
                Text(
                  l10n.stepTimeRemaining,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$_secondsLeft',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    // Runs warning-coloured over the last ten seconds.
                    color: _secondsLeft <= 10 ? semantic.warning : null,
                  ),
                ),
              ],
            ),
          if (_micFailed && !listening && _secondsLeft > 0) ...[
            const AppGap.sm(),
            Text(
              l10n.stepMicClosed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: semantic.warning),
            ),
          ],
          const AppGap.xs(),
          Text(
            listening ? l10n.stepSpeakNow : l10n.stepTapMicToStart,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const AppGap.md(),
          // The mic sits with the content rather than floating: it is the
          // control the patient is told to press, so it must be findable.
          Align(
            child: FilledButton.tonalIcon(
              onPressed:
                  _secondsLeft == 0 || _finished ? null : _toggleListening,
              icon: Icon(listening ? Icons.stop : Icons.mic),
              label: Text(listening ? l10n.stepFinish : l10n.stepStartMic),
            ),
          ),
          const AppGap.md(),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: FluencyWordChips(
                  words: _listener.words,
                  pending: _listener.pendingWords,
                  isValid: _isValid,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
