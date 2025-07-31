import 'dart:async';
import 'package:flutter/material.dart';

/// Step 6 - Working memory. User must repeat the shown sequence "2 1 8 5 4".
class DigitsForwardStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const DigitsForwardStep({super.key, required this.onNext, required this.onScored});

  @override
  State<DigitsForwardStep> createState() => _DigitsForwardStepState();
}

class _DigitsForwardStepState extends State<DigitsForwardStep> {
  final _controller = TextEditingController();
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    // Auto move on after a minute so the test doesn't block.
    _timeout = Timer(const Duration(minutes: 1), _submit);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    _timeout?.cancel();
    final answer = _controller.text.replaceAll(' ', '');
    final score = answer == '21854' ? 1 : 0;
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Εργαζόμενη μνήμη')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Επαναλάβετε με την ίδια σειρά τους αριθμούς 2 – 1 – 8 – 5 – 4',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '2 1 8 5 4',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Επόμενο'),
            ),
          ],
        ),
      ),
    );
  }
}
