import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class NamingStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(double score) onScored;

  const NamingStep({
    Key? key,
    required this.onNext,
    required this.onScored,
  }) : super(key: key);

  @override
  _NamingStepState createState() => _NamingStepState();
}

class _NamingStepState extends State<NamingStep> {
  final _responses = List<String>.filled(3, '');
  final _listening = List<bool>.filled(3, false);
  final _hintUsed = List<bool>.filled(3, false);
  final _showHint = List<bool>.filled(3, false);
  late SpeechToText _speech;
  Timer? _timeoutTimer;
  int _answeredCount = 0;
  bool _done = false;

  final _names = ['λιοντάρι', 'ρινόκερος', 'καμήλα'];

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    _timeoutTimer = Timer(const Duration(minutes: 2), _finish);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  Future<void> _startListening(int i) async {
    if (_listening[i]) return;
    final available = await _speech.initialize();
    if (!available) return;

    setState(() => _listening[i] = true);
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _responses[i] = r.recognizedWords.trim().toLowerCase();
        });
        if (r.finalResult) {
          _speech.stop();
          _validateField(i);
        }
      },
    );
  }

  void _validateField(int idx) {
    if (_responses[idx].isEmpty) return;
    final userSaid = _responses[idx];
    final correct = userSaid == _names[idx] || userSaid == _names[idx].replaceAll('ά', 'α');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_names[idx][0].toUpperCase()}${_names[idx].substring(1)}: '
          '${correct ? 'Σωστό' : 'Λάθος'}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    _answeredCount++;
    if (_answeredCount >= 3) {
      Future.delayed(const Duration(milliseconds: 500), _finish);
    }
    setState(() => _listening[idx] = false);
  }

  void _showHintFor(int idx) {
    setState(() {
      _showHint[idx] = true;
      _hintUsed[idx] = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHint[idx] = false);
    });
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _timeoutTimer?.cancel();
    double score = 0;
    for (int i = 0; i < 3; i++) {
      final userSaid = _responses[i];
      final correct = userSaid == _names[i] || userSaid == _names[i].replaceAll('ά', 'α');
      if (correct && _hintUsed[i]) {
        score += 0.5;
      } else if (correct) {
        score += 1;
      }
    }
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Κατονομασία')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Κατονομάστε κάθε ζώο πατώντας το μικρόφωνο στη δεξιά πλευρά του πλαισίου.\n'
                  'Αν πατήσετε "Υπόδειξη" για κάποιο, παίρνετε μισό βαθμό για αυτό.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(3, (i) {
                      final asset = i == 0
                          ? 'assets/animals/lion.png'
                          : i == 1
                              ? 'assets/animals/rhino.png'
                              : 'assets/animals/camel.png';
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Image.asset(asset, fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 50,
                              child: TextField(
                                readOnly: true,
                                controller: TextEditingController(
                                    text: _responses[i].isEmpty ? '—' : _responses[i]),
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      Icons.mic,
                                      color: _listening[i] ? Colors.green : Colors.black,
                                    ),
                                    onPressed: !_listening[i] && !_done
                                        ? () => _startListening(i)
                                        : null,
                                    tooltip: 'Λέγεται στο μικρόφωνο',
                                  ),
                                ),
                                style: const TextStyle(fontSize: 17),
                                enableInteractiveSelection: false,
                                showCursor: false,
                              ),
                            ),
                            const SizedBox(height: 5),
                            if (_showHint[i])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  _names[i].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.yellow[900],
                                    backgroundColor: Colors.yellow[200],
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: 110,
                              child: OutlinedButton(
                                onPressed: !_showHint[i]
                                    ? () => _showHintFor(i)
                                    : null,
                                child: const Text('Υπόδειξη'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 50), // space for button
              ],
            ),
          ),
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
