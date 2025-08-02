import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

// Helper for more forgiving Greek matching
String normalizeGreek(String text) {
  return text
      .replaceAll(RegExp(r'[άα]'), 'α')
      .replaceAll(RegExp(r'[έε]'), 'ε')
      .replaceAll(RegExp(r'[ήη]'), 'η')
      .replaceAll(RegExp(r'[ίιϊΐ]'), 'ι')
      .replaceAll(RegExp(r'[όο]'), 'ο')
      .replaceAll(RegExp(r'[ύυϋΰ]'), 'υ')
      .replaceAll(RegExp(r'[ώω]'), 'ω')
      .replaceAll(RegExp(r'[ς]'), 'σ')
      .toLowerCase();
}

class SimilaritiesStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(double score) onScored;
  const SimilaritiesStep({super.key, required this.onNext, required this.onScored});

  @override
  State<SimilaritiesStep> createState() => _SimilaritiesStepState();
}

class _SimilaritiesStepState extends State<SimilaritiesStep> {
  final _controllers = [TextEditingController(), TextEditingController()];
  late SpeechToText _speech;
  final _listening = [false, false];
  final _showHint = [false, false];
  final _hintUsed = [false, false];
  Timer? _timeout;

  // Acceptable answers
  static const _hints1 = [
    'Μέσα μεταφοράς',
    'Οχήματα',
    'Μετακινούν ανθρώπους',
    'Μέσο κυκλοφορίας'
  ];
  static const _hints2 = [
    'Μετρούν',
    'Μέσα μέτρησης',
    'Μετρούν χρόνο και μήκος',
    'Όργανα μέτρησης'
  ];

  bool _isCorrect1 = false;
  bool _isCorrect2 = false;

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    _timeout = Timer(const Duration(minutes: 2), _submit);

    // Live check as user types
    _controllers[0].addListener(_checkCorrect);
    _controllers[1].addListener(_checkCorrect);
  }

  void _checkCorrect() {
    setState(() {
      final a1 = normalizeGreek(_controllers[0].text);
      final a2 = normalizeGreek(_controllers[1].text);

      _isCorrect1 = a1.contains('μεταφορ') ||
          a1.contains('οχη') ||
          a1.contains('μετακιν') ||
          a1.contains('κυκλοφορ');

      _isCorrect2 = a2.contains('μετρ') ||
          a2.contains('χρον') ||
          a2.contains('μηκοσ') ||
          a2.contains('ακριβεια') ||
          a2.contains('μετρηση');
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    for (final c in _controllers) c.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _startListening(int idx) async {
    if (_listening[idx]) return;
    final available = await _speech.initialize();
    if (!available) return;
    setState(() => _listening[idx] = true);

    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _controllers[idx].text = r.recognizedWords.trim();
        });
        if (r.finalResult) {
          _speech.stop();
          setState(() => _listening[idx] = false);
        }
      },
    );
  }

  void _showHintFunc(int idx) {
    setState(() {
      _showHint[idx] = true;
      _hintUsed[idx] = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint[idx] = false);
    });
  }

  void _submit() {
    _timeout?.cancel();
    double score = 0;
    if (_isCorrect1) {
      score += _hintUsed[0] ? 0.5 : 1.0;
    }
    if (_isCorrect2) {
      score += _hintUsed[1] ? 0.5 : 1.0;
    }
    widget.onScored(score);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Αφαιρετική σκέψη')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // INSTRUCTIONS (theme color)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface, // App theme
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tι κοινό έχουν τα παρακάτω ζεύγη;\n\n'
                      'Μπορείτε να πληκτρολογήσετε ή να χρησιμοποιήσετε το μικρόφωνο.\n'
                      'Πατήστε "Υπόδειξη" για παραδείγματα απαντήσεων.\n'
                      'π.χ. μπανάνα - πορτοκάλι = φρούτα\n',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  // First pair
                  const Text(
                    '1) Τρένο – Ποδήλατο',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllers[0],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Απάντηση',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_listening[0] ? Icons.mic : Icons.mic_none),
                        color: _listening[0] ? Colors.green : null,
                        onPressed: _listening[0] ? null : () => _startListening(0),
                      ),
                      OutlinedButton(
                        onPressed: () => _showHintFunc(0),
                        child: const Text('Υπόδειξη'),
                      ),
                      if (_isCorrect1)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.check_circle, color: Colors.green),
                        ),
                    ],
                  ),
                  if (_showHint[0])
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _hints1.map((h) => Text('• $h', style: const TextStyle(fontSize: 15))).toList(),
                      ),
                    ),
                  const SizedBox(height: 22),
                  // Second pair
                  const Text(
                    '2) Ρολόι – Χάρακας',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllers[1],
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Απάντηση',
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_listening[1] ? Icons.mic : Icons.mic_none),
                        color: _listening[1] ? Colors.green : null,
                        onPressed: _listening[1] ? null : () => _startListening(1),
                      ),
                      OutlinedButton(
                        onPressed: () => _showHintFunc(1),
                        child: const Text('Υπόδειξη'),
                      ),
                      if (_isCorrect2)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.check_circle, color: Colors.green),
                        ),
                    ],
                  ),
                  if (_showHint[1])
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _hints2.map((h) => Text('• $h', style: const TextStyle(fontSize: 15))).toList(),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Next button at bottom right, matches your other tests
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Επόμενο'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
