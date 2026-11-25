import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/continuous_word_listener.dart';
import '../../../common/widgets/widgets.dart';

/// FAB lexical fluency: name as many words starting with Κ as possible in one
/// minute.
///
/// The target letter and the "τέλος" stop word belong to the Greek instrument
/// and are matched against `el_GR` speech, so both stay Greek.
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
    onFailure: () {
      if (mounted) setState(() => _micFailed = true);
    },
  );
  bool _available = false;
  Timer? _timer;
  int _secondsLeft = 60;
  bool _micFailed = false;
  bool _finished = false;
  int _phase = 0; // 0 = instructions, 1 = test, 2 = results

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _available = await _listener.initialize();
    if (mounted) setState(() {});
  }

  /// Words that count: start with Κ and are more than one letter.
  Set<String> get _validWords => _listener.words
      .map((w) => w.trim().toLowerCase())
      .where((w) => w.startsWith('κ') && w.length > 1)
      .toSet();

  static bool _isValid(String w) =>
      w.length > 1 && w.toLowerCase().startsWith('κ');

  Future<void> _toggleListening() async {
    if (!_available || _secondsLeft == 0 || _finished) return;

    // Pauses the mic; the countdown keeps running.
    if (_listener.isListening) {
      await _listener.stop();
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

    final count = _validWords.length;
    final int score;
    if (count > 10) {
      score = 3;
    } else if (count >= 6) {
      score = 2;
    } else if (count >= 3) {
      score = 1;
    } else {
      score = 0;
    }

    if (mounted) setState(() => _phase = 2);

    widget.onScored(score);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _listener.dispose();
    super.dispose();
  }

  /// The score and its explanation. Mirrors the branches in [_finish].
  (int, String) _result(AppLocalizations l10n) {
    final count = _validWords.length;
    if (count > 10) return (3, l10n.fabFluencyResultMany);
    if (count >= 6) return (2, l10n.fabFluencyResultCount(count));
    if (count >= 3) return (1, l10n.fabFluencyResultCount(count));
    return (0, l10n.fabFluencyResultFew);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);

    if (_phase == 0) {
      return TestStepScaffold(
        title: l10n.fabFluencyTitle,
        instruction: l10n.fabFluencyInstructions,
        nextLabel: l10n.stepStart,
        onNext: () => setState(() => _phase = 1),
        child: const SizedBox.shrink(),
      );
    }

    if (_phase == 2) {
      final (score, explanation) = _result(l10n);
      return TestStepScaffold(
        title: l10n.stepResults,
        onNext: widget.onNext,
        child: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.fabScoreValue('$score'),
                  style: theme.textTheme.headlineMedium,
                ),
                const AppGap.sm(),
                Text(
                  explanation,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return TestStepScaffold(
      title: l10n.fabFluencyTitle,
      instruction: l10n.fabFluencyPrompt,
      // The word chips scroll in their own list below.
      scrollable: false,
      nextLabel: l10n.stepFinish,
      onNext: _finish,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$_secondsLeft',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
              // Runs warning-coloured over the last ten seconds.
              color: _secondsLeft <= 10 ? semantic.warning : null,
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
          if (_micFailed && !_listener.isListening && _secondsLeft > 0) ...[
            const AppGap.xs(),
            Text(
              l10n.stepMicClosed,
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: semantic.warning),
            ),
          ],
          const AppGap.md(),
          Align(
            child: FilledButton.tonalIcon(
              onPressed: _secondsLeft == 0 ? null : _toggleListening,
              icon: Icon(_listener.isListening ? Icons.stop : Icons.mic),
              label: Text(
                  _listener.isListening ? l10n.stepFinish : l10n.stepStartMic),
            ),
          ),
        ],
      ),
    );
  }
}
