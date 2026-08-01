import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA Serial 7s - dynamic, allows speaking or typing.
/// Each subtraction uses user's previous input.
/// 5 or 4 correct = 3 pts, 3 or 2 = 2 pts, 1 = 1 pt, 0 = 0.
class SubtractStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const SubtractStep({super.key, required this.onNext, required this.onScored});

  @override
  State<SubtractStep> createState() => _SubtractStepState();
}

class _SubtractStepState extends State<SubtractStep> {
  final _controllers = List.generate(5, (_) => TextEditingController());
  final _focusNodes = List.generate(5, (_) => FocusNode());
  final List<bool> _listening = List.filled(5, false);
  late SpeechToText _speech;
  Timer? _timeout;
  bool _submitted = false;

  static const _answers = [93, 86, 79, 72, 65];

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    _timeout = Timer(const Duration(minutes: 2), _submit);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _speech.stop();
    super.dispose();
  }

  Future<void> _listenField(int idx) async {
    if (_listening[idx]) return;
    if (_listening.contains(true)) return; // Only one at a time
    final available = await _speech.initialize();
    if (!available) return;
    setState(() => _listening[idx] = true);
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        final recognized = r.recognizedWords.replaceAll(RegExp(r'[^\d]'), '');
        setState(() => _controllers[idx].text = recognized);
        if (r.finalResult) {
          _speech.stop();
          setState(() => _listening[idx] = false);
          _focusNodes[idx].unfocus();
        }
      },
    );
  }

  void _submit() {
    if (_submitted) return;
    _timeout?.cancel();

    int correct = 0;
    for (int i = 0; i < 5; i++) {
      final val = int.tryParse(_controllers[i].text.trim());
      if (val == _answers[i]) correct++;
    }
    // MoCA serial 7s: 4-5 correct = 3 pts, 2-3 = 2, 1 = 1, none = 0.
    final int score;
    if (correct >= 4) {
      score = 3;
    } else if (correct >= 2) {
      score = 2;
    } else if (correct == 1) {
      score = 1;
    } else {
      score = 0;
    }

    setState(() => _submitted = true);
    widget.onScored(score);
    widget.onNext();
  }

  int? _leftNumber(int i) {
    if (i == 0) return 100;
    final prev = int.tryParse(_controllers[i - 1].text.trim());
    return prev;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return TestStepScaffold(
      title: l10n.stepTitleSubtract,
      instruction: l10n.stepInstructionSubtract,
      onNext: _submit,
      nextEnabled: !_submitted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(5, (i) {
          final left = _leftNumber(i);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                // Left side: previous answer or 100.
                SizedBox(
                  width: 56,
                  child: Text(
                    left != null ? '$left' : '—',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const AppGap.wide(AppSpacing.xs),
                Text('− 7 =', style: theme.textTheme.titleMedium),
                const AppGap.wide(AppSpacing.xs),
                Expanded(
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    enabled: !_submitted,
                    onChanged: (_) {
                      // Refreshes the left-hand number of the next row.
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        tooltip: l10n.stepSayWithMic,
                        icon: Icon(
                          _listening[i] ? Icons.mic : Icons.mic_none,
                          color: _listening[i]
                              ? AppSemanticColors.of(context).success
                              : null,
                        ),
                        onPressed: _submitted || _listening.contains(true)
                            ? null
                            : () => _listenField(i),
                      ),
                    ),
                    onSubmitted: (_) => i == 4 ? _submit() : null,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
