import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA vigilance: the patient taps whenever the letter Α is read out.
///
/// The letter sequence is the instrument's own and stays Greek regardless of
/// the app's language — it is also what the `el-GR` speech synthesizer reads.
class VigilanceStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const VigilanceStep({super.key, required this.onNext, required this.onScored});

  @override
  State<VigilanceStep> createState() => _VigilanceStepState();
}

class _VigilanceStepState extends State<VigilanceStep> {
  // Real MoCA sequence, can be replaced with your own if needed
  static const _sequence = [
    'Φ','Β','Α','Γ','Μ','Ν','Α','Α','Ξ','Κ','Λ','Β','Α','Φ','Α','Κ',
    'Ε','Α','Α','Α','Ξ','Α','Ν','Ο','Φ','Α','Α','Β'
  ];
  int _index = -1;
  String _current = '';
  int _correct = 0;
  int _wrong = 0;
  bool _buttonEnabled = true;
  bool _testDone = false;
  Timer? _letterTimer;
  int _phase = 0;
  late FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage("el-GR");
  }

  @override
  void dispose() {
    _letterTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  void _startPhase2() {
    setState(() {
      _phase = 1;
      _index = -1;
      _correct = 0;
      _wrong = 0;
      _testDone = false;
    });
    _nextLetter();
  }

  void _nextLetter() async {
    if (!mounted) return;
    _letterTimer?.cancel();

    setState(() {
      _index += 1;
      if (_index >= _sequence.length) {
        _testDone = true;
        _current = '';
        _buttonEnabled = false;
        return;
      }
      _current = _sequence[_index];
      _buttonEnabled = true;
    });

    // Speak the letter (always, in black)
    await _tts.speak(_current);

    _letterTimer = Timer(const Duration(milliseconds: 1500), () {
      // Automatically proceed to next letter
      if (!_testDone) _nextLetter();
    });
  }

  void _pressed() {
    if (!_buttonEnabled || _testDone) return;

    setState(() {
      _buttonEnabled = false;
      if (_current == 'Α') {
        _correct++;
      } else {
        _wrong++;
      }
    });
  }

  void _finish() {
    _letterTimer?.cancel();
    // MoCA: 1 point if <=2 mistakes (false positives or misses), else 0
    int missedA = _sequence.where((c) => c == 'Α').length - _correct;
    int totalMistakes = _wrong + missedA;
    int score = totalMistakes <= 2 ? 1 : 0;
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_phase == 0) {
      return TestStepScaffold(
        title: l10n.stepTitleVigilance,
        instruction: '${l10n.stepInstructionVigilance}\n'
            '${l10n.stepInstructionVigilanceLetters}\n'
            '${l10n.stepInstructionVigilanceTap}',
        onNext: _startPhase2,
        child: const SizedBox.shrink(),
      );
    }

    return TestStepScaffold(
      title: l10n.stepTitleVigilance,
      onNext: _finish,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The letter under test. Deliberately the largest thing on screen.
          Text(
            _current.isEmpty ? '—' : _current,
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const AppGap.xl(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _buttonEnabled && !_testDone ? _pressed : null,
              style: FilledButton.styleFrom(
                // Oversized: this is the only control on the screen and it is
                // pressed under time pressure.
                minimumSize: const Size.fromHeight(72),
                textStyle: theme.textTheme.headlineSmall,
              ),
              child: Text(l10n.stepHeardTargetLetter),
            ),
          ),
        ],
      ),
    );
  }
}
