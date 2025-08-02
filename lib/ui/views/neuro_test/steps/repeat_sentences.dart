import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class RepeatSentencesStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(double score) onScored;
  const RepeatSentencesStep({
    Key? key,
    required this.onNext,
    required this.onScored,
  }) : super(key: key);

  @override
  State<RepeatSentencesStep> createState() => _RepeatSentencesStepState();
}

class _RepeatSentencesStepState extends State<RepeatSentencesStep> {
  final SpeechToText _speech = SpeechToText();
  final List<String> _phrases = const [
    'Το μόνο που ξέρω είναι ότι ο Γιάννης είναι αυτός που θα βοηθήσει σήμερα',
    'Η γάτα κρυβόταν πάντα κάτω από τον καναπέ όταν βρίσκονταν σκυλιά μέσα στο δωμάτιο',
  ];

  int _step = 0; // 0: instructions, 1: memorize, 2: recording
  int _phraseIndex = 0;
  bool _listening = false;
  String _recognized = '';
  String _recognizedHistory = '';
  bool _hintUsed = false;
  bool _showHintPhrase = false;
  bool _micUnexpectedlyClosed = false;
  int _memorizeSecondsLeft = 20;
  int _recordingSecondsLeft = 60;
  Timer? _memorizeTimer;
  Timer? _recordingTimer;
  bool _available = false;
  List<double> _phraseScores = [];
  bool _timerStarted = false;

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

