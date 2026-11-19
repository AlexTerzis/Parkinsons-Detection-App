import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../models/frame_data.dart';
import '../../../models/hand_posture.dart';
import '../../../models/posture_test_result.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../../../services/authentication_service.dart';
import '../../../services/hand_posture_classifier.dart';
import '../../../services/test_service.dart';

/// Where the posture run currently is.
enum PostureTestPhase {
  /// Instructions shown, nothing recorded yet.
  setup,

  /// Showing the posture to copy, waiting for the patient to begin.
  preparing,

  /// Watching for the posture to be held.
  running,

  /// Saving.
  finishing,

  /// Showing what was copied.
  results,
}

/// Drives the hand and finger posture imitation run.
///
/// The reason this test exists alongside the camera assessment is that it rests
/// on a much more forgiving signal. A posture needs the hand seen clearly for a
/// fraction of a second, not tracked continuously for twelve; there is no frame
/// rate floor, no rhythm, no decrement and no spectrum. Where the movement items
/// return nothing at all on a difficult device, this still returns something.
class PostureTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();

  static const HandPostureClassifier _postures = HandPostureClassifier();

  /// Frames the posture must be held for before it counts.
  ///
  /// A hand on its way from one shape to another passes through others, and a
  /// single frame cannot tell that from a posture deliberately held. Requiring
  /// a run of frames is what separates them — the same guard the FAB gesture
  /// step uses.
  static const int framesToHold = 5;

  /// How long one attempt runs before it is given up on.
  static const Duration trialTimeout = Duration(seconds: 12);

  static const Duration _tick = Duration(milliseconds: 100);

  PostureTestPhase _phase = PostureTestPhase.setup;
  final List<HandPosture> _sequence = HandPostures.all;

  int _index = 0;
  int _trial = 1;

  Timer? _timer;
  final Stopwatch _trialWatch = Stopwatch();

  /// Consecutive frames the target posture has been held for.
  int _heldFrames = 0;

  int _usableFrames = 0;
  int _totalFrames = 0;
  String? _observedPostureId;

  final Map<String, List<PostureAttempt>> _attempts =
      <String, List<PostureAttempt>>{};

  PostureTestResult? _result;
  bool _resultSaved = false;
  bool _disposed = false;

  // --- View state ---

  PostureTestPhase get phase => _phase;
  bool get isRunning => _phase == PostureTestPhase.running;

  List<HandPosture> get sequence => List.unmodifiable(_sequence);
  int get index => _index;
  int get total => _sequence.length;
  int get trial => _trial;
  int get trialsPerPosture => HandPostures.trialsPerPosture;

  HandPosture? get currentPosture =>
      _index < _sequence.length ? _sequence[_index] : null;

  PostureTestResult? get result => _result;
  bool get resultSaved => _resultSaved;

  /// Whether this is a repeat of a posture already attempted once.
  bool get isRetry => _trial > 1;

  double get progress => total == 0 ? 0 : _index / total;

  /// Seconds left in this attempt.
  int get secondsLeft {
    final int remaining =
        trialTimeout.inMilliseconds - _trialWatch.elapsedMilliseconds;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }

  /// How close the current attempt is to being accepted, 0-1.
  double get holdProgress => (_heldFrames / framesToHold).clamp(0.0, 1.0);

  /// Whether the hand is visible right now, so the patient can be told before
  /// the attempt is wasted.
  bool get handVisible => _handVisible;
  bool _handVisible = false;

  // --- Control ---

  void start() {
    _attempts.clear();
    _index = 0;
    _trial = 1;
    _result = null;
    _resultSaved = false;
    _beginAttempt();
  }

  /// Shows the posture and waits for the patient.
  void _beginAttempt() {
    _heldFrames = 0;
    _usableFrames = 0;
    _totalFrames = 0;
    _observedPostureId = null;
    _handVisible = false;
    _phase = PostureTestPhase.preparing;
    _stopTimer();
    notifyListeners();
  }

  /// Begins watching for the posture. The patient's "I'm ready".
  void beginWatching() {
    if (_phase != PostureTestPhase.preparing) return;
    _phase = PostureTestPhase.running;
    _trialWatch
      ..reset()
      ..start();
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _onTick());
    notifyListeners();
  }

  void _onTick() {
    if (_trialWatch.elapsedMilliseconds >= trialTimeout.inMilliseconds) {
      _endAttempt(_totalFrames == 0 || _usableFrames == 0
          ? PostureOutcome.notRecorded
          : PostureOutcome.notCopied);
    } else {
      notifyListeners();
    }
  }

  /// Receives every processed frame from the landmarker.
  void onFrame(FrameData frame) {
    if (_phase != PostureTestPhase.running) return;
    final posture = currentPosture;
    if (posture == null) return;

    _totalFrames++;

    // Every processed frame is counted, including those with no hand, so
    // "did not copy the posture" stays separate from "the hand was never seen".
    //
    // Handedness is deliberately not constrained. The task is to copy a shape;
    // either hand may be used, and the detector's Left/Right label is the least
    // reliable thing it reports — insisting on a side here would reintroduce
    // exactly the failure that made the camera test impossible to complete.
    final shape = _describeAnyHand(frame);

    if (shape == null) {
      _heldFrames = 0;
      _setHandVisible(false);
      return;
    }

    _usableFrames++;
    _setHandVisible(true);

    if (posture.matches(shape.shape)) {
      _heldFrames++;
      if (_heldFrames >= framesToHold) {
        _endAttempt(PostureOutcome.copied);
        return;
      }
    } else {
      // The posture has to be *held*: a broken run starts over.
      _heldFrames = 0;
      _observedPostureId = shape.recognisedId;
    }
    notifyListeners();
  }

  /// Describes the first hand in [frame] that the classifier can read.
  _ReadHand? _describeAnyHand(FrameData frame) {
    for (final hand in frame.hands) {
      final shape = _postures.describe(hand.landmarks);
      if (shape == null) continue;
      return _ReadHand(
        shape: shape,
        recognisedId: _postures
            .identify(hand.landmarks, handedness: hand.handedness)
            ?.id,
      );
    }
    return null;
  }

  void _setHandVisible(bool visible) {
    if (visible == _handVisible) return;
    _handVisible = visible;
    notifyListeners();
  }

  void _endAttempt(PostureOutcome outcome) {
    _stopTimer();
    final posture = currentPosture;
    if (posture == null) return;

    _attempts.putIfAbsent(posture.id, () => <PostureAttempt>[]).add(
          PostureAttempt(
            trial: _trial,
            outcome: outcome,
            usableFrames: _usableFrames,
            totalFrames: _totalFrames,
            secondsTaken: outcome == PostureOutcome.copied
                ? _trialWatch.elapsedMilliseconds / 1000.0
                : null,
            observedPostureId:
                outcome == PostureOutcome.copied ? null : _observedPostureId,
          ),
        );

    final bool exhausted = _trial >= HandPostures.trialsPerPosture;
    if (outcome != PostureOutcome.copied && !exhausted) {
      _trial++;
      _beginAttempt();
      return;
    }

    _index++;
    _trial = 1;

    if (_index >= _sequence.length) {
      _phase = PostureTestPhase.finishing;
      notifyListeners();
      unawaited(_finish());
      return;
    }

    _beginAttempt();
  }

  /// Gives up on the current posture without waiting out the timer.
  void skipCurrent() {
    if (_phase != PostureTestPhase.running &&
        _phase != PostureTestPhase.preparing) {
      return;
    }
    _endAttempt(_usableFrames == 0
        ? PostureOutcome.notRecorded
        : PostureOutcome.notCopied);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _trialWatch.stop();
  }

  // --- Completion ---

  Future<void> _finish() async {
    setBusy(true);

    final result = PostureTestResult(
      performedAt: DateTime.now(),
      items: <PostureItemResult>[
        for (final posture in _sequence)
          PostureItemResult(
            postureId: posture.id,
            attempts: _attempts[posture.id] ?? const <PostureAttempt>[],
          ),
      ],
    );
    _result = result;

    final uid = _auth.currentUser?.uid;

    // A run that never saw the hand is not saved. Its score would be zero, and
    // zero on this scale means "copied none of them" — a statement about the
    // patient that the recording gives no grounds for.
    if (uid != null && result.hasUsableRecording) {
      try {
        await _tests.addResult(
          result: TestResult(
            id: '',
            patientId: uid,
            type: TestType.posture,
            performedAt: result.performedAt,
            score: result.concern,
            data: result.toJson(),
          ),
        );
        _resultSaved = true;
      } catch (e) {
        debugPrint('Could not save posture test result: $e');
      }
    }

    if (_disposed) return;
    setBusy(false);
    _phase = PostureTestPhase.results;
    notifyListeners();
  }

  void finishFromResults() => locator<NavigationService>().back(result: true);

  void repeatTest() {
    _phase = PostureTestPhase.setup;
    _result = null;
    _resultSaved = false;
    notifyListeners();
  }

  void cancel() {
    _stopTimer();
    locator<NavigationService>().back();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimer();
    super.dispose();
  }
}

/// A hand the classifier could read, and what it made of it.
class _ReadHand {
  const _ReadHand({required this.shape, this.recognisedId});

  final HandShape shape;

  /// The catalogue posture recognised, if the shape was one of them. Kept so a
  /// patient copying the wrong posture is recorded as having done that, rather
  /// than as having made no shape at all.
  final String? recognisedId;
}
