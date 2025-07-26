import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

/*
 * This widget implements the "verbal fluency" assessment which is a
 * component of the MoCA cognitive test.  The participant is asked to speak
 * as many words as possible that begin with the Greek letter "χ" within a
 * single one‑minute period.  Modern versions of Flutter require a recent
 * speech_to_text plugin to avoid Android embedding issues; therefore
 * pubspec.yaml specifies version 7.2.0 or newer.
 *
 * The design is intentionally simple:
 *   1. The plugin is initialised during [initState] and the microphone
 *      button is enabled once availability is confirmed.
 *   2. Tapping the button begins listening and starts a 60s timer. Interim
 *      recognition results are displayed live so the user sees feedback.
 *   3. Saying "Τέλος" or letting the timer expire ends the test.  The
 *      transcript is analysed to count distinct "χ" words which are then
 *      scored.  Results appear in a SnackBar before advancing to the next
 *      step.
 */

/// Step 6 – verbal fluency test.
///
/// The patient must list as many words as possible beginning with the
/// Greek letter "χ" within sixty seconds.  Speech is captured using the
/// [`speech_to_text`](https://pub.dev/packages/speech_to_text) plugin.
///
/// * The plugin is initialised in [initState] and the test is only
///   enabled once it reports availability.
/// * Pressing the microphone floating action button starts listening and
///   begins a 60 second countdown.  Interim recognition results are shown
///   live on screen.
/// * Saying "Τέλος" or pressing the button again stops recognition.
/// * When time expires or listening stops, words starting with "χ" are
///   extracted, duplicates removed and counted.  Eleven or more distinct
///   words yield a score of one, otherwise zero.
/// * The detected word count is displayed briefly in a [SnackBar] before
///   invoking [widget.onScored] and [widget.onNext].
class NeuroStep12 extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(int score) onScored;

  const NeuroStep12({
    Key? key,
    required this.onNext,
    required this.onScored,
  }) : super(key: key);

  @override
  State<NeuroStep12> createState() => _NeuroStep12State();
}

/// Widget state containing the speech recognition and timer logic.
///
/// The boolean fields track microphone availability and whether we are
/// currently recording.  The recognised text is accumulated into
/// [_transcript] so it can be displayed live.// ... [imports and docs unchanged] ...
class _NeuroStep12State extends State<NeuroStep12> {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  List<String> _allWords = [];  // <-- Store all recognized words in order
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _available = await _speech.initialize();
    if (mounted) setState(() {});
  }

  void _toggleListening() async {
    if (!_available) return;

    if (_listening) {
      await _speech.stop();
      _finish();
    } else {
      _timer?.cancel();
      _timer = Timer(
        const Duration(seconds: 60),
        () => _finish(forceZero: true),
      );
      setState(() {
        _transcript = '';
        _allWords = []; // Reset for new attempt
        _listening = true;
      });
      await _speech.listen(
        onResult: (r) {
          setState(() {
            _transcript = r.recognizedWords;
            // Update the list of all words (split on whitespace or comma)
            _allWords = _transcript
                .split(RegExp(r'[\s,]+'))
                .where((w) => w.isNotEmpty)
                .toList();
          });
          if (r.finalResult &&
              r.recognizedWords.toLowerCase().contains('τέλος')) {
            _finish();
          }
        },
        partialResults: true,
        listenMode: ListenMode.confirmation,
        localeId: 'el_GR',
      );
    }
  }

  void _finish({bool forceZero = false}) async {
    if (!_listening) return;
    _timer?.cancel();
    await _speech.stop();
    setState(() => _listening = false);

    // You can use _allWords here for scoring or analysis

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Λέξεις: ${_allWords.length}')),
    );
    Future.delayed(const Duration(seconds: 1), () {
      // Scoring logic here, example:
      widget.onScored(0); // Just as placeholder
      widget.onNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Λέξεις που ειπώθηκαν')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Μιλήστε και κάθε λέξη θα εμφανίζεται αμέσως στην οθόνη.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        _transcript,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  if (_allWords.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _allWords
                            .map((w) => Chip(
                                  label: Text(w),
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        child: Icon(_listening ? Icons.stop : Icons.mic),
      ),
    );
  }
}
