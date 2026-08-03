import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';
import 'greek_text.dart';

/// MoCA immediate recall: hear five words, then repeat them back.
///
/// The word list is the instrument's own and stays Greek — it is spoken to the
/// patient, matched against `el_GR` recognition, and reused verbatim by the
/// delayed-recall step later in the battery.
class ImmediateRecallStep extends StatefulWidget {
  final void Function(List<String> responses, String allTogether) onFinished;

  const ImmediateRecallStep({super.key, required this.onFinished});

  @override
  State<ImmediateRecallStep> createState() => _ImmediateRecallStepState();
}

class _ImmediateRecallStepState extends State<ImmediateRecallStep> {
  static const _words = [
    'ΠΡΟΣΩΠΟ',
    'ΒΕΛΟΥΔΟ',
    'ΕΚΚΛΗΣΙΑ',
    'ΜΑΡΓΑΡΙΤΑ',
    'ΚΟΚΚΙΝΟ',
  ];

  final SpeechToText _speech = SpeechToText();
  final TextEditingController _allController = TextEditingController();
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<bool> _listening = List.filled(5, false);
  final List<bool> _locked = List.filled(5, false);
  final List<int?> _assigned = List.filled(5, null); // Which _words index each row claimed

  bool _speechReady = false;
  int _phase = 0; // 0: instructions, 1: all-together, 2: per-word

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
    if (mounted) setState(() => _speechReady = true);
  }

  Set<int> _claimedWordIndices() {
    final used = <int>{};
    for (final idx in _assigned) {
      if (idx != null) used.add(idx);
    }
    return used;
  }

  void _toggleListeningAll() async {
    if (!_speechReady) return;
    setState(() {
      _allController.clear();
    });
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _allController.text = r.recognizedWords;
        });
      },
    );
  }

  void _toggleListening(int i) async {
    if (!_speechReady || _locked[i]) return;
    setState(() {
      _listening[i] = true;
      _controllers[i].clear();
    });
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _controllers[i].text = r.recognizedWords;
        });
      },
    );
  }

  void _onSubmit(int i) {
    if (_locked[i]) return;
    final input = normalizeGreek(_controllers[i].text);
    final claimed = _claimedWordIndices();
    int matchIdx = -1;
    for (int j = 0; j < _words.length; j++) {
      if (!claimed.contains(j) && normalizeGreek(_words[j]) == input) {
        matchIdx = j;
        break;
      }
    }
    if (matchIdx != -1) {
      setState(() {
        _locked[i] = true;
        _assigned[i] = matchIdx;
      });
    } else {
      setState(() {});
    }
  }

  void _nextPhase() {
    setState(() {
      _phase++;
    });
  }

  void _finish() {
    final answers = _controllers.map((c) => c.text.trim()).toList();
    widget.onFinished(answers, _allController.text.trim());
  }

  @override
  void dispose() {
    _speech.stop();
    _allController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);
    final wordList = _words.join(', ');

    if (_phase == 0) {
      return TestStepScaffold(
        title: l10n.stepTitleImmediateRecall,
        instruction: '${l10n.stepInstructionImmediateRecall}\n\n'
            '${l10n.stepInstructionImmediateRecallPractice}',
        onNext: _nextPhase,
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _words
                .map((w) => Chip(
                      label: Text(w, style: theme.textTheme.titleMedium),
                    ))
                .toList(),
          ),
        ),
      );
    }

    if (_phase == 1) {
      return TestStepScaffold(
        title: l10n.stepTitleImmediateRecall,
        instruction: l10n.stepInstructionSayWordsTogether(wordList),
        onNext: _nextPhase,
        child: SpeechTextField(
          controller: _allController,
          // The recognizer owns this field; typing would bypass the task.
          readOnly: true,
          listening: false,
          onListen: _speechReady ? _toggleListeningAll : null,
          hintText: l10n.stepInstructionSayWords,
          micTooltip: l10n.stepSayWithMic,
        ),
      );
    }

    // Phase 2: one field per word, each locked once it matches.
    final allDone = _locked.every((x) => x);

    return TestStepScaffold(
      title: l10n.stepTitleImmediateRecall,
      instruction: l10n.stepInstructionSayWordsSeparately(wordList),
      onNext: _finish,
      nextLabel: allDone ? l10n.stepDone : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.stepWordNumbered(i + 1),
                      style: theme.textTheme.titleSmall,
                    ),
                    const AppGap.xs(),
                    SpeechTextField(
                      controller: _controllers[i],
                      readOnly: true,
                      listening: _listening[i],
                      onListen:
                          _locked[i] ? null : () => _toggleListening(i),
                      hintText: l10n.stepSayWithMic,
                      micTooltip: l10n.stepSayWithMic,
                      correct: _locked[i] ? true : null,
                    ),
                    const AppGap.xs(),
                    if (_locked[i])
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: semantic.success, size: 20),
                          const AppGap.wide(AppSpacing.xs),
                          Text(
                            l10n.stepCorrectAnswer,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: semantic.success),
                          ),
                        ],
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonal(
                          onPressed: _controllers[i].text.trim().isNotEmpty
                              ? () => _onSubmit(i)
                              : null,
                          child: Text(l10n.stepSubmit),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
