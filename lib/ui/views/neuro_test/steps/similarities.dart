import 'dart:async';
import 'package:flutter/material.dart';

/// Step 10 - Abstract thinking with two pair questions.
class SimilaritiesStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const SimilaritiesStep({super.key, required this.onNext, required this.onScored});

  @override
  State<SimilaritiesStep> createState() => _SimilaritiesStepState();
}

class _SimilaritiesStepState extends State<SimilaritiesStep> {
  final _c1 = TextEditingController();
  final _c2 = TextEditingController();
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(minutes: 2), _submit);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  void _submit() {
    _timeout?.cancel();
    int score = 0;
    final a1 = _c1.text.toLowerCase();
    final a2 = _c2.text.toLowerCase();
    if (a1.contains('μεταφορ') || a1.contains('οχη')) score++;
    if (a2.contains('μετρ') || a2.contains('χρον') || a2.contains('μηκος')) score++;
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Αφαιρετική σκέψη')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Τι κοινό έχουν τα ζεύγη: \n1) τρένο – ποδήλατο\n2) ρολόι – χάρακας\n',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c1,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Απάντηση για ζεύγος 1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c2,
              decoration: const InputDecoration(
                labelText: 'Απάντηση για ζεύγος 2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: const Text('Επόμενο')),
          ],
        ),
      ),
    );
  }
}
