import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Step 8 - Vigilance. Random letters flash every second. Tap when "Α" appears.
class NeuroStep8 extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const NeuroStep8({super.key, required this.onNext, required this.onScored});

  @override
  State<NeuroStep8> createState() => _NeuroStep8State();
}

class _NeuroStep8State extends State<NeuroStep8> {
  static const _letters = ['Α','Β','Γ','Δ','Ε'];
  String _current = '';
  late Timer _timer;
  int _correct = 0;
  int _wrong = 0;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    // Show 15 letters total.
    _nextLetter();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _nextLetter());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _nextLetter() {
    setState(() {
      _current = _letters[Random().nextInt(_letters.length)];
      _shown++;
    });
    if (_shown >= 15) {
      _timer.cancel();
    }
  }

  void _pressed() {
    if (_current == 'Α') {
      _correct++;
    } else {
      _wrong++;
    }
    if (_shown >= 15) _finish();
  }

  void _finish() {
    final score = _correct > _wrong ? 1 : 0;
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Εγρήγορση')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _current,
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pressed,
              child: const Text('Άκουσα Α'),
            ),
            const SizedBox(height: 20),
            if (_shown >= 15)
              ElevatedButton(
                onPressed: _finish,
                child: const Text('Επόμενο'),
              ),
          ],
        ),
      ),
    );
  }
}
