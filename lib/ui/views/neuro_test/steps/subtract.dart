import 'dart:async';
import 'package:flutter/material.dart';

/// Step 9 - Serial subtraction. User subtracts 7 from 100 five times.
class SubtractStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const SubtractStep({super.key, required this.onNext, required this.onScored});

  @override
  State<SubtractStep> createState() => _SubtractStepState();
}

class _SubtractStepState extends State<SubtractStep> {
  final _controllers = List.generate(5, (_) => TextEditingController());
  Timer? _timeout;

  static const _answers = [93, 86, 79, 72, 65];

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(minutes: 2), _submit);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  void _submit() {
    _timeout?.cancel();
    int score = 0;
    for (int i = 0; i < 5; i++) {
      final val = int.tryParse(_controllers[i].text.trim());
      if (val == _answers[i]) score++;
    }
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Αφαίρεση 7 από το 100')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Αφαιρέστε διαδοχικά 7 ξεκινώντας από το 100 (πέντε φορές).',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < 5; i++) ...[
              Text('Βήμα ${i + 1}:'),
              TextField(
                controller: _controllers[i],
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Επόμενο'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
