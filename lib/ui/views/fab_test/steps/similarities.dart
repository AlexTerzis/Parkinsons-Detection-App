import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// Folds Greek for *keyword* matching: accents away, case down, everything
/// else left alone.
///
/// Deliberately not the battery's shared `normalizeGreek`, which upper-cases
/// and strips non-letters for whole-word equality. The accepted answers here
/// are lowercase stems matched with `contains` ('φρουτ', 'λουλουδ'), so
/// upper-casing would fail every one of them.
String normalizeGreek(String text) {
  return text
      .replaceAll(RegExp(r'[άα]'), 'α')
      .replaceAll(RegExp(r'[έε]'), 'ε')
      .replaceAll(RegExp(r'[ήη]'), 'η')
      .replaceAll(RegExp(r'[ίιϊΐ]'), 'ι')
      .replaceAll(RegExp(r'[όο]'), 'ο')
      .replaceAll(RegExp(r'[ύυϋΰ]'), 'υ')
      .replaceAll(RegExp(r'[ώω]'), 'ω')
      .replaceAll(RegExp(r'[ς]'), 'σ')
      .toLowerCase();
}

/// FAB conceptualisation: say what each set of words has in common.
///
/// The stimuli and the accepted answer stems are the instrument's own and stay
/// Greek — they are matched against `el_GR` speech.
class SimilaritiesStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const SimilaritiesStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<SimilaritiesStep> createState() => _SimilaritiesStepState();
}

class _SimilaritiesStepState extends State<SimilaritiesStep> {
  final List<String> questions = [
    "Μπανάνα – Πορτοκάλι",
    "Τραπέζι – Καρέκλα",
    "Γαρύφαλο – Τριαντάφυλλο – Μαργαρίτα",
  ];
  final List<List<String>> acceptable = [
    // Each sublist holds the acceptable stems for one category.
    ['φρουτ', 'φρουτα', 'καρπο'],
    ['επιπλ', 'επιπλα'],
    ['λουλουδ', 'ανθ', 'ανθος', 'λουλουδια'],
  ];
  final List<String> hints = [
    'Και τα δύο είναι φρούτα',
    '', // Only the first question offers a hint.
    '',
  ];

  int _phase = 0; // 0=Instructions, 1=Test, 2=Results

  int _currentQ = 0;

  /// One controller per question, kept for the life of the step. Rebuilding a
  /// `TextEditingController` inside `build` reset the selection on every
  /// keystroke, so the caret jumped back to the start as the patient typed.
  final List<TextEditingController> _controllers =
      List.generate(3, (_) => TextEditingController());

  final List<bool> _listening = [false, false, false];
  final List<bool> _isCorrect = [false, false, false];
  bool _showHint = false;
  Timer? _timeout;
  int _score = 0;

  late SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    for (final c in _controllers) {
      c.addListener(_checkCorrect);
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    _speech.stop();
    super.dispose();
  }

  void _next() {
    if (_phase == 0) {
      setState(() {
        _phase = 1;
        _currentQ = 0;
      });
    } else if (_phase == 1) {
      if (_currentQ < questions.length - 1) {
        setState(() {
          _currentQ++;
          _showHint = false;
        });
      } else {
        _finish();
      }
    } else {
      widget.onNext();
    }
  }

  void _startListening() async {
    if (_listening[_currentQ]) return;
    final available = await _speech.initialize();
    if (!available) return;
    setState(() => _listening[_currentQ] = true);

    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _controllers[_currentQ].text = r.recognizedWords.trim();
        });
        if (r.finalResult) {
          _speech.stop();
          setState(() => _listening[_currentQ] = false);
        }
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _listening[_currentQ] = false);
  }

  void _checkCorrect() {
    final ans = normalizeGreek(_controllers[_currentQ].text);
    final found = acceptable[_currentQ].any(ans.contains);
    if (found != _isCorrect[_currentQ] && mounted) {
      setState(() => _isCorrect[_currentQ] = found);
    }
  }

  void _showHintFunc() {
    setState(() => _showHint = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _finish() {
    _timeout?.cancel();
    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      final ans = normalizeGreek(_controllers[i].text);
      if (acceptable[i].any(ans.contains)) correct++;
    }
    setState(() {
      _phase = 2;
      _score = correct;
    });
    widget.onScored(_score);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_phase == 0) {
      return TestStepScaffold(
        title: l10n.fabSimilaritiesTitle,
        instruction: l10n.fabSimilaritiesInstructions,
        nextLabel: l10n.stepStart,
        onNext: _next,
        child: const SizedBox.shrink(),
      );
    }

    if (_phase == 2) {
      return TestStepScaffold(
        title: l10n.stepResults,
        onNext: widget.onNext,
        child: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.fabScoreValue('$_score'),
                  style: theme.textTheme.headlineMedium,
                ),
                const AppGap.sm(),
                Text(
                  _score == 0
                      ? l10n.fabNoCorrectAnswers
                      : l10n.fabCorrectAnswersCount(_score),
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

    final isLast = _currentQ >= questions.length - 1;

    return TestStepScaffold(
      title: l10n.fabSimilaritiesTitle,
      nextLabel: isLast ? l10n.stepResults : null,
      onNext: () {
        _checkCorrect();
        _next();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.fabQuestionOfCount(_currentQ + 1, questions.length),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const AppGap.xs(),
          Text(
            questions[_currentQ],
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const AppGap.lg(),
          SpeechTextField(
            controller: _controllers[_currentQ],
            listening: _listening[_currentQ],
            onListen:
                _listening[_currentQ] ? _stopListening : _startListening,
            label: l10n.stepAnswer,
            micTooltip: l10n.stepSayWithMic,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _checkCorrect(),
            correct: _isCorrect[_currentQ],
          ),
          // Only the first question offers a hint, per the instrument.
          if (_currentQ == 0) ...[
            const AppGap.sm(),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _showHint ? null : _showHintFunc,
                icon: const Icon(Icons.lightbulb_outline),
                label: Text(l10n.stepHint),
              ),
            ),
            if (_showHint) HintPanel(lines: [hints[0]]),
          ],
        ],
      ),
    );
  }
}
