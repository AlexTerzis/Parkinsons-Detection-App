import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
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
  bool _listening = false;
  bool _finished = false;

  // Stores all segments and recognized partials
  final List<String> _segments = [];
  String _currentPartial = '';
  String _recognizedText = '';
  bool _restartLock = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _startPreview();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) async {
        // If stopped (e.g. due to silence), allow restart via button
        if (!_previewPhase && !_finished && status == 'notListening') {
          setState(() => _listening = false);
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
      _segments.clear();
      _currentPartial = '';
      _recognizedText = '';
      _showHint = false;
      _finished = false;
      _listening = false;
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

  void _startListening() {
    if (!_speechAvailable) return;
    setState(() {
      _previewPhase = false;
      _listenSeconds = 60;
      _showHint = false;
      _segments.clear();
      _currentPartial = '';
      _recognizedText = '';
      _finished = false;
      _listening = true;
    });
    _speech.listen(
      localeId: 'el_GR',
      onResult: _processResult,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 60),
      listenMode: ListenMode.dictation,
      partialResults: true,
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

  void _processResult(SpeechRecognitionResult result) {
    setState(() {
      _currentPartial = result.recognizedWords;
      if (result.finalResult) {
        final trimmed = _currentPartial.trim();
        if (trimmed.isNotEmpty) _segments.add(trimmed);
        _currentPartial = '';
      }
      _recognizedText = (_segments + [_currentPartial]).join(' ').trim();
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

    if (correctCount >= totalWords) return 1.0; // Require all
    if (correctCount >= half) return 0.5;
    return 0.0;
  }

  Future<void> _stopListening() async {
    if (_finished) return;
    _finished = true;
    final trimmed = _currentPartial.trim();
    if (trimmed.isNotEmpty) _segments.add(trimmed);
    _currentPartial = '';
    _recognizedText = _segments.join(' ').trim();
    await _speech.stop();
    _listenTimer?.cancel();
    setState(() => _listening = false);
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
      _segments.clear();
      _currentPartial = '';
      _recognizedText = '';
    });
  }

  void _next() {
    if (_previewPhase) {
      _previewTimer?.cancel();
      _startListening();
      return;
    }
    if (_speech.isListening) _stopListening();
    else if (_index < _phrases.length - 1) {
      setState(() => _index++);
      _startPreview();
    } else {
      widget.onScored(_totalScore);
      widget.onNext();
    }
  }

  void _startMicManually() {
    if (!_previewPhase && !_listening && !_finished && _listenSeconds > 0) {
      _startListening();
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
                  child: Text(_previewPhase ? 'Έναρξη' : 'Επόμενο'),
                ),
                if (!_previewPhase && !_listening && !_finished && _listenSeconds > 0)
                  ElevatedButton(
                    onPressed: _startMicManually,
                    child: const Text('Ξανα-Άκου'),
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
