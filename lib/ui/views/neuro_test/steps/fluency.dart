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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Πρόβλημα με το μικρόφωνο. Πάτα πάλι το μικρόφωνο για να ξαναδοκιμάσεις.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleListening() async {
    if (!_available || _secondsLeft == 0) return;

    if (_listening) {
      await _speech.stop();
      _finish();
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

  void _finish({bool forceZero = false}) async {
    if (!_listening && !_micUnexpectedlyClosed && _secondsLeft > 0) return;
    _speech.stop();
    setState(() => _listening = false);

    final validWords = _allWords
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.startsWith('χ') && w.length > 1)
        .toSet();

    final count = forceZero ? 0 : validWords.length;
    final score = count >= 11 ? 1 : 0;

    // Use the score!
    widget.onScored(score);
    // User presses Next to continue
  }


  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Λεκτική ευχέρεια')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Λεκτική ευχέρεια: όσες περισσότερες λέξεις μπορείς που να αρχίζουν από το γράμμα "Χ", '
              'χωρίς να πεις κύρια ονόματα ή παράγωγες λέξεις, μέσα σε 1 λεπτό.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            if (_listening || _secondsLeft < 60)
              Column(
                children: [
                  const Text(
                    'Χρόνος που απομένει:',
                    style: TextStyle(fontSize: 15, color: Colors.black),
                  ),
                  Text(
                    '$_secondsLeft',
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (_micUnexpectedlyClosed && !_listening && _secondsLeft > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Το μικρόφωνο έκλεισε. Πάτησε ξανά το μικρόφωνο για να συνεχίσεις.',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _listening
                  ? 'Μιλήστε τώρα! Κάθε λέξη εμφανίζεται αμέσως στην οθόνη.'
                  : 'Πάτα το μικρόφωνο για να ξεκινήσεις.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _allWords.map((w) {
                        final isValid = w.length > 1 && w.toLowerCase().startsWith('χ');
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
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          // Next button bottom right
          Positioned(
            right: 8,
            bottom: 8,
            child: ElevatedButton.icon(
              onPressed: widget.onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Επόμενο'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          // Mic button bottom center
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 28,
            bottom: 72,
            child: FloatingActionButton(
              onPressed: (_secondsLeft == 0) ? null : _toggleListening,
              tooltip: 'Ξεκίνησε ή συνέχισε',
              child: const Icon(Icons.mic),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
