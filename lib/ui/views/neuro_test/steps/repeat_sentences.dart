import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  double _totalScore = 0;
  Timer? _previewTimer;
  Timer? _listenTimer;
  Timer? _hintTimer;
  bool _speechAvailable = false;
  bool _finished = false;

  // Collects all recognized text segments from mic restarts (no dupe)
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _startPreview();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) async {
        if (!_previewPhase &&
            !_finished &&
            _listenSeconds > 0 &&
            _scoreRecognized(_recognizedText) < 1.0 &&
            status == 'notListening') {
          // Mic stopped (by itself) – restart unless correct or finished
          await Future.delayed(const Duration(milliseconds: 100));
          if (!_finished) _startOrRestartListening();
        }
      },
    );
    setState(() {});
  }

  void _startPreview() {
    setState(() {
      _previewPhase = true;
      _previewSeconds = 20;
      _hintUsed = false;
      _recognizedText = '';
      _showHint = false;
      _finished = false;
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

  void _startOrRestartListening() {
    if (!_speechAvailable || _finished) return;
    _speech.listen(
      localeId: 'el_GR',
      onResult: (result) {
        setState(() {
          // Always append any new words to the recognized text
          // If result is empty, do nothing
          if (result.recognizedWords.isNotEmpty) {
            // Avoid repeated phrases: if new part is at the end, just append the difference
            if (_recognizedText.isEmpty) {
              _recognizedText = result.recognizedWords;
            } else {
              final prev = _recognizedText.trim();
              final current = result.recognizedWords.trim();
              // Don't append if current is substring of end of prev
              if (!prev.endsWith(current)) {
                // Try to append only new part
                var newPart = current;
                if (current.startsWith(prev)) {
                  newPart = current.substring(prev.length).trim();
                }
                if (newPart.isNotEmpty) {
                  _recognizedText = (prev + ' ' + newPart).trim();
                }
              }
            }
          }
          if (_scoreRecognized(_recognizedText) >= 1.0) _stopListening();
        });
      },
      listenFor: Duration(seconds: _listenSeconds),
      pauseFor: Duration(seconds: _listenSeconds),
      listenMode: ListenMode.dictation,
      partialResults: true,
    );
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    setState(() {
      _previewPhase = false;
      _listenSeconds = 60;
      _showHint = false;
      _recognizedText = '';
      _finished = false;
    });
    _startOrRestartListening();
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

  String normalizeGreek(String s) {
    return s
        .replaceAll('ά', 'α')
        .replaceAll('έ', 'ε')
        .replaceAll('ή', 'η')
        .replaceAll('ί', 'ι')
        .replaceAll('ό', 'ο')
        .replaceAll('ύ', 'υ')
        .replaceAll('ώ', 'ω')
        .replaceAll('Ά', 'Α')
        .replaceAll('Έ', 'Ε')
        .replaceAll('Ή', 'Η')
        .replaceAll('Ί', 'Ι')
        .replaceAll('Ό', 'Ο')
        .replaceAll('Ύ', 'Υ')
        .replaceAll('Ώ', 'Ω')
        .replaceAll('ϊ', 'ι')
        .replaceAll('ΐ', 'ι')
        .replaceAll('Ϊ', 'Ι')
        .replaceAll('ϋ', 'υ')
        .replaceAll('ΰ', 'υ')
        .replaceAll('Ϋ', 'Υ')
        .replaceAll(RegExp(r'[^\p{L}]', unicode: true), '')
        .toLowerCase()
        .trim();
  }

  double _scoreRecognized(String spoken) {
    final phrase = _phrases[_index];
    final targetWords = Set<String>.from(normalizeGreek(phrase).split(RegExp(r'\s+')));
    final userWords = Set<String>.from(normalizeGreek(spoken).split(RegExp(r'\s+')));
    final correctCount = targetWords.intersection(userWords).length;
    final totalWords = targetWords.length;
    final half = (totalWords / 2).ceil();

    if (correctCount >= totalWords - 1) return 1.0;
    if (correctCount >= half) return 0.5;
    return 0.0;
  }

  Future<void> _stopListening() async {
    if (_finished) return;
    _finished = true;
    await _speech.stop();
    _listenTimer?.cancel();
    _evaluate();
  }

  void _evaluate() {
    double base = _scoreRecognized(_recognizedText);
    double score = base;
    if (_hintUsed) score /= 2;
    _totalScore += score;
  }

  void _showHintPressed() {
    if (_previewPhase) return;
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
  }

  void _clear() {
    setState(() {
      _recognizedText = '';
    });
  }

  void _next() {
    if (_previewPhase) {
      _previewTimer?.cancel();
      _startListening();
      return;
    }
    if (_speech.isListening) return;
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
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_showHint)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Text(
                                phrase,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          Align(
                            alignment: Alignment.center,
                            child: _recognizedText.isEmpty
                                ? const Text(
                                    'Επαναλάβετε την πρόταση',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                                    textAlign: TextAlign.center,
                                  )
                                : Text(
                                    _recognizedText,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: !_previewPhase
                  ? Text(
                      '$_listenSeconds δευτ.',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    )
                  : const SizedBox.shrink(),
            ),
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
              'Σε αυτή τη δοκιμασία θα δείτε μία πρόταση για 20".\n'
              'Μετά από 20", η εγγραφή θα ξεκινήσει αυτόματα για 60" ή έως ότου την επαναλάβετε σωστά.\n'
              'Μπορείτε να πατήσετε "Υπόδειξη" για να εμφανιστεί ξανά η πρόταση για 3" με ποινή 0.5 βαθμού,\n'
              'ή "Καθαρισμός" για να διαγράψετε τα λόγια σας.',
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
