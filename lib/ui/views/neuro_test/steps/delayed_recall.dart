import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';
import 'greek_text.dart';

/// MoCA delayed recall, with the two graded cues: a category hint, then a
/// three-way multiple choice.
///
/// The words, cues and distractors are the instrument's own and stay Greek.
class DelayedRecallStep extends StatefulWidget {
  final void Function(int score, VerbalMemoryResult result) onFinished;
  final List<String> immediateTrials;

  const DelayedRecallStep({
    super.key,
    required this.onFinished,
    required this.immediateTrials,
  });

  @override
  State<DelayedRecallStep> createState() => _DelayedRecallStepState();
}

class _RowAnswer {
  String text = '';
  bool locked = false;
  int? wordIndex; // Which word (index in _words) this row is matched to (if locked)
  int hintStep = 0;
  String? choiceAnswer;

  /// Multiple-choice options, shuffled once when the second cue is revealed.
  /// Shuffling inside `build` reordered the options on every rebuild — every
  /// keystroke and every recognizer partial result — which made them
  /// impossible to read, let alone answer.
  List<String>? shuffledChoices;
}

class _DelayedRecallStepState extends State<DelayedRecallStep> {
  static const _words = [
    'ΠΡΟΣΩΠΟ',
    'ΒΕΛΟΥΔΟ',
    'ΕΚΚΛΗΣΙΑ',
    'ΜΑΡΓΑΡΙΤΑ',
    'ΚΟΚΚΙΝΟ',
  ];
  static const _cues = [
    'ένα μέρος του σώματος',
    'ένα είδος υφάσματος',
    'ένας τόπος λατρείας',
    'ένα είδος λουλουδιού',
    'ένα χρώμα',
  ];
  static const _choices = [
    ['ΠΡΟΣΩΠΟ', 'ΓΕΦΥΡΑ', 'ΛΑΜΠΑ'],
    ['ΒΕΛΟΥΔΟ', 'ΜΕΤΑΞΙ', 'ΜΑΧΑΙΡΙ'],
    ['ΕΚΚΛΗΣΙΑ', 'ΕΡΓΟΣΤΑΣΙΟ', 'ΚΑΦΕΝΕΙΟ'],
    ['ΜΑΡΓΑΡΙΤΑ', 'ΤΟΥΛΙΠΑ', 'ΔΡΥΣ'],
    ['ΚΟΚΚΙΝΟ', 'ΠΡΑΣΙΝΟ', 'ΓΑΛΑΖΙΟ'],
  ];

  final SpeechToText _speech = SpeechToText();
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<_RowAnswer> _rows = List.generate(5, (_) => _RowAnswer());

