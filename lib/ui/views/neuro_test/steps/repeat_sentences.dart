import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA sentence repetition: read a sentence, then repeat it from memory.
///
/// The two sentences are the instrument's own and stay Greek — they are scored
/// word-by-word against `el_GR` recognition.
class RepeatSentencesStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(double score) onScored;
  const RepeatSentencesStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<RepeatSentencesStep> createState() => _RepeatSentencesStepState();
}

class _RepeatSentencesStepState extends State<RepeatSentencesStep> {
  final SpeechToText _speech = SpeechToText();
  final List<String> _phrases = const [
    'Το μόνο που ξέρω είναι ότι ο Γιάννης είναι αυτός που θα βοηθήσει σήμερα',
    'Η γάτα κρυβόταν πάντα κάτω από τον καναπέ όταν βρίσκονταν σκυλιά μέσα στο δωμάτιο',
  ];

  int _step = 0; // 0: instructions, 1: memorize, 2: recording
  int _phraseIndex = 0;
  bool _listening = false;
  String _recognized = '';
  String _recognizedHistory = '';
  bool _hintUsed = false;
  bool _showHintPhrase = false;
  bool _micUnexpectedlyClosed = false;
  int _memorizeSecondsLeft = 20;
  int _recordingSecondsLeft = 60;
  Timer? _memorizeTimer;
  Timer? _recordingTimer;
  bool _available = false;
  final List<double> _phraseScores = [];
  bool _timerStarted = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (mounted) setState(() {});
  }

  void _goToMemorize() {
    setState(() {
      _step = 1;
      _hintUsed = false;
      _showHintPhrase = false;
      _micUnexpectedlyClosed = false;
      _memorizeSecondsLeft = 20;
      _recordingSecondsLeft = 60;
      _timerStarted = false;
      _recognized = '';
      _recognizedHistory = '';
    });
    _memorizeTimer?.cancel();
    _memorizeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_memorizeSecondsLeft > 1) {
        setState(() => _memorizeSecondsLeft--);
      } else {
        timer.cancel();
        _goToRecording();
      }
    });
  }

  void _skipMemorizeAndRecord() {
    _memorizeTimer?.cancel();
    _goToRecording();
  }

  void _goToRecording() {
    setState(() {
      _step = 2;
      _micUnexpectedlyClosed = false;
      _showHintPhrase = false;
      _recordingSecondsLeft = 60;
      _timerStarted = false;
      // Do NOT clear _recognized or _recognizedHistory here!
    });
    _recordingTimer?.cancel();
    // Timer will be started by the mic, NOT here.
  }

  void _onSpeechStatus(String status) {
    if (_listening &&
        (status == "notListening" || status == "done" || status == "done_no_result")) {
      if (!mounted) return;
      setState(() {
        _micUnexpectedlyClosed = true;
        _listening = false;
      });
      _speech.stop();
    }
  }

  void _onSpeechError(dynamic error) {
    if (!mounted) return;
    setState(() {
      _micUnexpectedlyClosed = true;
      _listening = false;
    });
  }

  Future<void> _startListening() async {
    if (!_available) return;
    setState(() {
      _micUnexpectedlyClosed = false; // Hide message as soon as mic is started
      _listening = true;
      // DO NOT CLEAR _recognized or _recognizedHistory HERE!
    });
    if (!_timerStarted) {
      setState(() {
        _timerStarted = true;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_recordingSecondsLeft > 1) {
          setState(() => _recordingSecondsLeft--);
        } else {
          timer.cancel();
          _stopListening();
          setState(() => _listening = false);
        }
      });
    }
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        if (!mounted) return;
        setState(() {
          if (r.recognizedWords.isNotEmpty) {
            _recognized = r.recognizedWords;
            // Only append if new recognition doesn't already exist at the end
            if (!_recognizedHistory.endsWith(_recognized)) {
              _recognizedHistory = '$_recognizedHistory $_recognized'.trim();
            }
          }
          if (r.finalResult) {
            // Always save the final recognizedWords to history
            if (!_recognizedHistory.endsWith(_recognized)) {
              _recognizedHistory = '$_recognizedHistory $_recognized'.trim();
            }
            _listening = false;
          }
        });
      },
      listenFor: Duration(seconds: _recordingSecondsLeft),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    await _speech.stop();
    if (!mounted) return;
    setState(() => _listening = false);
  }

  void _showHint() {
    setState(() {
      _hintUsed = true;
      _showHintPhrase = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showHintPhrase = false);
    });
  }

  void _clear() {
    setState(() {
      _recognized = '';
      _recognizedHistory = '';
    });
  }

  void _next() async {
    await _stopListening();
    _memorizeTimer?.cancel();
    _recordingTimer?.cancel();

    // Scoring
    final phrase = _phrases[_phraseIndex]
        .toLowerCase()
        .replaceAll(RegExp('[.,«»]'), '')
        .split(RegExp(r'\s+'));
    final actual = _recognizedHistory
        .toLowerCase()
        .replaceAll(RegExp('[.,«»]'), '')
        .split(RegExp(r'\s+'));
    int errors = 0;
    int minLen = min(phrase.length, actual.length);
    for (var i = 0; i < minLen; i++) {
      if (phrase[i] != actual[i]) errors++;
    }
    errors += (phrase.length - actual.length).abs();
    int correctCount = 0;
    for (var w in actual) {
      if (phrase.contains(w)) correctCount++;
    }
    double score = 0;
    if (_recognizedHistory.trim().isEmpty) {
      score = 0;
    } else if (errors <= 1) {
      score = 1;
    } else if (correctCount >= (phrase.length / 2).ceil()) {
      score = 0.5;
    } else {
      score = 0;
    }
    if (_hintUsed) {
      score /= 2;
    }

    _phraseScores.add(score);

    if (_phraseIndex < _phrases.length - 1) {
      setState(() {
        _phraseIndex++;
      });
      _goToMemorize();
    } else {
      double totalScore =
          _phraseScores.isEmpty ? 0 : _phraseScores.reduce((a, b) => a + b);
      widget.onScored(totalScore);
      widget.onNext();
    }
  }

  @override
  void dispose() {
    _memorizeTimer?.cancel();
    _recordingTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);
    final isLastPhrase = _phraseIndex >= _phrases.length - 1;

    if (_step == 0) {
      return TestStepScaffold(
        title: l10n.stepTitleRepeatSentences,
        instruction: l10n.stepInstructionRepeatSentencesIntro,
        nextLabel: l10n.stepStartTest,
        onNext: _goToMemorize,
        child: const SizedBox.shrink(),
      );
    }

    if (_step == 1) {
      return TestStepScaffold(
        title: l10n.stepTitleRepeatSentences,
        onNext: _skipMemorizeAndRecord,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The sentence to memorise, given the whole screen.
            Text(
              _phrases[_phraseIndex],
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const AppGap.lg(),
            Text(
              l10n.stepMemoriseTimeLeft(_memorizeSecondsLeft),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final micEnabled = !_listening && _available && _recordingSecondsLeft > 0;

    return TestStepScaffold(
      title: l10n.stepTitleRepeatSentences,
      instruction: l10n.stepInstructionRepeatBack,
      nextLabel: isLastPhrase ? l10n.stepFinish : null,
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.stepTimeRemainingValue(
              l10n.stepSecondsValue(_recordingSecondsLeft),
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _recordingSecondsLeft <= 10 ? semantic.warning : null,
            ),
          ),
          const AppGap.md(),
          Text(
            _recognizedHistory.isEmpty
                ? l10n.stepInstructionRepeatSentence
                : _recognizedHistory,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: _recognizedHistory.isEmpty
                  ? theme.colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
          if (_showHintPhrase) HintPanel(lines: [_phrases[_phraseIndex]]),
          const Spacer(),
          if (_micUnexpectedlyClosed && !_listening) ...[
            Text(
              l10n.stepMicStopped,
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: semantic.warning),
            ),
            const AppGap.sm(),
          ],
          Align(
            child: FilledButton.tonalIcon(
              onPressed: micEnabled
                  ? () async {
                      // Clear the warning the moment the patient retries.
                      setState(() => _micUnexpectedlyClosed = false);
                      await _startListening();
                    }
                  : null,
              icon: const Icon(Icons.mic),
              label: Text(l10n.stepStartMic),
            ),
          ),
          const AppGap.md(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text(l10n.stepHint),
                ),
              ),
              const AppGap.wide(AppSpacing.xs),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _recognizedHistory.isEmpty ? null : _clear,
                  icon: const Icon(Icons.undo),
                  label: Text(l10n.stepDelete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
