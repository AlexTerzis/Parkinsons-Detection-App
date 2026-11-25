import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../models/camera_task_protocol.dart';
import '../../../models/camera_task_segment.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../../../models/tracking_event.dart';
import '../../../services/authentication_service.dart';
import '../../../services/scoring/camera_recording.dart';
import '../../../services/scoring/camera_test_report.dart';
import '../../../services/scoring/motor_rating.dart';
import '../../../services/scoring/task_quality.dart';
import '../../../services/test_service.dart';
import '../../../services/tracking_classifier.dart';
import '../patience/hand_landmarker_screen.dart';

/// Where the guided run currently is.
enum CameraTestPhase {
  /// Setup instructions and live camera checks. Nothing recorded yet.
  setup,

  /// Counting down to the next step. Nothing recorded.
  preparing,

  /// A step is recording.
  running,

  /// Stopped at a step boundary, waiting for the patient to resume.
  paused,

  /// All steps done; analysing and saving.
  finishing,

  /// Saved, and showing the result. The patient leaves from here.
  results,
}

/// What the setup screen should tell the patient about the picture right now.
enum SetupHint {
  /// No hand in view.
  noHands,

  /// Only one hand in view; both are needed for the first steps.
  oneHand,

  /// The hands are small in the picture: move closer.
  tooFar,

  /// The hands are cut off or very large: move back.
  tooClose,

  /// Both hands in view at a good size.
  ready,
}

/// Something the patient should hear, spoken by the view.
///
/// The ViewModel decides *when* a cue is due; the view owns the words, because
/// they are localized and the locale lives there.
enum CameraCueKind {
  /// The next step's instruction, at the start of its countdown.
  instruction,

  /// The first step of a hand's block: change hands, then the instruction.
  switchHands,

  /// The previous attempt was not clear enough; the step is being repeated.
  retry,

  /// Recording has started.
  go,

  /// Recording has stopped.
  stop,

  /// The whole test is done.
  finished,
}

class CameraCue {
  const CameraCue(this.kind, [this.task]);

  final CameraCueKind kind;
  final CameraTask? task;
}