  bool _speechReady = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _refreshUnclaimedMapping();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
    if (mounted) setState(() => _speechReady = true);
  }

  void _toggleListening(int i) async {
    if (!_speechReady) return;
    if (_rows[i].locked) return;
    if (_controllers[i].text.isNotEmpty) _controllers[i].clear();
    setState(() {
      _rows[i].text = '';
    });
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _rows[i].text = r.recognizedWords;
          _controllers[i].text = r.recognizedWords;
        });
      },
    );
  }

  // Set of all claimed word indices (via text or choice)
  Set<int> _claimedWordIndices() {
    final used = <int>{};
    for (final row in _rows) {
      if (row.locked && row.wordIndex != null) used.add(row.wordIndex!);
      if (row.choiceAnswer != null) {
        final idx = _words.indexWhere((w) => normalizeGreek(w) == normalizeGreek(row.choiceAnswer!));
        if (idx != -1) used.add(idx);
      }
    }
    return used;
  }

  // Assign the next available (unclaimed) word to each unlocked row, for hints/choices
  void _refreshUnclaimedMapping() {
    final claimed = _claimedWordIndices();
    int nextUnclaimed = 0;
    for (int i = 0; i < 5; i++) {
      if (!_rows[i].locked) {
        // Look for the next unclaimed word
        while (nextUnclaimed < _words.length && claimed.contains(nextUnclaimed)) {
          nextUnclaimed++;
        }
        _rows[i].wordIndex = (nextUnclaimed < _words.length) ? nextUnclaimed : null;
        nextUnclaimed++;
      }
    }
  }

  void _onSubmit(int i) {
    if (_rows[i].locked) return;
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
        _rows[i].locked = true;
        _rows[i].wordIndex = matchIdx;
        _rows[i].text = _controllers[i].text;
        _refreshUnclaimedMapping();
      });
    } else {
      setState(() {}); // stay open, can still submit/hint
    }
  }

  void _onHint(int i) {
    if (_rows[i].locked || _rows[i].wordIndex == null) return;
    setState(() {
      if (_rows[i].hintStep == 0) {
        _rows[i].hintStep = 1;
      } else if (_rows[i].hintStep == 1) {
        _rows[i].hintStep = 2;
        _rows[i].shuffledChoices =
            List<String>.from(_choices[_rows[i].wordIndex!])..shuffle(Random());
      }
    });
  }

  void _onChoice(int i, String choice) {
    int? idx = _words.indexWhere((w) => normalizeGreek(w) == normalizeGreek(choice));
    if (idx == -1) return;
    setState(() {
      _rows[i].choiceAnswer = choice;
      _rows[i].locked = true;
      _rows[i].wordIndex = idx;
      _refreshUnclaimedMapping();
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    int score = 0;
    final used = <int>{};
    for (final row in _rows) {
      if (row.locked && row.wordIndex != null && !used.contains(row.wordIndex!)) {
        score++;
        used.add(row.wordIndex!);
      }
    }
    widget.onFinished(
      score,
      VerbalMemoryResult(
        immediateTrials: widget.immediateTrials,
        delayedFreeRecall: _rows.map((r) => r.text).toList().join(' '),
        categoryCueAnswers: Map.fromIterables(
            _words, List.generate(5, (i) => _rows[i].hintStep >= 1 ? _rows[i].text : null)),
        choiceAnswers: Map.fromIterables(_words, _rows.map((r) => r.choiceAnswer)),
        score: score,
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allDone = _rows.every((r) => r.locked);
    _refreshUnclaimedMapping();

    return TestStepScaffold(
      title: l10n.stepTitleDelayedRecall,
      instruction: '${l10n.stepInstructionDelayedRecall}\n'
          '${l10n.stepInstructionDelayedRecallHint}',
      onNext: _finish,
      nextLabel: allDone ? l10n.stepDone : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _row(context, i),
            ),
        ],
      ),
    );
  }

  /// One recall slot: the spoken answer, its two graded cues, and its state.
  Widget _row(BuildContext context, int i) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);
    final row = _rows[i];
    final available = !row.locked && row.wordIndex != null;

    return AppCard(
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
            // Voice only: the MoCA scores recall, not spelling.
            readOnly: true,
            listening: false,
            onListen:
                available && _speechReady ? () => _toggleListening(i) : null,
            hintText: row.wordIndex != null || row.locked
                ? l10n.stepSayWithMic
                : l10n.stepAllWordsFound,
            micTooltip: l10n.stepSayWithMic,
            correct: row.locked ? true : null,
          ),
          const AppGap.xs(),
          if (row.locked)
            Row(
              children: [
                Icon(Icons.check_circle, color: semantic.success, size: 20),
                const AppGap.wide(AppSpacing.xs),
                Text(
                  l10n.stepCorrectAnswer,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: semantic.success),
                ),
              ],
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                FilledButton.tonal(
                  onPressed:
                      available && _controllers[i].text.trim().isNotEmpty
                          ? () => _onSubmit(i)
                          : null,
                  child: Text(l10n.stepSubmit),
                ),
                OutlinedButton.icon(
                  onPressed: available ? () => _onHint(i) : null,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text(l10n.stepHint),
                ),
              ],
            ),
          // First cue: the word's category, worth half a point.
          if (row.hintStep == 1 && available) ...[
            const AppGap.xs(),
            HintPanel(lines: [_cues[row.wordIndex!]]),
          ],
          // Second cue: recognition among three options.
          if (row.hintStep == 2 && available) ...[
            const AppGap.xs(),
            Text(
              l10n.stepInstructionWhichWordWasInList,
              style: theme.textTheme.bodyMedium,
            ),
            RadioGroup<String>(
              groupValue: row.choiceAnswer,
              onChanged: (v) {
                if (v != null) _onChoice(i, v);
              },
              child: Column(
                children: [
                  for (final opt
                      in row.shuffledChoices ?? _choices[row.wordIndex!])
                    RadioListTile<String>(
                      value: opt,
                      title: Text(opt),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class VerbalMemoryResult {
  const VerbalMemoryResult({
    required this.immediateTrials,
    required this.delayedFreeRecall,
    required this.categoryCueAnswers,
    required this.choiceAnswers,
    required this.score,
  });

  final List<String> immediateTrials;
  final String delayedFreeRecall;
  final Map<String, String?> categoryCueAnswers;
  final Map<String, String?> choiceAnswers;
  final int score;

  Map<String, dynamic> toJson() => {
        'immediateTrials': immediateTrials,
        'delayedFreeRecall': delayedFreeRecall,
        'categoryCueAnswers': categoryCueAnswers,
        'choiceAnswers': choiceAnswers,
        'score': score,
      };
}
