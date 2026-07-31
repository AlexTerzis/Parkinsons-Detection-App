import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class FluencyStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(int score) onScored;

  const FluencyStep({
    Key? key,
    required this.onNext,
    required this.onScored,
  }) : super(key: key);

  @override
  State<FluencyStep> createState() => _FluencyStepState();
}

class _FluencyStepState extends State<FluencyStep> {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  final List<String> _allWords = [];
  Timer? _timer;
  int _secondsLeft = 60;
  bool _micUnexpectedlyClosed = false;
  bool _finished = false;
  int _phase = 0; // 0 = instructions, 1 = test, 2 = results

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (mounted) setState(() {});
  }

  void _onSpeechStatus(String status) {
    if (_listening &&
        (status == "notListening" || status == "done" || status == "done_no_result")) {
      if (_secondsLeft > 0) {
        setState(() {
          _micUnexpectedlyClosed = true;
          _listening = false;
        });
        _speech.stop();
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    setState(() {
      _micUnexpectedlyClosed = true;
      _listening = false;
    });
  }

  void _toggleListening() async {
    if (!_available || _secondsLeft == 0) return;

    if (_listening) {
      await _speech.stop();
    } else {
      setState(() {
        _micUnexpectedlyClosed = false;
        _listening = true;
      });

      if (_timer == null && _secondsLeft > 0) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secondsLeft > 0) {
            setState(() {
              _secondsLeft--;
            });
          }
          if (_secondsLeft <= 0) {
            _finish();
          }
        });
      }

      await _speech.listen(
        onResult: (r) {
          setState(() {
            _transcript = r.recognizedWords;
            for (var w in _transcript
                .split(RegExp(r'[,\s\.]+'))
                .where((w) => w.isNotEmpty)) {
              if (!_allWords.contains(w)) {
                _allWords.add(w);
              }
            }
          });
          if (r.finalResult &&
              r.recognizedWords.toLowerCase().contains('τέλος')) {
            _finish();
          }
        },
        partialResults: true,
        listenMode: ListenMode.confirmation,
        localeId: 'el_GR',
      );
    }
  }

  void _finish() async {
    if (!_listening && !_micUnexpectedlyClosed && _secondsLeft > 0) return;
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    _speech.stop();
    setState(() => _listening = false);

    // Move to results phase
    setState(() => _phase = 2);

    // Evaluate valid words for "Κ" (not name variants etc)
    final validWords = _allWords
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.startsWith('κ') && w.length > 1)
        .toSet();

    int count = validWords.length;
    int score = 0;
    if (count > 10) score = 3;
    else if (count >= 6) score = 2;
    else if (count >= 3) score = 1;
    // else remains 0

    // Use the score!
    widget.onScored(score);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  String resultMessage() {
    final validWords = _allWords
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.startsWith('κ') && w.length > 1)
        .toSet();

    int count = validWords.length;
    if (count > 10) return "Σκορ: 3\nΠερισσότερες από 10 λέξεις!";
    if (count >= 6) return "Σκορ: 2\n$count λέξεις.";
    if (count >= 3) return "Σκορ: 1\n$count λέξεις.";
    return "Σκορ: 0\nΛιγότερες από 3 λέξεις.";
  }

  @override
  Widget build(BuildContext context) {
    // --- Instructions ---
    String instructions = '''
2. Λεκτική ευφράδεια (νοητική ευελιξία):

«Πείτε όσες περισσότερες λέξεις μπορείτε που να αρχίζουν από το γράμμα Κ, εκτός από επώνυμα και κύρια ονόματα»

- Αν ο ασθενής δεν δώσει απάντηση εντός 5 sec, πείτε για παράδειγμα καράβι.
- Αν ο ασθενής σταματήσει για περισσότερο από 10sec παρακινείστε τον λέγοντας «οποιαδήποτε λέξη αρχίζει από Κ».
- Ο επιτρεπόμενος χρόνος είναι 60 sec.

Βαθμολόγηση:
3: Περισσότερες από 10 λέξεις
2: 6 έως 10 λέξεις
1: 3 με 5 λέξεις
0: Λιγότερες από 3 λέξεις
''';

    return Scaffold(
      appBar: AppBar(title: const Text('Λεκτική ευφράδεια')),
      body: Stack(
        children: [
          // PHASE 0: Instructions and start
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
                      onPressed: () => setState(() => _phase = 1),
                      child: const Text('Έναρξη'),
                    ),
                  ],
                ),
              ),
            ),
          // PHASE 1: Main test, large mic button, words etc
          if (_phase == 1)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Λέξεις που ξεκινούν με 'Κ'",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Χρόνος που απομένει: $_secondsLeft',
                    style: const TextStyle(fontSize: 24, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 12),
                  // Words shown as chips, scrollable
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _allWords.map((w) {
                              final isValid = w.length > 1 && w.toLowerCase().startsWith('κ');
                              return Chip(
                                label: Text(w),
                                backgroundColor: isValid ? Colors.green[200] : null,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Feedback for mic issue
                  if (_micUnexpectedlyClosed && !_listening && _secondsLeft > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Το μικρόφωνο έκλεισε. Πάτησε ξανά το μικρόφωνο για να συνεχίσεις.',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Big mic button
                  ElevatedButton(
                    onPressed: (_secondsLeft == 0) ? null : _toggleListening,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 120),
                      shape: const CircleBorder(),
                      backgroundColor: _listening ? Colors.red : Colors.blue,
                    ),
                    child: Icon(
                      _listening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _finish,
                    child: const Text('Τερματισμός'),
                  ),
                ],
              ),
            ),
          // PHASE 2: Results card only!
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
