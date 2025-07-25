import 'dart:async';
import 'package:flutter/material.dart';

/// Step 7 - Backward digit span. User repeats 7‑4‑2 in reverse order.
class NeuroStep7 extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const NeuroStep7({super.key, required this.onNext, required this.onScored});

  @override
  State<NeuroStep7> createState() => _NeuroStep7State();
}

class _NeuroStep7State extends State<NeuroStep7> {
  final _controller = TextEditingController();
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
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
    final ans = _controller.text.replaceAll(' ', '');
    final score = ans == '247' ? 1 : 0;
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Οπισθοχωρητική μνήμη')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Επαναλάβετε με την αντίστροφη σειρά τους αριθμούς 7 – 4 – 2',
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
                hintText: '2 4 7',
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
