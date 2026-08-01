import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA verbal fluency: name as many words starting with Χ as possible in one
/// minute. The target letter and the "τέλος" stop word belong to the Greek
/// instrument and are matched against `el_GR` speech, so both stay Greek.
class FluencyStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(int score) onScored;

  const FluencyStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<FluencyStep> createState() => _FluencyStepState();
}

class _FluencyStepState extends State<FluencyStep> {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  final List<String> _allWords = [];
  Timer? _timer;
  int _secondsLeft = 60;
  bool _micUnexpectedlyClosed = false;
  bool _finished = false;

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

  void _onSpeechStatus(String status) {
    if (_listening &&
        (status == "notListening" || status == "done" || status == "done_no_result")) {
      if (_secondsLeft > 0) {
        setState(() {
          _micUnexpectedlyClosed = true;
          _listening = false;
        });
        _speech.stop();
        
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    setState(() {
      _micUnexpectedlyClosed = true;
      _listening = false;
    });
    AppFeedback.error(context, AppLocalizations.of(context)!.stepMicProblem);
  }

  void _toggleListening() async {
    if (!_available || _secondsLeft == 0) return;

    if (_listening) {
      await _speech.stop();
      _finish();
    } else {
      setState(() {
        _micUnexpectedlyClosed = false;
        _listening = true;
      });

      if (_timer == null && _secondsLeft > 0) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secondsLeft > 0) {
            setState(() {
              _secondsLeft--;
            });
          }
          if (_secondsLeft <= 0) {
            _finish();
          }
        });
      }

      await _speech.listen(
        onResult: (r) {
          setState(() {
            _transcript = r.recognizedWords;
            for (var w in _transcript
                .split(RegExp(r'[,\s\.]+'))
                .where((w) => w.isNotEmpty)) {
              if (!_allWords.contains(w)) {
                _allWords.add(w);
              }
            }
          });
          if (r.finalResult &&
              r.recognizedWords.toLowerCase().contains('τέλος')) {
            _finish();
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.confirmation,
        ),
        localeId: 'el_GR',
      );
    }
  }

  void _finish({bool forceZero = false}) async {
    if (!_listening && !_micUnexpectedlyClosed && _secondsLeft > 0) return;
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    _speech.stop();
    setState(() => _listening = false);

    final validWords = _allWords
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.startsWith('χ') && w.length > 1)
        .toSet();

    final count = forceZero ? 0 : validWords.length;
    final score = count >= 11 ? 1 : 0;

    // Use the score!
    widget.onScored(score);
    // User presses Next to continue
  }


  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);
    final started = _listening || _secondsLeft < 60;

    return TestStepScaffold(
      title: l10n.stepTitleFluency,
      instruction: l10n.stepInstructionFluency,
      // The word chips scroll in their own list below.
      scrollable: false,
      onNext: widget.onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (started)
            Column(
              children: [
                Text(
                  l10n.stepTimeRemaining,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$_secondsLeft',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    // Runs warning-coloured over the last ten seconds.
                    color: _secondsLeft <= 10 ? semantic.warning : null,
                  ),
                ),
              ],
            ),
          if (_micUnexpectedlyClosed && !_listening && _secondsLeft > 0) ...[
            const AppGap.sm(),
            Text(
              l10n.stepMicClosed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: semantic.warning),
            ),
          ],
          const AppGap.xs(),
          Text(
            _listening ? l10n.stepSpeakNow : l10n.stepTapMicToStart,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const AppGap.md(),
          // The mic sits with the content rather than floating: it is the
          // control the patient is told to press, so it must be findable.
          Align(
            child: FilledButton.tonalIcon(
              onPressed: _secondsLeft == 0 ? null : _toggleListening,
              icon: Icon(_listening ? Icons.stop : Icons.mic),
              label: Text(_listening ? l10n.stepFinish : l10n.stepStartMic),
            ),
          ),
          const AppGap.md(),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: _allWords.map((w) {
                    // Words that count toward the score are marked with an
                    // icon as well as a tint, so the cue is not colour alone.
                    final isValid =
                        w.length > 1 && w.toLowerCase().startsWith('χ');
                    return Chip(
                      label: Text(w),
                      avatar: isValid
                          ? Icon(Icons.check, color: semantic.success)
                          : null,
                      backgroundColor:
                          isValid ? semantic.successContainer : null,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
