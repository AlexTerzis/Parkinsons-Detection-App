import 'dart:async';
import 'package:flutter/material.dart';

class NeuroStep5 extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(int score) onScored;

  const NeuroStep5({
    Key? key,
    required this.onNext,
    required this.onScored,
  }) : super(key: key);

  @override
  _NeuroStep5State createState() => _NeuroStep5State();
}

class _NeuroStep5State extends State<NeuroStep5> {
  final _controllers = List.generate(3, (_) => TextEditingController());
  final _focusNodes  = List.generate(3, (_) => FocusNode());
  Timer? _timeoutTimer;
  int _answeredCount = 0;
  bool _done = false;

  final _names = ['λιοντάρι', 'ρινόκερος', 'καμήλα'];

  @override
  void initState() {
    super.initState();
    // listen for focus loss on each field
    for (int i = 0; i < 3; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && !_done) {
          _validateField(i);
        }
      });
    }
    // 2‑minute timeout auto‑submit
    _timeoutTimer = Timer(const Duration(minutes: 2), _finish);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    for (var fn in _focusNodes) fn.dispose();
    for (var c  in _controllers) c.dispose();
    super.dispose();
  }

  void _validateField(int idx) {
    final text = _controllers[idx].text.trim().toLowerCase();
    final correct = text == _names[idx]
      || text == _names[idx].replaceAll('ά','α');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_names[idx][0].toUpperCase()}${_names[idx].substring(1)}: '
          '${correct ? 'Σωστό' : 'Λάθος'}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    _answeredCount++;
    if (_answeredCount >= 3) {
      // give a moment for the last SnackBar to show
      Future.delayed(const Duration(milliseconds: 500), _finish);
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _timeoutTimer?.cancel();
    // tally score
    int score = 0;
    for (int i = 0; i < 3; i++) {
      final text = _controllers[i].text.trim().toLowerCase();
      if (text == _names[i] || text == _names[i].replaceAll('ά','α')) {
        score++;
      }
    }
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Κατονομασία')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Κατονομάστε κάθε ζώο. Όταν φύγετε από το πεδίο, '
              'θα δείτε αν η απάντηση ήταν σωστή ή λάθος.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: List.generate(3, (i) {
                  final asset = i == 0
                      ? 'assets/animals/lion.png'
                      : i == 1
                          ? 'assets/animals/rhino.png'
                          : 'assets/animals/camel.png';
                  return Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(asset, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _controllers[i],
                            focusNode:  _focusNodes[i],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '…',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
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
