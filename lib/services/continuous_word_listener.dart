import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Collects words spoken over a long window, such as a one-minute verbal
/// fluency task.
///
/// The device recogniser is built for short utterances. One long session
/// grows slower as its hypothesis grows, and it closes by itself after a
/// pause. This keeps sessions short instead: whenever one ends while the
/// listener is still active, a new one is started, so the patient can keep
/// talking without touching the mic.
///
/// Only words from a *final* result are committed. Partial results are
/// guesses the recogniser revises as it hears more ("κα", "καρ", "καρέκλα"),
/// and committing them used to fill the list with fragments that could count
/// toward the score. They are exposed separately in [pendingWords] for
/// display.
class ContinuousWordListener {
  ContinuousWordListener({
    required this.localeId,
    required this.onChanged,
    this.onStopWord,
    this.stopWord,
    this.onFailure,
  });

  final String localeId;

  /// Called whenever [words], [pendingWords] or [isListening] change.
  final void Function() onChanged;

  /// Said on its own in a final result to end the task early.
  final String? stopWord;
  final void Function()? onStopWord;

  /// The recogniser cannot be used: not available, no permission, or an error
  /// a restart will not fix.
  final void Function()? onFailure;

  // A process-wide singleton. Its initialize() runs once per app run and then
  // ignores its arguments, so the callbacks given to it belong to whichever
  // screen initialized first. They are assigned directly instead, every time
  // a listener takes over the mic.
  final SpeechToText _speech = SpeechToText();

  final List<String> _words = [];
  final Set<String> _seen = {};
  List<String> _pending = const [];
  bool _active = false;
  bool _disposed = false;
  Timer? _restart;

  /// Committed words, in the order they were first heard, without repeats.
  List<String> get words => List.unmodifiable(_words);

  /// Words of the utterance in progress, not yet confirmed.
  List<String> get pendingWords =>
      _pending.where((w) => !_seen.contains(w.toLowerCase())).toList();

  /// True from [start] until [stop], including the short gaps between
  /// sessions.
  bool get isListening => _active;

  Future<bool> initialize() async {
    final ok = await _speech.initialize();
    _attach();
    return ok;
  }

  void _attach() {
    _speech.statusListener = _onStatus;
    _speech.errorListener = _onError;
  }

  Future<void> start() async {
    if (_disposed || _active) return;
    _attach();
    _active = true;
    onChanged();
    await _listen();
  }

  /// Stops listening and keeps whatever was being said when it stopped.
  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    _restart?.cancel();
    _commit(_pending);
    _pending = const [];
    await _speech.stop();
    if (!_disposed) onChanged();
  }

  void dispose() {
    _disposed = true;
    _active = false;
    _restart?.cancel();
    if (_speech.statusListener == _onStatus) _speech.statusListener = null;
    if (_speech.errorListener == _onError) _speech.errorListener = null;
    _speech.cancel();
  }

  Future<void> _listen() async {
    if (!_active || _disposed || _speech.isListening) return;
    try {
      await _speech.listen(
        onResult: _onResult,
        localeId: localeId,
        // Short sessions keep each result quick to arrive. A session that
        // hits either limit is simply restarted.
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          // Dictation, not confirmation: confirmation is tuned for a short
          // command and ends the session sooner.
          listenMode: ListenMode.dictation,
          cancelOnError: false,
        ),
      );
    } catch (_) {
      _scheduleRestart(const Duration(milliseconds: 600));
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    if (_disposed) return;
    final heard = _split(result.recognizedWords);
    if (result.finalResult) {
      _commit(heard);
      _pending = const [];
      final stop = stopWord;
      if (stop != null && heard.any((w) => w.toLowerCase() == stop)) {
        onStopWord?.call();
      }
    } else {
      _pending = heard;
    }
    onChanged();
  }

  void _onStatus(String status) {
    if (_disposed || !_active) return;
    if (status == SpeechToText.doneStatus) {
      // Every result of the session has been delivered. One that closed
      // without a final result would otherwise drop what it had heard.
      _commit(_pending);
      _pending = const [];
      onChanged();
      _scheduleRestart(const Duration(milliseconds: 300));
    } else if (status == SpeechToText.notListeningStatus) {
      // The mic is off but the final result may still be on its way, and a
      // new session started now would discard it. `done` normally follows
      // and restarts sooner; this is the fallback if it never does.
      _scheduleRestart(const Duration(milliseconds: 1500));
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (_disposed || !_active) return;
    // Silence and "nothing matched" end a session in the normal course of a
    // fluency task, when the patient pauses to think.
    const routine = {
      'error_no_match',
      'error_speech_timeout',
      'error_busy',
      'error_client',
    };
    if (routine.contains(error.errorMsg) || !error.permanent) {
      _scheduleRestart(const Duration(milliseconds: 600));
      return;
    }
    _active = false;
    onChanged();
    onFailure?.call();
  }

  void _scheduleRestart(Duration delay) {
    _restart?.cancel();
    // Restarting the instant a session closes is refused by Android's
    // recogniser as busy, hence the short pause.
    _restart = Timer(delay, _listen);
  }

  void _commit(List<String> heard) {
    for (final w in heard) {
      if (_seen.add(w.toLowerCase())) _words.add(w);
    }
  }

  static List<String> _split(String text) => text
      .split(RegExp(r'[,\s\.;!?]+'))
      .where((w) => w.isNotEmpty)
      .toList();
}