/// Drives the camera test's hands-free task sequence.
///
/// Once the patient taps Start, nothing else needs touching: each step counts
/// down on its own (holding while the hands are out of view), records, and
/// moves on. A step the camera could not see properly is repeated once,
/// automatically, and then kept whatever happened, so the run always finishes.
class CameraTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();

  static const TrackingClassifier _classifier = TrackingClassifier();
  static const TaskQualityValidator _validator = TaskQualityValidator();
  static const MotorRatingScorer _scorer = MotorRatingScorer();

  static const int protocolVersion = CameraTestReport.protocolVersion;

  /// The UI ticks about ten times a second so the countdown moves smoothly;
  /// task timing itself comes from the stopwatches, not this.
  static const Duration _tick = Duration(milliseconds: 100);

  /// Recordings of one step in total: the first and one automatic repeat.
  ///
  /// The old flow asked the patient to choose between repeating and
  /// continuing, up to three times, which meant reaching the phone after
  /// every failure. Hands-free, one repeat is offered automatically and the
  /// second recording is kept either way.
  static const int maxAttemptsPerTask = 2;

  /// A hand seen more than this long ago no longer counts as present.
  static const Duration _handStaleAfter = Duration(milliseconds: 700);

  /// Frame-rate window for the live check.
  static const int _fpsWindowMs = 2000;

  /// Below this the setup screen warns that the camera is slow. Tremor
  /// frequency needs 15; fast tapping needs more to be counted reliably.
  static const double slowFpsBelow = 15;

  /// Palm length (wrist to middle knuckle) as a fraction of picture height,
  /// outside which the patient is asked to move. About 1.2 m and 0.3 m away
  /// on a typical front camera.
  static const double _tooFarBelow = 0.07;
  static const double _tooCloseAbove = 0.30;

  CameraTestPhase _phase = CameraTestPhase.setup;

  final List<CameraTask> _tasks = CameraTaskProtocol.build();
  final List<CameraTaskSegment> _segments = <CameraTaskSegment>[];
  int _taskIndex = 0;

  final Map<String, int> _attempts = <String, int>{};
  final Map<String, TaskQuality> _qualities = <String, TaskQuality>{};
  final List<CameraTaskSegment> _discarded = <CameraTaskSegment>[];

  /// Why the step being prepared is a repeat, if it is one.
  TaskQuality? _retryReason;
  TaskQuality? get retryReason => _retryReason;

  CameraTestReport? _report;
  CameraTestReport? get report => _report;

  MotorRating? get rating => _report?.rating;

  /// The stored 0-1 score, or `null` when nothing could be rated.
  double? get score => _report?.score;

  String? _reportError;
  String? get reportError => _reportError;

  bool _resultSaved = false;
  bool get resultSaved => _resultSaved;

  Timer? _timer;
  final Stopwatch _taskWatch = Stopwatch();
  final Stopwatch _leadInWatch = Stopwatch();

  bool _pauseRequested = false;
  bool _disposed = false;

  /// Receives spoken cues; set by the view.
  void Function(CameraCue cue)? onCue;

  CameraTestViewModel() {
    // Keeps the setup screen's checks current even when frames stop arriving
    // (the camera only reports when it processes a frame, so a hand leaving
    // the picture would otherwise leave the last state on screen).
    _setupTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_phase == CameraTestPhase.setup && !_disposed) notifyListeners();
    });
  }

  Timer? _setupTimer;

  void _cue(CameraCueKind kind, [CameraTask? task]) =>
      onCue?.call(CameraCue(kind, task));

  // --- Live camera state, in every phase ---

  DateTime? _lastFrameSeen;
  int _handsInView = 0;
  double? _palmFraction;
  bool _anyClipped = false;
  final Queue<int> _frameTimes = Queue<int>();

  /// How many hands the camera can see right now.
  int get handsInView => _isFresh ? _handsInView : 0;

  bool get _isFresh {
    final seen = _lastFrameSeen;
    return seen != null && DateTime.now().difference(seen) < _handStaleAfter;
  }

  /// Frames per second actually coming out of the detector, over the last two
  /// seconds. 0 until frames arrive.
  double get measuredFps {
    if (_frameTimes.length < 2) return 0;
    final int span = _frameTimes.last - _frameTimes.first;
    if (span <= 0) return 0;
    return (_frameTimes.length - 1) * 1000 / span;
  }

  bool get cameraIsSlow => measuredFps > 0 && measuredFps < slowFpsBelow;

  /// Whether the camera has delivered anything yet.
  bool get cameraLive => _isFresh;

  SetupHint get setupHint {
    final n = handsInView;
    if (n == 0) return SetupHint.noHands;
    final palm = _palmFraction;
    if (_anyClipped || (palm != null && palm > _tooCloseAbove)) {
      return SetupHint.tooClose;
    }
    if (palm != null && palm < _tooFarBelow) return SetupHint.tooFar;
    if (n < 2) return SetupHint.oneHand;
    return SetupHint.ready;
  }

  /// Whether the hands the current step needs are in view.
  bool get requiredHandsVisible {
    final task = currentTask;
    if (task == null) return false;
    return handsInView >= task.hands.length;
  }

  /// True while a step's countdown is held because its hands are not in view.
  bool get awaitingHand =>
      _phase == CameraTestPhase.preparing && !requiredHandsVisible;

  // --- View state ---

  CameraTestPhase get phase => _phase;
  bool get isRunning => _phase == CameraTestPhase.running;
  bool get isPaused => _phase == CameraTestPhase.paused;
  bool get isSetup => _phase == CameraTestPhase.setup;

  /// Whole seconds left of the countdown before recording starts.
  int? get leadInCountdown {
    final task = currentTask;
    if (task == null || _phase != CameraTestPhase.preparing) return null;
    final int remainingMs =
        task.leadIn.inMilliseconds - _leadInWatch.elapsedMilliseconds;
    return remainingMs <= 0 ? 0 : (remainingMs / 1000).ceil();
  }

  List<CameraTask> get tasks => List.unmodifiable(_tasks);
  int get taskIndex => _taskIndex;
  int get taskCount => _tasks.length;

  CameraTask? get currentTask =>
      _taskIndex < _tasks.length ? _tasks[_taskIndex] : null;

  CameraTask? get nextTask =>
      _taskIndex + 1 < _tasks.length ? _tasks[_taskIndex + 1] : null;

  /// Whole seconds left in the current recording.
  int get countdown {
    final task = currentTask;
    if (task == null) return 0;
    final int remainingMs =
        task.duration.inMilliseconds - _taskWatch.elapsedMilliseconds;
    if (remainingMs <= 0) return 0;
    return (remainingMs / 1000).ceil();
  }

  /// Progress through the whole protocol, 0-1.
  double get overallProgress {
    final int totalMs = _tasks.fold<int>(
        0, (sum, task) => sum + task.duration.inMilliseconds);
    if (totalMs == 0) return 0;

    int doneMs = 0;
    for (int i = 0; i < _taskIndex && i < _tasks.length; i++) {
      doneMs += _tasks[i].duration.inMilliseconds;
    }
    final task = currentTask;
    if (task != null && _phase == CameraTestPhase.running) {
      doneMs += _taskWatch.elapsedMilliseconds
          .clamp(0, task.duration.inMilliseconds);
    }
    return (doneMs / totalMs).clamp(0.0, 1.0);
  }

  /// Progress through the current recording alone, 0-1.
  double get taskProgress {
    final task = currentTask;
    if (task == null || task.duration.inMilliseconds == 0) return 0;
    return (_taskWatch.elapsedMilliseconds / task.duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  bool get pausePending => _pauseRequested && _phase == CameraTestPhase.running;

  /// Whether every hand being examined is visible right now.
  bool get targetHandVisible => _targetHandVisible;
  bool _targetHandVisible = false;

  /// What the most recent frame was worth, for neutral technical feedback.
  TrackingState get trackingState => _trackingState;
  TrackingState _trackingState = TrackingState.noHand;

  /// Approximate whole minutes the test takes.
  int get estimatedMinutes =>
      (CameraTaskProtocol.totalDuration().inSeconds / 60).ceil();

  // --- Control ---

  List<CameraTaskSegment> _freshSegmentsFor(CameraTask task) => task.hands
      .map((hand) => CameraTaskSegment(task: task, hand: hand))
      .toList(growable: false);

  List<CameraTaskSegment> _segmentsForIndex(int index) {
    if (index < 0 || index >= _tasks.length) return const <CameraTaskSegment>[];
    final task = _tasks[index];
    return _segments
        .where((s) => identical(s.task, task))
        .toList(growable: false);
  }

  List<CameraTaskSegment> get _currentSegments => _segmentsForIndex(_taskIndex);

  /// Begins the run from the first step. The only tap the patient needs.
  void start() {
    _segments
      ..clear()
      ..addAll(_tasks.expand(_freshSegmentsFor));
    _attempts.clear();
    _qualities.clear();
    _discarded.clear();
    _retryReason = null;
    _reportError = null;
    _taskIndex = 0;
    _pauseRequested = false;
    _trackingState = TrackingState.noHand;
    _targetHandVisible = false;
    _beginCurrentTask();
    notifyListeners();
  }

  void requestPause() {
    if (_phase != CameraTestPhase.running) return;
    _pauseRequested = true;
    notifyListeners();
  }

  void cancelPauseRequest() {
    if (!_pauseRequested) return;
    _pauseRequested = false;
    notifyListeners();
  }

  void resume() {
    if (_phase != CameraTestPhase.paused) return;
    _pauseRequested = false;
    _beginCurrentTask();
    notifyListeners();
  }

  /// Abandons the run without saving.
  void cancel() {
    _stopTimer();
    locator<NavigationService>().back();
  }

  /// Opens a step's countdown and announces it.
  void _beginCurrentTask() {
    final task = currentTask;
    _phase = CameraTestPhase.preparing;
    _leadInWatch.reset();

    if (task != null) {
      if (_retryReason != null) {
        _cue(CameraCueKind.retry, task);
      } else if (task.switchesHand) {
        _cue(CameraCueKind.switchHands, task);
      } else {
        _cue(CameraCueKind.instruction, task);
      }
    }

    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _onPrepareTick());
  }

  void _onPrepareTick() {
    final task = currentTask;
    if (task == null) return;

    // The countdown holds while the hands are out of view, rather than running
    // down and recording an empty picture.
    if (!requiredHandsVisible) {
      _leadInWatch.stop();
      notifyListeners();
      return;
    }
    if (!_leadInWatch.isRunning) _leadInWatch.start();

    if (_leadInWatch.elapsedMilliseconds >= task.leadIn.inMilliseconds) {
      _beginRecording();
    } else {
      notifyListeners();
    }
  }

  void _beginRecording() {
    final task = currentTask;
    if (task == null) return;

    final now = DateTime.now();
    for (final segment in _currentSegments) {
      segment.startedAt = now;
    }
    _attempts[task.id] = (_attempts[task.id] ?? 0) + 1;

    // Reset per task: every rhythm and duration figure is measured from this
    // task's own first frame, so nothing carries across a boundary.
    _taskWatch
      ..reset()
      ..start();

    _phase = CameraTestPhase.running;
    _cue(CameraCueKind.go, task);
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _onTick());
    notifyListeners();
  }

  void _onTick() {
    final task = currentTask;
    if (task == null) return;

    if (_taskWatch.elapsedMilliseconds >= task.duration.inMilliseconds) {
      _completeCurrentTask();
    } else {
      notifyListeners();
    }
  }

  /// Ends the current step, checks it, and either repeats it once or moves on.
  void _completeCurrentTask() {
    _stopTimer();

    final segments = _currentSegments;
    final task = currentTask;
    if (segments.isEmpty || task == null) return;

    final now = DateTime.now();
    for (final segment in segments) {
      segment.endedAt = now;
    }

    // Each hand is validated on its own; a both-hands step where one hand
    // stayed out of view is not a usable recording of that step.
    TaskQuality? failed;
    for (final recorded in CameraRecording.fromSegments(segments).tasks) {
      final quality = _validator.validate(recorded);
      _qualities[recorded.taskId] = quality;
      if (quality.retryRecommended && failed == null) failed = quality;
    }

    _cue(CameraCueKind.stop, task);

    if (failed != null && canRetryCurrentTask) {
      _repeatCurrentTask(failed);
      return;
    }

    _retryReason = null;
    _advanceToNextTask();
  }

  /// Records the current step again, keeping everything already completed.
  ///
  /// The rejected attempt is set aside, not deleted: it is uploaded under its
  /// own key as the record of what went wrong.
  void _repeatCurrentTask(TaskQuality reason) {
    final task = currentTask;
    final existing = _currentSegments;
    if (task == null) return;

    _discarded.addAll(existing);
    final int at = _segments.indexWhere((s) => identical(s.task, task));
    _segments.removeWhere((s) => identical(s.task, task));
    _segments.insertAll(at, _freshSegmentsFor(task));
    for (final hand in task.hands) {
      _qualities.remove(task.segmentId(hand));
    }

    _retryReason = reason;
    _targetHandVisible = false;
    _trackingState = TrackingState.noHand;
    _beginCurrentTask();
    notifyListeners();
  }

  void _advanceToNextTask() {
    _taskIndex++;
    _targetHandVisible = false;
    _trackingState = TrackingState.noHand;

    if (_taskIndex >= _tasks.length) {
      _phase = CameraTestPhase.finishing;
      _cue(CameraCueKind.finished);
      notifyListeners();
      unawaited(_finish());
      return;
    }

    if (_pauseRequested) {
      _pauseRequested = false;
      _phase = CameraTestPhase.paused;
      notifyListeners();
      return;
    }

    _beginCurrentTask();
    notifyListeners();
  }

  // --- Quality ---

  Map<String, TaskQuality> get qualities => Map.unmodifiable(_qualities);

  @visibleForTesting
  List<CameraTaskSegment> get segments => List.unmodifiable(_segments);

  /// Ends the current step now, as the timer would have.
  @visibleForTesting
  void completeCurrentTask() => _completeCurrentTask();

  /// Skips the countdown and starts recording immediately.
  @visibleForTesting
  void beginRecordingNow() {
    if (_phase != CameraTestPhase.preparing) return;
    _beginRecording();
  }

  int attemptsFor(String taskId) => _attempts[taskId] ?? 0;

  int get currentAttempt {
    final task = currentTask;
    return task == null ? 0 : attemptsFor(task.id);
  }

  bool get canRetryCurrentTask => currentAttempt < maxAttemptsPerTask;

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _taskWatch.stop();
  }

  // --- Capture ---

  /// Receives every processed frame from the landmarker.
  ///
  /// Every frame updates the live checks (hands in view, frame rate, distance)
  /// in every phase; only frames during a recording are kept. During a
  /// recording *every* frame is recorded, including those holding no hand, so
  /// coverage and frame rate are computed against what the camera actually
  /// delivered.
  void onFrame(FrameData frame) {
    _updateLiveChecks(frame);

    if (_phase != CameraTestPhase.running) {
      if (_phase == CameraTestPhase.setup) _notifySetupIfChanged();
      return;
    }

    final task = currentTask;
    final segments = _currentSegments;
    if (task == null || segments.isEmpty) return;

    final events =
        _classifier.classifyAll(frame: frame, targetHands: task.hands);
    TrackingState? worst;
    for (final segment in segments) {
      final event = events[segment.hand]!;
      segment.add(event);
      if (worst == null || _severity(event.state) > _severity(worst)) {
        worst = event.state;
      }
    }

    _updateLiveFeedback(worst!);
  }

  SetupHint? _lastHint;
  int _lastFpsShown = -1;
  DateTime _lastSetupNotify = DateTime.fromMillisecondsSinceEpoch(0);

  /// Rebuilds the setup screen when what it shows changed, not per frame.
  void _notifySetupIfChanged() {
    final hint = setupHint;
    final fps = measuredFps.round();
    final now = DateTime.now();
    if (hint == _lastHint &&
        fps == _lastFpsShown &&
        now.difference(_lastSetupNotify) < const Duration(seconds: 1)) {
      return;
    }
    _lastHint = hint;
    _lastFpsShown = fps;
    _lastSetupNotify = now;
    notifyListeners();
  }

  void _updateLiveChecks(FrameData frame) {
    _lastFrameSeen = DateTime.now();
    _handsInView = frame.hands.where((h) => h.landmarks.isNotEmpty).length;

    _frameTimes.addLast(frame.timestamp);
    while (_frameTimes.length > 2 &&
        frame.timestamp - _frameTimes.first > _fpsWindowMs) {
      _frameTimes.removeFirst();
    }

    double? palm;
    bool clipped = false;
    for (final hand in frame.hands) {
      final lm = hand.landmarks;
      if (lm.length < 21) continue;
      final dx = lm[0].x - lm[9].x;
      final dy = lm[0].y - lm[9].y;
      final length = math.sqrt(dx * dx + dy * dy);
      palm = palm == null ? length : math.max(palm, length);
      for (final p in lm) {
        if (p.x < -0.02 || p.x > 1.02 || p.y < -0.02 || p.y > 1.02) {
          clipped = true;
        }
      }
    }
    _palmFraction = palm;
    _anyClipped = clipped;
  }

  int _severity(TrackingState state) {
    switch (state) {
      case TrackingState.tracked:
        return 0;
      case TrackingState.lowConfidence:
        return 1;
      case TrackingState.partiallyOutOfFrame:
        return 2;
      case TrackingState.incompleteLandmarks:
        return 3;
      case TrackingState.wrongHand:
        return 4;
      case TrackingState.noHand:
        return 5;
    }
  }

  void _updateLiveFeedback(TrackingState state) {
    final bool visible = state.contributesLandmarks;
    if (visible == _targetHandVisible && state == _trackingState) return;
    _targetHandVisible = visible;
    _trackingState = state;
    notifyListeners();
  }

  // --- Completion ---

  Future<void> _finish() async {
    setBusy(true);

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setBusy(false);
      locator<NavigationService>().back(result: false);
      return;
    }

    final recording = CameraRecording.fromSegments(_segments);
    final metrics = _summary(recording);

    try {
      final rating = _scorer.rate(recording, qualities: _qualities);
      _report = const CameraReportBuilder().build(
        recording,
        qualities: _qualities,
        rating: rating,
        retryCount: _discarded.length,
        performedAt: DateTime.now(),
      );
      metrics.addAll(_report!.toJson());
    } catch (e, stack) {
      // An analysis crash must not cost the patient their recording, and must
      // not be hidden as "nothing measured" either.
      debugPrint('Could not build camera report: $e\n$stack');
      _reportError = e.toString();
      metrics['report_error'] = _reportError;
    }

    // A run with no rated movement is not saved: there is no score to store,
    // and storing 0 would file it as a perfect result.
    final double? finalScore = score;
    if (finalScore == null) {
      if (_disposed) return;
      setBusy(false);
      _phase = CameraTestPhase.results;
      notifyListeners();
      return;
    }

    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.cameraDetection,
      performedAt: DateTime.now(),
      score: finalScore,
      data: metrics,
    );

    try {
      await _tests.addResult(
        result: result,
        taskSegments: {
          for (final segment in _segments)
            if (segment.samples.isNotEmpty) segment.taskId: segment.toJson(),
          for (int i = 0; i < _discarded.length; i++)
            if (_discarded[i].samples.isNotEmpty)
              '${_discarded[i].taskId}__rejected$i': <String, dynamic>{
                ..._discarded[i].toJson(),
                'rejected': true,
              },
        },
      );
      _resultSaved = true;
    } catch (e) {
      debugPrint('Could not save camera test result: $e');
    }

    if (_disposed) return;
    setBusy(false);
    _phase = CameraTestPhase.results;
    notifyListeners();
  }

  void finishFromResults() {
    locator<NavigationService>().back(result: true);
  }

  void repeatTest() {
    _report = null;
    _reportError = null;
    _resultSaved = false;
    _retryReason = null;
    _phase = CameraTestPhase.setup;
    _segments.clear();
    _attempts.clear();
    _qualities.clear();
    _discarded.clear();
    _taskIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimer();
    _setupTimer?.cancel();
    onCue = null;
    super.dispose();
  }

  /// Recording facts stored alongside the report.
  Map<String, dynamic> _summary(CameraRecording recording) {
    final List<double> rates =
        _segments.map((s) => s.fps).where((f) => f > 0).toList();
    final List<double> processed =
        _segments.map((s) => s.processedFps).where((f) => f > 0).toList();
    double mean(List<double> v) =>
        v.isEmpty ? 0.0 : v.reduce((a, b) => a + b) / v.length;

    return <String, dynamic>{
      'protocol_version': protocolVersion,
      'orientation': 'landscape',
      'mds_updrs_items': <String>{for (final t in _tasks) t.mdsUpdrsItem}
          .toList(growable: false),
      'frames': recording.frameCount,
      'mean_fps': mean(rates),
      'mean_processed_fps': mean(processed),
      'quality_rules_version': const QualityRules().version,
      'task_quality': <String, dynamic>{
        for (final entry in _qualities.entries) entry.key: entry.value.toJson(),
      },
      'attempts': Map<String, int>.of(_attempts),
      'invalid_tasks': _qualities.values
          .where((q) => !q.valid)
          .map((q) => q.taskId)
          .toList(growable: false),
      'tasks': _segments
          .map((segment) => segment.toSummaryJson())
          .toList(growable: false),
    };
  }
}
