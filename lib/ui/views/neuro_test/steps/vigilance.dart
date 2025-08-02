import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
    if (_phase == 0) {
      // Instruction phase
      return Scaffold(
        appBar: AppBar(title: const Text('Εγρήγορση')),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  SizedBox(height: 48),
                  Text(
                    'Oδηγίες:\nΑυτό το τεστ μετρά την εγρήγορση και την προσοχή σας.\n'
                    'Θα εμφανιστεί μία σειρά από γράμματα, ένα κάθε φορά.\n'
                    'Πατήστε το κουμπί όταν βλέπετε το γράμμα "Α".\n',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: ElevatedButton(
                onPressed: _startPhase2,
                child: const Text('Επόμενο'),
              ),
            ),
          ],
        ),
      );
    }

    // Phase 2: Test
    return Scaffold(
      appBar: AppBar(title: const Text('Εγρήγορση')),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _current.isEmpty ? '-' : _current,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _buttonEnabled && !_testDone ? _pressed : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(180, 48),
                  ),
                  child: const Text('Άκουσα Α'),
                ),
              ],
            ),
          ),
          if (_phase == 1)
            Positioned(
              right: 16,
              bottom: 16,
              child: ElevatedButton(
                onPressed: _finish,
                child: const Text('Επόμενο'),
              ),
            ),
        ],
      ),
    );
  }
}
