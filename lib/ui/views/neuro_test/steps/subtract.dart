import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// MoCA Serial 7s - dynamic, allows speaking or typing.
/// Each subtraction uses user's previous input.
/// 5 or 4 correct = 3 pts, 3 or 2 = 2 pts, 1 = 1 pt, 0 = 0.
class SubtractStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const SubtractStep({super.key, required this.onNext, required this.onScored});

  @override
  State<SubtractStep> createState() => _SubtractStepState();
}

class _SubtractStepState extends State<SubtractStep> {
  final _controllers = List.generate(5, (_) => TextEditingController());
  final _focusNodes = List.generate(5, (_) => FocusNode());
  final List<bool> _listening = List.filled(5, false);
  late SpeechToText _speech;
  Timer? _timeout;
  bool _submitted = false;

  static const _answers = [93, 86, 79, 72, 65];

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    _timeout = Timer(const Duration(minutes: 2), _submit);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _listenField(int idx) async {
    if (_listening[idx]) return;
    if (_listening.contains(true)) return; // Only one at a time
    final available = await _speech.initialize();
    if (!available) return;
    setState(() => _listening[idx] = true);
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        final recognized = r.recognizedWords.replaceAll(RegExp(r'[^\d]'), '');
        setState(() => _controllers[idx].text = recognized);
        if (r.finalResult) {
          _speech.stop();
          setState(() => _listening[idx] = false);
          _focusNodes[idx].unfocus();
        }
      },
    );
  }

  void _submit() {
    if (_submitted) return;
    _timeout?.cancel();

    int correct = 0;
    for (int i = 0; i < 5; i++) {
      final val = int.tryParse(_controllers[i].text.trim());
      if (val == _answers[i]) correct++;
    }
    int score = 0;
    if (correct >= 4) score = 3;
    else if (correct >= 2) score = 2;
    else if (correct == 1) score = 1;
    else score = 0;

    setState(() => _submitted = true);
    widget.onScored(score);
    widget.onNext();
  }

  int? _leftNumber(int i) {
    if (i == 0) return 100;
    final prev = int.tryParse(_controllers[i - 1].text.trim());
    return prev;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Αφαίρεση 7 από το 100')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Αφαιρέστε διαδοχικά 7 ξεκινώντας από το 100 (πέντε φορές):',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 18),
                Center(
                  child: SizedBox(
                    width: 320,
                    child: Column(
                      children: List.generate(5, (i) {
                        final left = _leftNumber(i);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              // Left side: previous answer or 100
                              SizedBox(
                                width: 55,
                                child: Text(
                                  left != null ? '$left' : '—',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Text('- 7 ='),
                              const SizedBox(width: 8),
                              // Input
                              Expanded(
                                child: TextField(
                                  controller: _controllers[i],
                                  focusNode: _focusNodes[i],
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_submitted,
                                  onChanged: (_) {
                                    setState(() {}); // To refresh left side for next row
                                  },
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _listening[i] ? Icons.mic : Icons.mic_none,
                                        color: _listening[i] ? Colors.green : null,
                                      ),
                                      onPressed: _submitted || _listening.contains(true)
                                          ? null
                                          : () => _listenField(i),
                                    ),
                                  ),
                                  onSubmitted: (_) => i == 4 ? _submit() : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
          // Next button bottom right
          Positioned(
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: _submitted ? null : _submit,
              child: const Text('Επόμενο'),
            ),
          ),
        ],
      ),
    );
  }
}
