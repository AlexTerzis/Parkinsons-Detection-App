import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../models/camera_task_protocol.dart';
import '../../../models/camera_task_segment.dart';
import '../../../models/landmark_point.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../../../models/tracking_event.dart';
import '../../../services/authentication_service.dart';
import '../../../services/hand_metrics.dart';
import '../../../services/parkinson_config.dart';
import '../../../services/scoring/camera_recording.dart';
import '../../../services/scoring/camera_scoring_service.dart';
import '../../../services/scoring/camera_test_report.dart';
import '../../../services/scoring/task_quality.dart';
import '../../../services/test_service.dart';
import '../../../services/tracking_classifier.dart';
import '../patience/hand_landmarker_screen.dart';

/// Where the guided run currently is.
enum CameraTestPhase {
  /// Instructions shown, nothing being recorded yet.
  setup,

  /// Showing the next step's instruction, waiting to begin. Nothing recorded.
  preparing,

  /// A task is running and frames are being captured.
  running,

  /// Stopped cleanly at a task boundary, waiting for the patient to resume.
  paused,

  /// The task that just finished was not recorded well enough to measure, and
  /// the patient is being offered a repeat of it.
  taskReview,

  /// All tasks done; analysing and saving.
  finishing,

  /// Saved, and showing what was measured. The patient leaves from here.
  results,
}

