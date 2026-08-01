import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA naming: name the three pictured animals aloud.
///
/// The expected answers stay Greek — they are matched against the `el_GR`
/// recognizer's output, so translating them would fail every comparison.
class NamingStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(double score) onScored;

  const NamingStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<NamingStep> createState() => _NamingStepState();
}

class _NamingStepState extends State<NamingStep> {
  final _responses = List<String>.filled(3, '');
  final _listening = List<bool>.filled(3, false);
  final _hintUsed = List<bool>.filled(3, false);
  final _showHint = List<bool>.filled(3, false);
  late SpeechToText _speech;
  Timer? _timeoutTimer;
  int _answeredCount = 0;
  bool _done = false;

  final _names = ['λιοντάρι', 'ρινόκερος', 'καμήλα'];

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    _timeoutTimer = Timer(const Duration(minutes: 2), _finish);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  Future<void> _startListening(int i) async {
    if (_listening[i]) return;
    final available = await _speech.initialize();
    if (!available) return;

    setState(() => _listening[i] = true);
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _responses[i] = r.recognizedWords.trim().toLowerCase();
        });
        if (r.finalResult) {
          _speech.stop();
          _validateField(i);
        }
      },
    );
  }

  void _validateField(int idx) {
    if (_responses[idx].isEmpty) return;
    final userSaid = _responses[idx];
    final correct = userSaid == _names[idx] || userSaid == _names[idx].replaceAll('ά', 'α');
    // Icon carries the verdict, so the message is just the expected animal.
    final expected =
        '${_names[idx][0].toUpperCase()}${_names[idx].substring(1)}';
    if (correct) {
      AppFeedback.success(context, expected);
    } else {
      AppFeedback.error(context, expected);
    }
    _answeredCount++;
    if (_answeredCount >= 3) {
      Future.delayed(const Duration(milliseconds: 500), _finish);
    }
    setState(() => _listening[idx] = false);
  }

  void _showHintFor(int idx) {
    setState(() {
      _showHint[idx] = true;
      _hintUsed[idx] = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHint[idx] = false);
    });
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _timeoutTimer?.cancel();
    double score = 0;
    for (int i = 0; i < 3; i++) {
      final userSaid = _responses[i];
      final correct = userSaid == _names[i] || userSaid == _names[i].replaceAll('ά', 'α');
      if (correct && _hintUsed[i]) {
        score += 0.5;
      } else if (correct) {
        score += 1;
      }
    }
    widget.onScored(score);
    widget.onNext();
  }

  static const _assets = [
    'assets/animals/lion.png',
    'assets/animals/rhino.png',
    'assets/animals/camel.png',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);

    return TestStepScaffold(
      title: l10n.stepTitleNaming,
      instruction: '${l10n.stepInstructionNaming}\n'
          '${l10n.stepInstructionDelayedRecallHint}',
      // Three side-by-side image columns that must share the viewport height.
      scrollable: false,
      onNext: _finish,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(_assets[i], fit: BoxFit.contain),
                  ),
                  const AppGap.xs(),
                  TextField(
                    readOnly: true,
                    // Rebuilt each frame from _responses, which the recognizer
                    // owns; the field is a read-only display, never an input.
                    controller: TextEditingController(
                      text: _responses[i].isEmpty ? '—' : _responses[i],
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixIcon: IconButton(
                        tooltip: l10n.stepSpokenIntoMic,
                        icon: Icon(
                          _listening[i] ? Icons.mic : Icons.mic_none,
                          color: _listening[i] ? semantic.success : null,
                        ),
                        onPressed: !_listening[i] && !_done
                            ? () => _startListening(i)
                            : null,
                      ),
                    ),
                    enableInteractiveSelection: false,
                    showCursor: false,
                  ),
                  const AppGap.xs(),
                  if (_showHint[i])
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: semantic.warningContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        _names[i].toUpperCase(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: semantic.onWarningContainer),
                      ),
                    ),
                  const AppGap.xs(),
                  OutlinedButton(
                    onPressed: !_showHint[i] ? () => _showHintFor(i) : null,
                    child: Text(l10n.stepHint),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
