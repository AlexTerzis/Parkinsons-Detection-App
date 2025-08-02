import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class DigitsBackwardStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(double score) onScored;
  const DigitsBackwardStep({
    Key? key,
    required this.onNext,
    required this.onScored,
  }) : super(key: key);

  @override
  State<DigitsBackwardStep> createState() => _DigitsBackwardStepState();
}

class _DigitsBackwardStepState extends State<DigitsBackwardStep> {
  final _controller = TextEditingController();
  late SpeechToText _speech;
  Timer? _timeout;
  Timer? _hintTimer;
  bool _hintUsed = false;
  bool _showHint = false;
  bool _listening = false;
  int _phase = 0; // 0: instruction/memorize, 1: recall

  static const _sequence = '7 4 2';
  static const _sequenceAnswer = '247';

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _hintTimer?.cancel();
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  void _startPhase2() {
    setState(() => _phase = 1);
    _timeout = Timer(const Duration(minutes: 1), _submit);
  }

  Future<void> _startListening() async {
    if (_listening) return;
    final available = await _speech.initialize();
    if (!available) return;
    setState(() => _listening = true);

    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          // Extract digits from recognized text
          final raw = r.recognizedWords.replaceAll(RegExp(r'[^\d]'), '');
          _controller.text = raw.split('').join(' ');
        });
        if (r.finalResult) {
          _speech.stop();
          setState(() => _listening = false);
        }
      },
    );
  }

  void _showHintFunc() {
    setState(() {
      _showHint = true;
      _hintUsed = true;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _submit() {
    _timeout?.cancel();
    final answer = _controller.text.replaceAll(' ', '');
    double score = 0;
    if (answer == _sequenceAnswer) {
      score = _hintUsed ? 0.5 : 1;
    } else {
      score = 0;
    }
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 0) {
      // Phase 1: Memorize instructions
      return Scaffold(
        appBar: AppBar(title: const Text('Οπισθοχωρητική μνήμη')),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Προσπαθήστε να απομνημονεύσετε τα παρακάτω νούμερα.\n'
                    'Σε λίγο θα σας ζητηθεί να τα επαναλάβετε με την αντίστροφη σειρά.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      _sequence,
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

    // Phase 2: Recall
    return Scaffold(
      appBar: AppBar(title: const Text('Οπισθοχωρητική μνήμη')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Επαναλάβετε με την αντίστροφη σειρά τους αριθμούς που είδατε:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 350,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Γράψτε ή πείτε τους αριθμούς',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _listening ? Icons.mic : Icons.mic_none,
                            color: _listening ? Colors.green : null,
                          ),
                          onPressed: _listening ? null : _startListening,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      ),
                      style: const TextStyle(fontSize: 18),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Hint button
                Center(
                  child: OutlinedButton(
                    onPressed: _showHint ? null : _showHintFunc,
                    child: const Text('Υπόδειξη'),
                  ),
                ),
                if (_showHint)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.yellow[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _sequence,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Next at bottom right
          Positioned(
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Επόμενο'),
            ),
          ),
        ],
      ),
    );
  }
}
