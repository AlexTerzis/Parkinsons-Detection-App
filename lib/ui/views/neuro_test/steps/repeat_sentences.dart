import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

// =========== FLOW WIDGET ===========
class RepeatSentencesStep extends StatefulWidget {
  final void Function(double score) onScored;
  final VoidCallback onNext;

  const RepeatSentencesStep({
    Key? key,
    required this.onScored,
    required this.onNext,
  }) : super(key: key);

  @override
  State<RepeatSentencesStep> createState() => _RepeatSentencesStepState();
}

class _RepeatSentencesStepState extends State<RepeatSentencesStep> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    return _started
        ? _RepeatSentencesStepInternal(
            onScored: widget.onScored,
            onNext: widget.onNext,
          )
        : RepeatInstructionsScreen(
            onStart: () => setState(() => _started = true),
          );
  }
}

// =========== ACTUAL TEST STEP ===========
class _RepeatSentencesStepInternal extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(double score) onScored;

  const _RepeatSentencesStepInternal({Key? key, required this.onNext, required this.onScored}) : super(key: key);

  @override
  State<_RepeatSentencesStepInternal> createState() => _RepeatSentencesStepInternalState();
}

class _RepeatSentencesStepInternalState extends State<_RepeatSentencesStepInternal> {
  final SpeechToText _speech = SpeechToText();
  final List<String> _phrases = const [
    'Το μόνο που ξέρω είναι ότι ο Γιάννης είναι αυτός που θα βοηθήσει σήμερα.',
    'Η γάτα κρυβόταν πάντα κάτω από τον καναπέ όταν βρίσκονταν σκυλιά μέσα στο δωμάτιο.',
  ];

  int _index = 0;
  bool _previewPhase = true;
  bool _hintUsed = false;
  bool _showHint = false;
  int _previewSeconds = 20;
  int _listenSeconds = 60;
  String _recognized = '';
  double _totalScore = 0;
  Timer? _previewTimer;
  Timer? _listenTimer;
  Timer? _hintTimer;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _startPreview();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  void _startPreview() {
    setState(() {
      _previewPhase = true;
      _previewSeconds = 20;
      _hintUsed = false;
      _recognized = '';
      _showHint = false;
    });
    _previewTimer?.cancel();
    _previewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_previewSeconds == 0) {
        timer.cancel();
        _startListening();
      } else {
        setState(() => _previewSeconds--);
      }
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    setState(() {
      _previewPhase = false;
      _listenSeconds = 60;
      _showHint = false;
    });
    _speech.listen(
      localeId: 'el_GR',
      onResult: (result) {
        setState(() => _recognized = result.recognizedWords);
        // Optional: stop if perfect or half correct
        // if (_scoreRecognized(_recognized) >= 1.0) _stopListening();
        if (_scoreRecognized(_recognized) >= 1.0) _stopListening();
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
    );
    _listenTimer?.cancel();
    _listenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_listenSeconds == 0) {
        timer.cancel();
        _stopListening();
      } else {
        setState(() => _listenSeconds--);
      }
    });
  }

  double _scoreRecognized(String spoken) {
    String normalize(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r"[^\p{L}\s]", unicode: true), '')
        .trim();
    final target = normalize(_phrases[_index]).split(RegExp(r'\\s+'));
    final words = normalize(spoken).split(RegExp(r'\\s+'));
    int match = 0;
    for (int i = 0; i < min(target.length, words.length); i++) {
      if (target[i] == words[i]) match++;
    }
    final halfCorrect = match >= (target.length / 2);
    final allCorrect = match >= (target.length - 1);

    if (allCorrect) return 1.0;
    if (halfCorrect) return 0.5;
    return 0.0;
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    _listenTimer?.cancel();
    _evaluate();
  }

  void _evaluate() {
    double base = _scoreRecognized(_recognized);
    double score = base;
    if (_hintUsed) score /= 2;
    _totalScore += score;
  }

  void _showHintPressed() {
    if (_previewPhase) return; // ignore during preview
    setState(() {
      _showHint = true;
      _hintUsed = true;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showHint = false;
      });
    });
    // DO NOT clear recognized or reset timer
  }

  void _clear() {
    // Only clear recognized text, do not reset timer or restart recording
    setState(() {
      _recognized = '';
    });
  }

  void _next() {
    if (_previewPhase) {
      // Skip preview and start recording immediately
      _previewTimer?.cancel();
      _startListening();
      return;
    }
    if (_speech.isListening) return; // prevent skipping while recording
    if (_index < _phrases.length - 1) {
      setState(() => _index++);
      _startPreview();
    } else {
      widget.onScored(_totalScore);
      widget.onNext();
    }
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _listenTimer?.cancel();
    _hintTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrase = _phrases[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('Επανάληψη προτάσεων')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Show instructions ONLY during recording (not during preview)
            if (!_previewPhase)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Επαναλάβετε ακριβώς την πρόταση που εμφανίστηκε.\n'
                  'Η εγγραφή διαρκεί 60" ή μέχρι να την πείτε σωστά. Μισό βαθμό αν πείτε τα μισά σωστά.',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: Center(
                child: _previewPhase
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            phrase,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$_previewSeconds δευτ.',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_showHint)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                phrase,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _recognized.isEmpty
                                  ? 'Ακούω… ($_listenSeconds δευτ.)'
                                  : _recognized,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: (!_previewPhase && !_showHint) ? _showHintPressed : null,
                  child: const Text('Υπόδειξη'),
                ),
                ElevatedButton(
                  onPressed: !_previewPhase ? _clear : null,
                  child: const Text('Καθαρισμός'),
                ),
                ElevatedButton(
                  onPressed: _next,
                  child: const Text('Επόμενο'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========== INSTRUCTIONS SCREEN ===========
class RepeatInstructionsScreen extends StatelessWidget {
  final VoidCallback onStart;

  const RepeatInstructionsScreen({Key? key, required this.onStart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Οδηγίες')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Σε αυτή τη δοκιμασία θα δείτε μία πρόταση για 20\".\n'
              'Μετά από 20\", η εγγραφή θα ξεκινήσει αυτόματα για 60\" ή έως ότου την επαναλάβετε σωστά.\n'
              'Μπορείτε να πατήσετε \"Υπόδειξη\" για να εμφανιστεί ξανά η πρόταση για 3\" με ποινή 0.5 βαθμού,\n'
              'ή \"Καθαρισμός\" για επανεκκίνηση της εγγραφής.',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: onStart,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('Επόμενο', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
