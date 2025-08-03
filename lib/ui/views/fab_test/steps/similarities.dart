import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  final Function(int score) onScored;
  const SimilaritiesStep({super.key, required this.onNext, required this.onScored});

  @override
  State<SimilaritiesStep> createState() => _SimilaritiesStepState();
}

class _SimilaritiesStepState extends State<SimilaritiesStep> {
  final List<String> questions = [
    "Μπανάνα – Πορτοκάλι",
    "Τραπέζι – Καρέκλα",
    "Γαρύφαλο – Τριαντάφυλλο – Μαργαρίτα"
  ];
  final List<List<String>> acceptable = [
    // Each sublist contains all acceptable keywords for a category
    ['φρουτ', 'φρουτα', 'καρπο'],
    ['επιπλ', 'επιπλα'],
    ['λουλουδ', 'ανθ', 'ανθος', 'λουλουδια'],
  ];
  final List<String> hints = [
    'Και τα δύο είναι φρούτα',
    '', // No hints for the others
    '',
  ];

  int _phase = 0; // 0=Instructions, 1=Test, 2=Results
  int _currentQ = 0;
  final List<String> _answers = ['', '', ''];
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
  }

  @override
  void dispose() {
    _timeout?.cancel();
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
        setState(() => _currentQ++);
      } else {
        _finish();
      }
    } else if (_phase == 2) {
      widget.onNext();
    }
  }

  void _startListening() async {
    if (_listening[_currentQ]) return;
    final available = await _speech.initialize();
    if (!available) return;
    setState(() {
      _listening[_currentQ] = true;
    });
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _answers[_currentQ] = r.recognizedWords.trim();
        });
        if (r.finalResult) {
          _speech.stop();
          setState(() {
            _listening[_currentQ] = false;
          });
        }
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _listening[_currentQ] = false;
    });
  }

  void _checkCorrect() {
    String ans = normalizeGreek(_answers[_currentQ]);
    bool found = acceptable[_currentQ].any((key) => ans.contains(key));
    setState(() => _isCorrect[_currentQ] = found);
  }

  void _showHintFunc() {
    setState(() => _showHint = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _finish() {
    _timeout?.cancel();
    // Check all answers
    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      String ans = normalizeGreek(_answers[i]);
      if (acceptable[i].any((key) => ans.contains(key))) {
        correct++;
      }
    }
    setState(() {
      _phase = 2;
      _score = correct;
    });
    widget.onScored(_score);
  }

  String resultMessage() {
    if (_score == 3) return "Σκορ: 3\n3 σωστές απαντήσεις.";
    if (_score == 2) return "Σκορ: 2\n2 σωστές απαντήσεις.";
    if (_score == 1) return "Σκορ: 1\n1 σωστή απάντηση.";
    return "Σκορ: 0\nΚαμία σωστή απάντηση.";
  }

  @override
  Widget build(BuildContext context) {
    String instructions = '''
1. Ομοιότητες (αντιληπτική ικανότητα):

«Τι κοινό έχουν;»
Παραδείγματα: μπανάνα - πορτοκάλι = φρούτα.

• Μπορείτε να πληκτρολογήσετε ή να χρησιμοποιήσετε το μικρόφωνο.
• Πατήστε "Υπόδειξη" μόνο στην 1η ερώτηση αν θέλετε βοήθεια.

Βαθμολόγηση:
3: 3 σωστές απαντήσεις
2: 2 σωστές απαντήσεις
1: 1 σωστή απάντηση
0: Καμία σωστή απάντηση
''';

    return Scaffold(
      appBar: AppBar(title: const Text('Ομοιότητες')),
      body: Stack(
        children: [
          // Phase 0: Instructions
          if (_phase == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      instructions,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _next,
                      child: const Text('Έναρξη'),
                    ),
                  ],
                ),
              ),
            ),
          // Phase 1: Test, step by step
          if (_phase == 1)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Ερώτηση ${_currentQ + 1} από 3",
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    questions[_currentQ],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Answer field & mic
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: TextField(
                          controller: TextEditingController(text: _answers[_currentQ]),
                          onChanged: (val) {
                            _answers[_currentQ] = val;
                            _checkCorrect();
                          },
                          decoration: InputDecoration(
                            labelText: 'Απάντηση',
                            border: const OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _checkCorrect(),
                          style: const TextStyle(fontSize: 19),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _listening[_currentQ] ? _stopListening : _startListening,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          minimumSize: const Size(64, 64),
                          backgroundColor: _listening[_currentQ] ? Colors.red : Colors.blue,
                        ),
                        child: Icon(
                          _listening[_currentQ] ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      // Only show hint button for the first question
                      if (_currentQ == 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: OutlinedButton(
                            onPressed: _showHintFunc,
                            child: const Text('Υπόδειξη'),
                          ),
                        ),
                      if (_isCorrect[_currentQ])
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.check_circle, color: Colors.green, size: 32),
                        ),
                    ],
                  ),
                  // Show hint if requested
                  if (_showHint && _currentQ == 0)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Υπόδειγμα: ${hints[0]}', style: const TextStyle(fontSize: 16)),
                    ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      _checkCorrect();
                      _next();
                    },
                    child: Text(_currentQ < questions.length - 1 ? 'Επόμενο' : 'Αποτελέσματα'),
                  ),
                ],
              ),
            ),
          // Phase 2: Results
          if (_phase == 2)
            Center(
              child: Card(
                color: Colors.white,
                elevation: 8,
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Αποτελέσματα", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 18),
                      Text(
                        resultMessage(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: widget.onNext,
                        child: const Text("Επόμενο"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