  void _goToMemorize() {
    setState(() {
      _step = 1;
      _hintUsed = false;
      _showHintPhrase = false;
      _micUnexpectedlyClosed = false;
      _memorizeSecondsLeft = 20;
      _recordingSecondsLeft = 60;
      _timerStarted = false;
      _recognized = '';
      _recognizedHistory = '';
    });
    _memorizeTimer?.cancel();
    _memorizeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_memorizeSecondsLeft > 1) {
        setState(() => _memorizeSecondsLeft--);
      } else {
        timer.cancel();
        _goToRecording();
      }
    });
  }

  void _skipMemorizeAndRecord() {
    _memorizeTimer?.cancel();
    _goToRecording();
  }

  void _goToRecording() {
    setState(() {
      _step = 2;
      _micUnexpectedlyClosed = false;
      _showHintPhrase = false;
      _recordingSecondsLeft = 60;
      _timerStarted = false;
      // Do NOT clear _recognized or _recognizedHistory here!
    });
    _recordingTimer?.cancel();
    // Timer will be started by the mic, NOT here.
  }

  void _onSpeechStatus(String status) {
    if (_listening &&
        (status == "notListening" || status == "done" || status == "done_no_result")) {
      if (!mounted) return;
      setState(() {
        _micUnexpectedlyClosed = true;
        _listening = false;
      });
      _speech.stop();
    }
  }

  void _onSpeechError(dynamic error) {
    if (!mounted) return;
    setState(() {
      _micUnexpectedlyClosed = true;
      _listening = false;
    });
  }

  Future<void> _startListening() async {
    if (!_available) return;
    setState(() {
      _micUnexpectedlyClosed = false; // Hide message as soon as mic is started
      _listening = true;
      // DO NOT CLEAR _recognized or _recognizedHistory HERE!
    });
    if (!_timerStarted) {
      setState(() {
        _timerStarted = true;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_recordingSecondsLeft > 1) {
          setState(() => _recordingSecondsLeft--);
        } else {
          timer.cancel();
          _stopListening();
          setState(() => _listening = false);
        }
      });
    }
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        if (!mounted) return;
        setState(() {
          if (r.recognizedWords.isNotEmpty) {
            _recognized = r.recognizedWords;
            // Only append if new recognition doesn't already exist at the end
            if (!_recognizedHistory.endsWith(_recognized)) {
              _recognizedHistory = (_recognizedHistory + ' ' + _recognized).trim();
            }
          }
          if (r.finalResult) {
            // Always save the final recognizedWords to history
            if (!_recognizedHistory.endsWith(_recognized)) {
              _recognizedHistory = (_recognizedHistory + ' ' + _recognized).trim();
            }
            _listening = false;
          }
        });
      },
      listenFor: Duration(seconds: _recordingSecondsLeft),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    await _speech.stop();
    if (!mounted) return;
    setState(() => _listening = false);
  }

  void _showHint() {
    setState(() {
      _hintUsed = true;
      _showHintPhrase = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showHintPhrase = false);
    });
  }

  void _clear() {
    setState(() {
      _recognized = '';
      _recognizedHistory = '';
    });
  }

  void _next() async {
    await _stopListening();
    _memorizeTimer?.cancel();
    _recordingTimer?.cancel();

    // Scoring
    final phrase = _phrases[_phraseIndex]
        .toLowerCase()
        .replaceAll(RegExp('[.,«»]'), '')
        .split(RegExp(r'\s+'));
    final actual = _recognizedHistory
        .toLowerCase()
        .replaceAll(RegExp('[.,«»]'), '')
        .split(RegExp(r'\s+'));
    int errors = 0;
    int minLen = min(phrase.length, actual.length);
    for (var i = 0; i < minLen; i++) {
      if (phrase[i] != actual[i]) errors++;
    }
    errors += (phrase.length - actual.length).abs();
    int correctCount = 0;
    for (var w in actual) {
      if (phrase.contains(w)) correctCount++;
    }
    double score = 0;
    if (_recognizedHistory.trim().isEmpty) {
      score = 0;
    } else if (errors <= 1) {
      score = 1;
    } else if (correctCount >= (phrase.length / 2).ceil()) {
      score = 0.5;
    } else {
      score = 0;
    }
    if (_hintUsed) {
      score /= 2;
    }

    _phraseScores.add(score);

    if (_phraseIndex < _phrases.length - 1) {
      setState(() {
        _phraseIndex++;
      });
      _goToMemorize();
    } else {
      double totalScore =
          _phraseScores.isEmpty ? 0 : _phraseScores.reduce((a, b) => a + b);
      widget.onScored(totalScore);
      widget.onNext();
    }
  }

  @override
  void dispose() {
    _memorizeTimer?.cancel();
    _recordingTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) {
      // Instructions Page
      return Scaffold(
        appBar: AppBar(title: const Text('Επανάληψη προτάσεων')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Οδηγίες"),
                const SizedBox(height: 12),
                const Text(
                  "Θα εμφανιστεί μια πρόταση για 20 δευτερόλεπτα. "
                  "Προσπάθησε να τη διαβάσεις και να την απομνημονεύσεις. "
                  "Στη συνέχεια θα σου ζητηθεί να την επαναλάβεις όσο πιο σωστά μπορείς. "
                  "\n Θα έχεις τη δυνατότητα να δεις ξανά την πρόταση για 3 δευτερόλεπτα αν χρειαστεί (Υπόδειξη).\n"
                  " Μπορείς να καθαρίσεις ό,τι έχει πει το μικρόφωνο (Καθαρισμός).\n"
                  " Πάτα 'Επόμενο' για να προχωρήσεις, ακόμα κι αν δεν έχεις απαντήσει.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _goToMemorize,
                  child: const Text("Έναρξη Τεστ"),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_step == 1) {
      // Memorize Phase
      return Scaffold(
        appBar: AppBar(title: const Text('Επανάληψη προτάσεων')),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Text(_phrases[_phraseIndex], textAlign: TextAlign.center),
              const SizedBox(height: 18),
              Text("Χρόνος απομνημόνευσης: $_memorizeSecondsLeft"),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _skipMemorizeAndRecord,
                  child: const Text("Επόμενο"),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } else {
      // Recording Phase
      bool micEnabled = (!_listening && _available && _recordingSecondsLeft > 0);

      return Scaffold(
        appBar: AppBar(title: const Text('Επανάληψη προτάσεων')),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Επανάλαβε την πρόταση που διάβασες. "
                "Πάτησε το μικρόφωνο για να ξεκινήσεις. Αν σταματήσει, πάτησέ το ξανά.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  "Χρόνος που απομένει: $_recordingSecondsLeft δευτ.",
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 12),
              // Recognized Text (plain)
              Text(
                _recognizedHistory.isEmpty ? 'Πείτε την πρόταση...' : _recognizedHistory,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17),
              ),
              if (_showHintPhrase)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _phrases[_phraseIndex],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const Spacer(),
              if (_micUnexpectedlyClosed && !_listening)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Το μικρόφωνο σταμάτησε. Πάτησε το μικρόφωνο για να συνεχίσεις.',
                    style: const TextStyle(color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                ),
              Center(
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: FloatingActionButton(
                    onPressed: micEnabled
                        ? () async {
                            setState(() {
                              _micUnexpectedlyClosed = false; // Hide message as soon as user tries again
                            });
                            await _startListening();
                          }
                        : null,
                    tooltip: 'Εκκίνηση μικροφώνου',
                    child: const Icon(Icons.mic, size: 30),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _showHint,
                        child: const Text('Υπόδειξη'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _clear,
                        child: const Text('Καθαρισμός'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _next,
                        child: Text(
                          _phraseIndex < _phrases.length - 1 ? 'Επόμενο' : 'Τέλος',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    }
  }
}