/// Drives the camera test's guided MDS-UPDRS task sequence.
///
/// The test used to be a single undifferentiated 29-second capture. It is now a
/// sequence of timed tasks per hand (see [CameraTaskProtocol]); frames are
/// captured into one segment per task so each movement can be analysed on its
/// own as well as in aggregate.
class CameraTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  final HandMetrics _metrics = locator<HandMetrics>();
  final CameraScoringService _scoring = locator<CameraScoringService>();

  /// Pure and stateless, so they are constructed rather than located.
  ///
  /// The default accepts a lone hand as the one under examination even when the
  /// detector labels it as the other side, because that label is unreliable —
  /// see [TrackingClassifier.acceptLoneHandAsTarget].
  static const TrackingClassifier _classifier = TrackingClassifier();

  /// Used when both hands are recorded together.
  ///
  /// With two hands in the frame the labels are the only thing distinguishing
  /// them, so the lone-hand fallback cannot apply — and does not need to, since
  /// a frame holding two hands is never ambiguous about which is which.
  static const TrackingClassifier _strictClassifier =
      TrackingClassifier(acceptLoneHandAsTarget: false);

  /// Bumped whenever the stored shape changes, so an analysis job can tell a
  /// guided run from the old single-capture documents. Version 1 is implicit
  /// in documents written before the protocol existed.
  ///
  /// Owned by [CameraTestReport] rather than duplicated, so the number written
  /// here and the number written by the report cannot drift apart.
  static const int protocolVersion = CameraTestReport.protocolVersion;

  /// The UI ticks about ten times a second so the countdown and progress bar
  /// move smoothly; task timing itself comes from [_taskWatch], not this.
  static const Duration _tick = Duration(milliseconds: 100);

  /// How many times one task may be recorded in total.
  ///
  /// Capped rather than unlimited: a patient whose room is too dark, or whose
  /// phone cannot keep up, would otherwise be asked to repeat the same step
  /// forever. After the cap the step can be kept as it is and the run
  /// continues, with the failure recorded against it.
  static const int maxAttemptsPerTask = 3;

  CameraTestPhase _phase = CameraTestPhase.setup;
  CameraTestMode _mode = CameraTestMode.full;

  List<CameraTask> _tasks = CameraTaskProtocol.build(CameraTestMode.full);
  final List<CameraTaskSegment> _segments = <CameraTaskSegment>[];
  int _taskIndex = 0;

  /// Attempts made per task id, including the one in progress.
  final Map<String, int> _attempts = <String, int>{};

  /// The verdict on each task, keyed by task id — the latest attempt's.
  final Map<String, TaskQuality> _qualities = <String, TaskQuality>{};

  /// Attempts that were rejected and re-recorded.
  ///
  /// Kept rather than thrown away: a discarded attempt is the record of what
  /// went wrong, and is uploaded alongside the accepted one under its own key.
  final List<CameraTaskSegment> _discarded = <CameraTaskSegment>[];

  static const TaskQualityValidator _validator = TaskQualityValidator();

  /// The finished report, available once the run has been analysed.
  CameraTestReport? _report;
  CameraTestReport? get report => _report;

  /// Why the detailed analysis failed, when it did.
  ///
  /// Shown on the results screen and stored with the result. A crash in the
  /// analysis is a bug to be fixed, and hiding it behind "nothing could be
  /// measured" is what stopped it being found.
  String? _reportError;
  String? get reportError => _reportError;

  /// The raw metric map from the last run, for the diagnostic section.
  Map<String, dynamic> _lastMetrics = const <String, dynamic>{};
  Map<String, dynamic> get lastMetrics => Map.unmodifiable(_lastMetrics);

  /// Whether the result reached Firestore. The results screen says so either
  /// way rather than implying a save that did not happen.
  bool _resultSaved = false;
  bool get resultSaved => _resultSaved;

  Timer? _timer;
  final Stopwatch _taskWatch = Stopwatch();

  /// Times the pause before a step records — the countdown in timed pacing, the
  /// get-ready after the patient taps in self-paced.
  final Stopwatch _leadInWatch = Stopwatch();

  CameraPacing _pacing = CameraPacing.selfPaced;

  /// Whether the patient has tapped "start" for the step being prepared.
  bool _readyTapped = false;

  /// When a hand was last seen, in any phase.
  DateTime? _lastHandSeen;

  /// A hand seen more than this long ago no longer counts as present.
  static const Duration _handStaleAfter = Duration(milliseconds: 700);

  /// Whether the detector is live and looking at a hand right now.
  ///
  /// Gates the countdown. Nothing about the protocol is worth starting before
  /// the camera can actually see the hand it is about to measure.
  bool get cameraSeesHand {
    final seen = _lastHandSeen;
    if (seen == null) return false;
    return DateTime.now().difference(seen) < _handStaleAfter;
  }

  /// True while a step is held back waiting for the hand to appear.
  bool get awaitingHand =>
      _phase == CameraTestPhase.preparing && !isAwaitingReady && !cameraSeesHand;

  bool _pauseRequested = false;
  bool _disposed = false;

  // --- View state ---

  CameraTestPhase get phase => _phase;
  CameraTestMode get mode => _mode;
  CameraPacing get pacing => _pacing;
  bool get isRunning => _phase == CameraTestPhase.running;
  bool get isPaused => _phase == CameraTestPhase.paused;
  bool get isSetup => _phase == CameraTestPhase.setup;

  /// True while a step is showing its instruction and waiting for the patient.
  bool get isAwaitingReady =>
      _phase == CameraTestPhase.preparing &&
      _pacing == CameraPacing.selfPaced &&
      !_readyTapped;

  /// Whole seconds left of the get-ready before recording starts, or `null`
  /// while still waiting on the patient.
  int? get leadInCountdown {
    final task = currentTask;
    if (task == null || _phase != CameraTestPhase.preparing) return null;
    if (isAwaitingReady) return null;
    final int remainingMs =
        task.leadIn.inMilliseconds - _leadInWatch.elapsedMilliseconds;
    return remainingMs <= 0 ? 0 : (remainingMs / 1000).ceil();
  }

  List<CameraTask> get tasks => List.unmodifiable(_tasks);
  int get taskIndex => _taskIndex;
  int get taskCount => _tasks.length;

  CameraTask? get currentTask =>
      _taskIndex < _tasks.length ? _tasks[_taskIndex] : null;

  /// The task that will run when the patient resumes, used to tell them what
  /// is coming while paused.
  CameraTask? get nextTask =>
      _taskIndex + 1 < _tasks.length ? _tasks[_taskIndex + 1] : null;

  /// Whole seconds left in the current task, rounded up so the display reaches
  /// zero exactly when the task ends rather than a tick early.
  int get countdown {
    final task = currentTask;
    if (task == null) return 0;
    final int remainingMs =
        task.duration.inMilliseconds - _taskWatch.elapsedMilliseconds;
    if (remainingMs <= 0) return 0;
    return (remainingMs / 1000).ceil();
  }

  /// Progress through the whole protocol, 0-1. Counts completed tasks plus the
  /// elapsed part of the current one, so the bar advances during a task and
  /// not only at boundaries.
  double get overallProgress {
    final int totalMs = _tasks.fold<int>(
        0, (sum, task) => sum + task.duration.inMilliseconds);
    if (totalMs == 0) return 0;

    int doneMs = 0;
    for (int i = 0; i < _taskIndex && i < _tasks.length; i++) {
      doneMs += _tasks[i].duration.inMilliseconds;
    }
    final task = currentTask;
    if (task != null) {
      doneMs += _taskWatch.elapsedMilliseconds
          .clamp(0, task.duration.inMilliseconds);
    }
    return (doneMs / totalMs).clamp(0.0, 1.0);
  }

  /// Progress through the current task alone, 0-1.
  double get taskProgress {
    final task = currentTask;
    if (task == null || task.duration.inMilliseconds == 0) return 0;
    return (_taskWatch.elapsedMilliseconds / task.duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  /// True once the patient has asked to pause but the current task has not yet
  /// finished. Pausing mid-task would leave a partial recording that is not
  /// comparable with a complete one, so the request is honoured at the next
  /// task boundary and the UI says so.
  bool get pausePending => _pauseRequested && _phase == CameraTestPhase.running;

  /// Whether the hand being examined is visible right now, so the UI can warn
  /// before the recording is wasted.
  bool get targetHandVisible => _targetHandVisible;
  bool _targetHandVisible = false;

  /// What the most recent frame was worth, for neutral technical feedback.
  ///
  /// Drives messages like "keep the whole hand in view" — never any reading of
  /// what the movement means.
  TrackingState get trackingState => _trackingState;
  TrackingState _trackingState = TrackingState.noHand;

  // --- Control ---

  /// Chooses the protocol length. Only meaningful before the run starts.
  void setMode(CameraTestMode mode) {
    if (_phase != CameraTestPhase.setup || mode == _mode) return;
    _mode = mode;
    _tasks = CameraTaskProtocol.build(mode);
    notifyListeners();
  }

  /// Chooses who starts each step. Only meaningful before the run starts.
  void setPacing(CameraPacing pacing) {
    if (_phase != CameraTestPhase.setup || pacing == _pacing) return;
    _pacing = pacing;
    notifyListeners();
  }

  Duration get totalDuration => CameraTaskProtocol.totalDuration(_mode);

  /// Range shown for a self-paced run, in whole minutes.
  ///
  /// The recording time is fixed; what varies is how long the patient spends
  /// reading each instruction. The low end assumes they already know the test;
  /// the high end allows roughly a minute per step for someone meeting it for
  /// the first time. A single figure would be a fiction — the whole point of
  /// self-pacing is that the patient sets it.
  int get estimatedMinutesLow =>
      (CameraTaskProtocol.totalDuration(_mode).inSeconds / 60).ceil();

  int get estimatedMinutesHigh {
    final int steps = CameraTaskProtocol.build(_mode).length;
    final int seconds =
        CameraTaskProtocol.recordedDuration(_mode).inSeconds + steps * 45;
    return (seconds / 60).ceil();
  }

  /// Begins the guided sequence from the first task.
  /// One segment per hand of [task] — two of them for a both-hands step.
  List<CameraTaskSegment> _freshSegmentsFor(CameraTask task) => task.hands
      .map((hand) => CameraTaskSegment(task: task, hand: hand))
      .toList(growable: false);

  /// The segments being recorded for the step at [index].
  List<CameraTaskSegment> _segmentsForIndex(int index) {
    if (index < 0 || index >= _tasks.length) return const <CameraTaskSegment>[];
    final task = _tasks[index];
    return _segments
        .where((s) => identical(s.task, task))
        .toList(growable: false);
  }

  void start() {
    _segments
      ..clear()
      ..addAll(_tasks.expand(_freshSegmentsFor));
    _attempts.clear();
    _qualities.clear();
    _discarded.clear();
    _reportError = null;
    _lastMetrics = const <String, dynamic>{};
    _taskIndex = 0;
    _pauseRequested = false;
    _trackingState = TrackingState.noHand;
    _targetHandVisible = false;
    _phase = CameraTestPhase.running;
    _beginCurrentTask();
    notifyListeners();
  }

  /// Asks to pause. Takes effect when the current task ends — see
  /// [pausePending].
  void requestPause() {
    if (_phase != CameraTestPhase.running) return;
    _pauseRequested = true;
    notifyListeners();
  }

  /// Cancels a pause that has not taken effect yet.
  void cancelPauseRequest() {
    if (!_pauseRequested) return;
    _pauseRequested = false;
    notifyListeners();
  }

  /// Continues with the next task after a pause.
  void resume() {
    if (_phase != CameraTestPhase.paused) return;
    _pauseRequested = false;
    _phase = CameraTestPhase.running;
    _beginCurrentTask();
    notifyListeners();
  }

  /// Abandons the run without saving.
  ///
  /// Returns no result rather than `false`: the caller reads `false` as "no
  /// hands were detected" and shows a warning, which would be the wrong thing
  /// to say to someone who deliberately backed out.
  void cancel() {
    _stopTimer();
    locator<NavigationService>().back();
  }

  /// Opens a step: shows the instruction and waits, then records.
  ///
  /// In [CameraPacing.selfPaced] the wait ends when the patient taps; in
  /// [CameraPacing.timed] it ends on its own after the task's lead-in. Nothing
  /// is recorded during it either way.
  void _beginCurrentTask() {
    _phase = CameraTestPhase.preparing;
    _leadInWatch
      ..reset()
      ..start();

    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _onPrepareTick());
  }

  /// Starts recording the current step. The patient's "I'm ready".
  ///
  /// In timed pacing the countdown calls this; in self-paced the button does,
  /// and the lead-in then runs as a short "get ready" so the tap itself is not
  /// the first recorded frame.
  void startCurrentStep() {
    if (_phase != CameraTestPhase.preparing) return;
    if (_pacing == CameraPacing.selfPaced && !_readyTapped) {
      _readyTapped = true;
      _leadInWatch
        ..reset()
        ..start();
      notifyListeners();
      return;
    }
    _beginRecording();
  }

  void _beginRecording() {
    final task = currentTask;
    if (task == null) return;

    final now = DateTime.now();
    for (final segment in _currentSegments) {
      segment.startedAt = now;
    }
    _attempts[task.id] = (_attempts[task.id] ?? 0) + 1;

    // Reset per task, not per run. Every derivative, rhythm and duration figure
    // is measured from this task's own first frame, so nothing carries across a
    // boundary — the gap between one task ending and the next beginning is not
    // movement, and treating it as such would put a large artificial jump at
    // the start of every task after the first.
    _taskWatch
      ..reset()
      ..start();

    _phase = CameraTestPhase.running;
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _onTick());
    notifyListeners();
  }

  /// The segments being recorded for the step in progress — one per hand.
  List<CameraTaskSegment> get _currentSegments => _segmentsForIndex(_taskIndex);

  void _onPrepareTick() {
    final task = currentTask;
    if (task == null) return;

    // Self-paced waits indefinitely until the patient taps; once they have, the
    // short get-ready runs to completion like a timed lead-in.
    if (_pacing == CameraPacing.selfPaced && !_readyTapped) {
      notifyListeners();
      return;
    }

    // The countdown holds while the hand is out of view, rather than running
    // down and recording an empty picture. It resumes the moment the hand
    // appears, so the patient never has to be told what to do about it beyond
    // the one line the overlay shows.
    if (!cameraSeesHand) {
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

  void _onTick() {
    final task = currentTask;
    if (task == null) return;

    if (_taskWatch.elapsedMilliseconds >= task.duration.inMilliseconds) {
      _completeCurrentTask();
    } else {
      notifyListeners();
    }
  }

  /// Ends the current task and decides whether it can be accepted.
  ///
  /// The run no longer advances simply because the timer ran out. Each task is
  /// validated on its own, and one that was not recorded well enough to measure
  /// stops the sequence so the patient can record it again — the whole test
  /// used to complete on the strength of a hand having appeared once in
  /// forty-six seconds.
  void _completeCurrentTask() {
    _stopTimer();

    final segments = _currentSegments;
    final task = currentTask;
    if (segments.isEmpty || task == null) return;

    final now = DateTime.now();
    for (final segment in segments) {
      segment.endedAt = now;
    }

    // Each hand is validated on its own — a both-hands step where only one hand
    // stayed in view is not a usable recording of that step, so both must pass.
    bool anyRetry = false;
    for (final recorded
        in CameraRecording.fromSegments(segments, _mode).tasks) {
      final quality = _validator.validate(recorded);
      _qualities[recorded.taskId] = quality;
      if (quality.retryRecommended) anyRetry = true;
    }

    if (anyRetry && canRetryCurrentTask) {
      _phase = CameraTestPhase.taskReview;
      notifyListeners();
      return;
    }

    _advanceToNextTask();
  }

  /// Moves past the current task, whatever its verdict was.
  void _advanceToNextTask() {
    _taskIndex++;
    _targetHandVisible = false;
    _trackingState = TrackingState.noHand;

    if (_taskIndex >= _tasks.length) {
      _phase = CameraTestPhase.finishing;
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

    // Set explicitly rather than assumed: this is reached from the review
    // phase as well as from a clean task, and leaving the phase alone would
    // strand the patient on the retry prompt with the next task recording
    // behind it.
    _phase = CameraTestPhase.running;
    _beginCurrentTask();
    notifyListeners();
  }

  // --- Retry ---

  /// The verdict the patient is being asked about.
  ///
  /// A both-hands step has one verdict per hand; the failing one is what the
  /// retry prompt needs to show, so an invalid verdict always wins.
  TaskQuality? get currentQuality {
    final task = currentTask;
    if (task == null) return null;
    TaskQuality? best;
    for (final hand in task.hands) {
      final quality = _qualities[task.segmentId(hand)];
      if (quality == null) continue;
      if (best == null || (best.valid && !quality.valid)) best = quality;
    }
    return best;
  }

  /// Every verdict for the step being reviewed, one per hand.
  List<TaskQuality> get currentQualities {
    final task = currentTask;
    if (task == null) return const <TaskQuality>[];
    return <TaskQuality>[
      for (final hand in task.hands)
        if (_qualities[task.segmentId(hand)] != null)
          _qualities[task.segmentId(hand)]!,
    ];
  }

  /// Verdicts on every task recorded so far, keyed by task id.
  Map<String, TaskQuality> get qualities => Map.unmodifiable(_qualities);

  /// The recorded segments, in protocol order.
  @visibleForTesting
  List<CameraTaskSegment> get segments => List.unmodifiable(_segments);

  /// Ends the current task now, as the timer would have.
  ///
  /// Exposed so the validation and retry logic can be driven directly rather
  /// than by waiting out a ten-second wall-clock timer in a test.
  @visibleForTesting
  void completeCurrentTask() => _completeCurrentTask();

  /// Skips the instruction pause and starts recording immediately.
  ///
  /// The pause is deliberately open-ended for the patient, so a test cannot
  /// wait it out.
  @visibleForTesting
  void beginRecordingNow() {
    if (_phase != CameraTestPhase.preparing) return;
    _readyTapped = true;
    _beginRecording();
  }

  /// Attempts made at [taskId], counting the one just recorded.
  int attemptsFor(String taskId) => _attempts[taskId] ?? 0;

  int get currentAttempt {
    final task = currentTask;
    return task == null ? 0 : attemptsFor(task.id);
  }

  /// Whether another attempt at the current task is allowed.
  bool get canRetryCurrentTask => currentAttempt < maxAttemptsPerTask;

  /// Records the current task again, keeping everything already completed.
  ///
  /// The rejected attempt is set aside rather than deleted: it is the evidence
  /// of what went wrong, and it is uploaded under its own key so an offline
  /// reviewer can see both what failed and what replaced it.
  void retryCurrentTask() {
    if (_phase != CameraTestPhase.taskReview) return;
    final task = currentTask;
    final existing = _currentSegments;
    if (task == null || existing.isEmpty || !canRetryCurrentTask) return;

    _discarded.addAll(existing);

    // Spliced in place rather than removed and appended: `_segments` is in
    // protocol order, and that order is what the stored per-task array and the
    // rebuilt recording both rely on.
    final int at = _segments.indexWhere((s) => identical(s.task, task));
    _segments.removeWhere((s) => identical(s.task, task));
    _segments.insertAll(at, _freshSegmentsFor(task));
    for (final hand in task.hands) {
      _qualities.remove(task.segmentId(hand));
    }

    _targetHandVisible = false;
    _trackingState = TrackingState.noHand;
    _readyTapped = false;
    _beginCurrentTask();
    notifyListeners();
  }

  /// Accepts the current task as recorded and carries on.
  ///
  /// Always available, including before the attempt cap is reached: a patient
  /// who cannot produce a clean recording of a step must still be able to
  /// finish the test rather than be trapped on it.
  void keepAndContinue() {
    if (_phase != CameraTestPhase.taskReview) return;
    _advanceToNextTask();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _taskWatch.stop();
  }

  // --- Capture ---

  /// Receives every processed frame from the landmarker.
  ///
  /// *Every* frame is recorded, including those holding no hand at all. That is
  /// the point: the previous version was only called when the detector found
  /// something, and counted a miss only when it found the *other* hand. A task
  /// spent entirely out of frame therefore produced no frames and no misses,
  /// and came out looking like a task that had simply not started yet — with
  /// coverage, capture rate and confidence all computed over the handful of
  /// frames that happened to work.
  ///
  /// Only the hand named by the current task contributes landmarks. The camera
  /// usually sees both, and keeping the idle one would mix a resting hand into
  /// a movement task's metrics.
  ///
  /// Handedness comes from MediaPipe and is reported from the camera's point of
  /// view, so a front-facing (mirrored) preview can label the hands the
  /// opposite way round from what the patient sees. The labels are consistent
  /// within a run, so left/right comparisons hold either way, but a reviewer
  /// should not assume the sides are anatomically correct.
  void onFrame(FrameData frame) {
    // Frames are watched during the instruction pause too, though nothing is
    // recorded from them. That is what tells the countdown the detector is
    // actually live: the camera and the landmark model take a moment to start,
    // and a run that began its timer regardless spent the first task recording
    // an empty picture and then asked the patient to do it again.
    if (frame.hands.isNotEmpty) _lastHandSeen = DateTime.now();

    if (_phase != CameraTestPhase.running) return;

    final segments = _currentSegments;
    if (segments.isEmpty) return;

    // One classification per hand under examination — one segment in full mode,
    // two when both hands are recorded together. A classifier configured to
    // accept a lone hand is only asked to do so when the step examines a single
    // hand; with two segments in play, the labels are what tell them apart.
    final bool single = segments.length == 1;
    TrackingState? worst;

    for (final segment in segments) {
      final event = (single ? _classifier : _strictClassifier)
          .classify(frame: frame, targetHand: segment.hand);
      segment.add(event);
      if (worst == null || _isWorse(event.state, worst)) worst = event.state;
    }

    _updateLiveFeedback(worst!);
  }

  /// Ranks states so the overlay reports the least good hand.
  ///
  /// With both hands recording, saying "hand visible" because one of them is
  /// would hide the very thing the patient needs to fix.
  bool _isWorse(TrackingState candidate, TrackingState current) =>
      _severity(candidate) > _severity(current);

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

  /// Neutral, technical status for the overlay — never an interpretation.
  ///
  /// Only notifies when something actually changed, so the camera thread does
  /// not drive a rebuild per frame.
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

    final Map<String, dynamic> metrics = _analyzeFrames();
    final recording = CameraRecording.fromSegments(_segments, _mode);

    // Both scorers run on every recording and both verdicts are stored. The
    // enhanced one's normalization ranges are still provisional; storing both
    // is what will make calibrating them possible.
    ScoringComparison? scoring;
    try {
      scoring = _scoring.scoreAll(recording);
      metrics['scoring'] = scoring.toJson();
    } catch (e) {
      // Scoring must never cost the patient their recording.
      debugPrint('Could not compute scoring comparison: $e');
    }

    // The structured report is what the results screen and any reviewer read.
    // Built after scoring so it can carry the experimental score, and wrapped
    // for the same reason: a failure here must not lose the recording either.
    try {
      _report = const CameraReportBuilder().build(
        recording,
        qualities: _qualities,
        experimentalScore: scoring?.enhanced,
        retryCount: _discarded.length,
        performedAt: DateTime.now(),
      );
      metrics.addAll(_report!.toJson());
    } catch (e, stack) {
      // Still caught — an analysis crash must not cost the patient their
      // recording — but no longer silent. This used to print to a log nobody
      // reads on a phone and leave the screen claiming nothing was measured,
      // which made a code fault indistinguishable from a bad recording.
      debugPrint('Could not build camera report: $e\n$stack');
      _reportError = e.toString();
      metrics['report_error'] = _reportError;
    }

    // Kept whatever happened, so the diagnostic section can show the run's
    // real numbers even when the analysis above failed.
    _lastMetrics = metrics;

    // A run that measured nothing is not saved.
    //
    // The scorers return a likelihood of 0 for an empty recording, and 0 is
    // the *best* possible value on this scale — so storing it would put a
    // reassuring result in the patient's history off the back of a recording
    // that contains nothing at all. The results screen says plainly that
    // nothing could be measured and offers the test again.
    if (_report != null && !_report!.hasAnyMeasurement) {
      if (_disposed) return;
      setBusy(false);
      _phase = CameraTestPhase.results;
      notifyListeners();
      return;
    }

    final double score =
        scoring?.likelihood ?? metrics['parkinson_probability'] as double;

    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.cameraDetection,
      performedAt: DateTime.now(),
      score: score,
      data: metrics,
    );

    // Best-effort save: a failed upload must not strand the patient on the
    // camera screen with no way back.
    try {
      await _tests.addResult(
        result: result,
        sensorData: _collectLandmarks(),
        // Keyed on samples, not frames: a task that produced no usable frame is
        // exactly the one whose record a reviewer needs, and uploading only the
        // successful tasks would hide every failure.
        //
        // Rejected attempts travel under their own keys, so the accepted
        // recording of a task and the attempts it replaced are both
        // recoverable and never confused with each other.
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

    // The run no longer pops straight back to the tests list. The patient sees
    // what was measured and how well it was recorded, and leaves the screen
    // themselves — a result that vanishes the instant it is produced is one
    // they have no way to read.
    _phase = CameraTestPhase.results;
    notifyListeners();
  }

  /// Leaves the results screen, reporting that the test ran.
  void finishFromResults() {
    locator<NavigationService>().back(result: true);
  }

  /// Starts the whole protocol again from the beginning.
  void repeatTest() {
    _report = null;
    _reportError = null;
    _lastMetrics = const <String, dynamic>{};
    _resultSaved = false;
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
    super.dispose();
  }

  /// Merges the trajectories of every segment for [hand] that satisfies
  /// [include], preserving the per-landmark shape [HandMetrics] expects.
  List<List<LandmarkPoint>> _mergedTrajectories(
    String hand,
    bool Function(CameraTaskSegment) include,
  ) {
    final merged = List.generate(21, (_) => <LandmarkPoint>[]);
    for (final segment in _segments) {
      if (segment.hand != hand || !include(segment)) continue;
      final trajectories = segment.toTrajectories();
      for (int i = 0; i < 21; i++) {
        merged[i].addAll(trajectories[i]);
      }
    }
    return merged;
  }

  /// Runs [HandMetrics] over one set of trajectories.
  Map<String, double> _metricsFor(List<List<LandmarkPoint>> trajectories) {
    return <String, double>{
      'speed_variance': _metrics.speedVarianceAll(trajectories),
      'accel_variance': _metrics.accelerationVarianceAll(trajectories),
      'jerk_variance': _metrics.jerkVarianceAll(trajectories),
      'finger_spread': _metrics.fingerSpread(trajectories),
      'tremor': _metrics.tremorAll(trajectories),
    };
  }

  /// Produces the result `data` map.
  ///
  /// The scoring formula and its [ParkinsonConfig] weights are unchanged from
  /// the single-capture version, and every key it used to write is still
  /// written, so existing readers and stored documents stay compatible. What is
  /// new is [protocolVersion], the per-task breakdown, and the fact that the
  /// aggregate is computed over the *movement* tasks only — rest frames are
  /// recorded and reported separately but excluded from the score, since a
  /// deliberately motionless hand would otherwise drag every variance metric
  /// toward zero.
  Map<String, dynamic> _analyzeFrames() {
    final leftMovement = _mergedTrajectories('Left', (s) => s.task.isScored);
    final rightMovement = _mergedTrajectories('Right', (s) => s.task.isScored);
    final leftRest = _mergedTrajectories('Left', (s) => !s.task.isScored);
    final rightRest = _mergedTrajectories('Right', (s) => !s.task.isScored);

    final left = _metricsFor(leftMovement);
    final right = _metricsFor(rightMovement);

    final double speedVarL = left['speed_variance']!;
    final double speedVarR = right['speed_variance']!;
    final double asymmetry = (speedVarL - speedVarR).abs();

    double avg(double a, double b) => (a + b) / 2;
    final double probability = ParkinsonConfig.wSpeed *
            avg(speedVarL, speedVarR) +
        ParkinsonConfig.wTremor * avg(left['tremor']!, right['tremor']!) +
        ParkinsonConfig.wAccel *
            avg(left['accel_variance']!, right['accel_variance']!) +
        ParkinsonConfig.wJerk *
            avg(left['jerk_variance']!, right['jerk_variance']!) +
        ParkinsonConfig.wSpread *
            avg(left['finger_spread']!, right['finger_spread']!) +
        ParkinsonConfig.wAsym * asymmetry;

    final int totalFrames =
        _segments.fold<int>(0, (sum, s) => sum + s.frames.length);
    final List<double> rates =
        _segments.map((s) => s.fps).where((f) => f > 0).toList();

    return <String, dynamic>{
      // --- Keys carried over unchanged from the single-capture version ---
      'frames': totalFrames,
      'hands_detected_frames': totalFrames,
      'speed_variance_left': speedVarL,
      'speed_variance_right': speedVarR,
      'accel_variance_left': left['accel_variance'],
      'accel_variance_right': right['accel_variance'],
      'jerk_variance_left': left['jerk_variance'],
      'jerk_variance_right': right['jerk_variance'],
      'finger_spread_left': left['finger_spread'],
      'finger_spread_right': right['finger_spread'],
      'tremor_left': left['tremor'],
      'tremor_right': right['tremor'],
      'asymmetry': asymmetry,
      'parkinson_probability': probability.clamp(0.0, 1.0),

      // --- Added by the guided protocol ---
      'protocol_version': protocolVersion,
      'mode': _mode.name,
      'mds_updrs_items': const <String>['3.4', '3.5', '3.6'],

      // --- Added with quality validation and retries ---
      'quality_rules_version': const QualityRules().version,
      'task_quality': <String, dynamic>{
        for (final entry in _qualities.entries) entry.key: entry.value.toJson(),
      },
      'attempts': Map<String, int>.of(_attempts),
      'retry_count': _discarded.length,
      'invalid_tasks': _qualities.values
          .where((q) => !q.valid)
          .map((q) => q.taskId)
          .toList(growable: false),
      'mean_fps': rates.isEmpty
          ? 0.0
          : rates.reduce((a, b) => a + b) / rates.length,
      'rest_tremor_left': _metrics.tremorAll(leftRest),
      'rest_tremor_right': _metrics.tremorAll(rightRest),
      'tasks': _segments
          .map((segment) => <String, dynamic>{
                ...segment.toSummaryJson(),
                ..._metricsFor(segment.toTrajectories()),
              })
          .toList(growable: false),
    };
  }

  /// The legacy merged landmark blob.
  ///
  /// Superseded by the per-task segments, but still uploaded so that anything
  /// already consuming `camera/<uid>/<testId>/raw.json.gz` keeps working.
  Map<String, dynamic> _collectLandmarks() {
    final left = <List<double>>[];
    final right = <List<double>>[];
    for (final segment in _segments) {
      final target = segment.hand == 'Left' ? left : right;
      for (final frame in segment.frames) {
        for (final lm in frame.landmarks) {
          target.add(<double>[lm.x, lm.y, lm.z]);
        }
      }
    }
    return <String, dynamic>{'leftHand': left, 'rightHand': right};
  }
}
