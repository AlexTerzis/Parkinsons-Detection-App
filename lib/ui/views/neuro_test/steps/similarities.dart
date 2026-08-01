import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

// Helper for more forgiving Greek matching
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

class SimilaritiesStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(double score) onScored;
  const SimilaritiesStep({super.key, required this.onNext, required this.onScored});

  @override
  State<SimilaritiesStep> createState() => _SimilaritiesStepState();
}

class _SimilaritiesStepState extends State<SimilaritiesStep> {
  final _controllers = [TextEditingController(), TextEditingController()];
  late SpeechToText _speech;
  final _listening = [false, false];
  final _showHint = [false, false];
  final _hintUsed = [false, false];
  Timer? _timeout;

  // Acceptable answers
  static const _hints1 = [
    'Μέσα μεταφοράς',
    'Οχήματα',
    'Μετακινούν ανθρώπους',
    'Μέσο κυκλοφορίας'
  ];
  static const _hints2 = [
    'Μετρούν',
    'Μέσα μέτρησης',
    'Μετρούν χρόνο και μήκος',
    'Όργανα μέτρησης'
  ];

  bool _isCorrect1 = false;
  bool _isCorrect2 = false;

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    _timeout = Timer(const Duration(minutes: 2), _submit);

    // Live check as user types
    _controllers[0].addListener(_checkCorrect);
    _controllers[1].addListener(_checkCorrect);
  }

  void _checkCorrect() {
    setState(() {
      final a1 = normalizeGreek(_controllers[0].text);
      final a2 = normalizeGreek(_controllers[1].text);

      _isCorrect1 = a1.contains('μεταφορ') ||
          a1.contains('οχη') ||
          a1.contains('μετακιν') ||
          a1.contains('κυκλοφορ');

      _isCorrect2 = a2.contains('μετρ') ||
          a2.contains('χρον') ||
          a2.contains('μηκοσ') ||
          a2.contains('ακριβεια') ||
          a2.contains('μετρηση');
    });
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

  Future<void> _startListening(int idx) async {
    if (_listening[idx]) return;
    final available = await _speech.initialize();
    if (!available) return;
    setState(() => _listening[idx] = true);

    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _controllers[idx].text = r.recognizedWords.trim();
        });
        if (r.finalResult) {
          _speech.stop();
          setState(() => _listening[idx] = false);
        }
      },
    );
  }

  void _showHintFunc(int idx) {
    setState(() {
      _showHint[idx] = true;
      _hintUsed[idx] = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint[idx] = false);
    });
  }

  void _submit() {
    _timeout?.cancel();
    double score = 0;
    if (_isCorrect1) {
      score += _hintUsed[0] ? 0.5 : 1.0;
    }
    if (_isCorrect2) {
      score += _hintUsed[1] ? 0.5 : 1.0;
    }
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TestStepScaffold(
      title: l10n.stepTitleSimilarities,
      instruction: '${l10n.stepInstructionSimilarities}\n'
          '${l10n.stepTypeOrUseMic}\n'
          '${l10n.stepInstructionSimilaritiesHint}\n'
          '${l10n.stepInstructionSimilaritiesExample}',
      onNext: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pair(
            context,
            // The word pairs are the instrument's stimuli and stay Greek.
            prompt: '1) Τρένο – Ποδήλατο',
            index: 0,
            hints: _hints1,
            correct: _isCorrect1,
            textInputAction: TextInputAction.next,
          ),
          const AppGap.lg(),
          _pair(
            context,
            prompt: '2) Ρολόι – Χάρακας',
            index: 1,
            hints: _hints2,
            correct: _isCorrect2,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
    );
  }

  /// One stimulus pair: the prompt, the answer field and its hint panel.
  Widget _pair(
    BuildContext context, {
    required String prompt,
    required int index,
    required List<String> hints,
    required bool correct,
    required TextInputAction textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(prompt, style: theme.textTheme.titleMedium),
        const AppGap.xs(),
        SpeechTextField(
          controller: _controllers[index],
          listening: _listening[index],
          onListen: () => _startListening(index),
          label: l10n.stepAnswer,
          micTooltip: l10n.stepSayWithMic,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          correct: correct,
        ),
        const AppGap.xs(),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _showHint[index] ? null : () => _showHintFunc(index),
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(l10n.stepHint),
          ),
        ),
        if (_showHint[index]) HintPanel(lines: hints),
      ],
    );
  }
}
