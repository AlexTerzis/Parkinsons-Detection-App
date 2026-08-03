import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// The MoCA digit-span task, shared by the forward and backward variants.
///
/// The two were separate 230-line files differing only in the digits, the
/// expected answer and two sentences of instruction. Everything else — the
/// two-phase memorise/recall flow, the speech capture, the 2-second hint, the
/// one-minute timeout and the half-point-for-a-hint scoring — was duplicated
/// verbatim, which is how the mic icon ended up different between them.
class DigitSpanStep extends StatefulWidget {
  const DigitSpanStep({
    super.key,
    required this.onNext,
    required this.onScored,
    required this.sequence,
    required this.expectedAnswer,
    required this.memoriseInstruction,
    required this.recallInstruction,
  });

  final VoidCallback onNext;
  final void Function(double score) onScored;

  /// Digits as shown to the patient, space-separated.
  final String sequence;

  /// Correct response with the separators stripped. For the backward variant
  /// this is [sequence] reversed, which is the whole point of the task.
  final String expectedAnswer;

  final String Function(AppLocalizations l10n) memoriseInstruction;
  final String Function(AppLocalizations l10n) recallInstruction;

  @override
  State<DigitSpanStep> createState() => _DigitSpanStepState();
}

class _DigitSpanStepState extends State<DigitSpanStep> {
  final _controller = TextEditingController();
  late final SpeechToText _speech;
  Timer? _timeout;
  Timer? _hintTimer;
  bool _hintUsed = false;
  bool _showHint = false;
  bool _listening = false;

  /// False while the digits are on screen to be memorised, true during recall.
  bool _recalling = false;

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _hintTimer?.cancel();
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  void _startRecall() {
    setState(() => _recalling = true);
    _timeout = Timer(const Duration(minutes: 1), _submit);
  }

  Future<void> _startListening() async {
    if (_listening) return;
    final available = await _speech.initialize();
    if (!available) return;
    setState(() => _listening = true);

    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          // Digits only: the recognizer returns them as words as often as not.
          final raw = r.recognizedWords.replaceAll(RegExp(r'[^\d]'), '');
          _controller.text = raw.split('').join(' ');
        });
        if (r.finalResult) {
          _speech.stop();
          setState(() => _listening = false);
        }
      },
    );
  }

  void _revealHint() {
    setState(() {
      _showHint = true;
      _hintUsed = true;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _submit() {
    _timeout?.cancel();
    final answer = _controller.text.replaceAll(' ', '');
    final score = answer == widget.expectedAnswer ? (_hintUsed ? 0.5 : 1.0) : 0.0;
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (!_recalling) {
      return TestStepScaffold(
        title: l10n.stepTitleDigits,
        instruction: widget.memoriseInstruction(l10n),
        onNext: _startRecall,
        child: Center(child: _digits(theme)),
      );
    }

    return TestStepScaffold(
      title: l10n.stepTitleDigits,
      instruction: widget.recallInstruction(l10n),
      onNext: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              hintText: l10n.stepInstructionWriteOrSayNumbers,
              suffixIcon: IconButton(
                tooltip: l10n.stepSayWithMic,
                icon: Icon(
                  _listening ? Icons.mic : Icons.mic_none,
                  color:
                      _listening ? AppSemanticColors.of(context).success : null,
                ),
                onPressed: _listening ? null : _startListening,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const AppGap.md(),
          Align(
            child: OutlinedButton.icon(
              onPressed: _showHint ? null : _revealHint,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(l10n.stepHint),
            ),
          ),
          if (_showHint) ...[
            const AppGap.md(),
            Align(child: _digits(theme, hint: true)),
          ],
        ],
      ),
    );
  }

  /// The sequence itself. Wide letter spacing so the digits read as separate
  /// items to memorise rather than as one number.
  Widget _digits(ThemeData theme, {bool hint = false}) {
    final semantic = AppSemanticColors.of(context);
    final text = Text(
      widget.sequence,
      style: theme.textTheme.displaySmall?.copyWith(
        letterSpacing: 12,
        fontWeight: FontWeight.w600,
        color: hint ? semantic.onWarningContainer : null,
      ),
    );

    if (!hint) return text;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: semantic.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: text,
    );
  }
}
