import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../models/camera_task_segment.dart';
import '../../../models/landmark_point.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../../../services/authentication_service.dart';
import '../../../services/hand_metrics.dart';
import '../../../services/parkinson_config.dart';
import '../../../services/test_service.dart';
import '../patience/hand_landmarker_screen.dart';
import 'camera_task_protocol.dart';

/// Where the guided run currently is.
enum CameraTestPhase {
  /// Instructions shown, nothing being recorded yet.
  setup,

  /// A task is running and frames are being captured.
  running,

  /// Stopped cleanly at a task boundary, waiting for the patient to resume.
  paused,

  /// All tasks done; analysing and saving.
  finishing,
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

  /// Bumped whenever the stored shape changes, so an analysis job can tell a
  /// guided run from the old single-capture documents. Version 1 is implicit
  /// in documents written before the protocol existed.
  static const int protocolVersion = 2;

  /// The UI ticks about ten times a second so the countdown and progress bar
  /// move smoothly; task timing itself comes from [_taskWatch], not this.
  static const Duration _tick = Duration(milliseconds: 100);

  CameraTestPhase _phase = CameraTestPhase.setup;
  CameraTestMode _mode = CameraTestMode.full;

  List<CameraTask> _tasks = CameraTaskProtocol.build(CameraTestMode.full);
  final List<CameraTaskSegment> _segments = <CameraTaskSegment>[];
  int _taskIndex = 0;

  Timer? _timer;
  final Stopwatch _taskWatch = Stopwatch();

  bool _pauseRequested = false;
  bool _handsDetected = false;
  bool _disposed = false;

  // --- View state ---

  CameraTestPhase get phase => _phase;
  CameraTestMode get mode => _mode;
  bool get isRunning => _phase == CameraTestPhase.running;
  bool get isPaused => _phase == CameraTestPhase.paused;
  bool get isSetup => _phase == CameraTestPhase.setup;

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

  // --- Control ---

  /// Chooses the protocol length. Only meaningful before the run starts.
  void setMode(CameraTestMode mode) {
    if (_phase != CameraTestPhase.setup || mode == _mode) return;
    _mode = mode;
    _tasks = CameraTaskProtocol.build(mode);
    notifyListeners();
  }

  Duration get totalDuration => CameraTaskProtocol.totalDuration(_mode);

  /// Begins the guided sequence from the first task.
  void start() {
    _segments
      ..clear()
      ..addAll(_tasks.map((task) => CameraTaskSegment(task: task)));
    _taskIndex = 0;
    _handsDetected = false;
    _pauseRequested = false;
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

  void _beginCurrentTask() {
    final segment = _currentSegment;
    segment?.startedAt = DateTime.now();

    _taskWatch
      ..reset()
      ..start();

    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  CameraTaskSegment? get _currentSegment =>
      _taskIndex < _segments.length ? _segments[_taskIndex] : null;

  void _onTick() {
    final task = currentTask;
    if (task == null) return;

    if (_taskWatch.elapsedMilliseconds >= task.duration.inMilliseconds) {
      _completeCurrentTask();
    } else {
      notifyListeners();
    }
  }

  void _completeCurrentTask() {
    _stopTimer();
    _currentSegment?.endedAt = DateTime.now();
    _taskIndex++;
    _targetHandVisible = false;

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

    _beginCurrentTask();
    notifyListeners();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _taskWatch.stop();
  }

  // --- Capture ---

  /// Receives every detected frame from the landmarker.
  ///
  /// Only the hand named by the current task is kept. The camera usually sees
  /// both hands, and keeping the idle one would mix a resting hand into a
  /// movement task's metrics.
  ///
  /// Handedness comes from MediaPipe and is reported from the camera's point of
  /// view, so a front-facing (mirrored) preview can label the hands the
  /// opposite way round from what the patient sees. The labels are consistent
  /// within a run, so left/right comparisons hold either way, but a reviewer
  /// should not assume the sides are anatomically correct.
  void onFrame(FrameData frame) {
    if (_phase != CameraTestPhase.running) return;

    final task = currentTask;
    final segment = _currentSegment;
    if (task == null || segment == null) return;

    if (frame.hands.isNotEmpty) _handsDetected = true;

    LandmarkData? match;
    for (final hand in frame.hands) {
      if (hand.handedness == task.hand) {
        match = hand;
        break;
      }
    }

    if (match == null) {
      segment.missedFrames++;
      if (_targetHandVisible) {
        _targetHandVisible = false;
        notifyListeners();
      }
      return;
    }

    segment.frames.add(TaggedFrame(
      taskId: task.id,
      hand: task.hand,
      timestamp: frame.timestamp,
      landmarks: match.landmarks,
    ));

    if (!_targetHandVisible) {
      _targetHandVisible = true;
      notifyListeners();
    }
  }

  // --- Completion ---

  Future<void> _finish() async {
    setBusy(true);

    if (!_handsDetected) {
      setBusy(false);
      locator<NavigationService>().back(result: false);
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setBusy(false);
      locator<NavigationService>().back(result: false);
      return;
    }

    final Map<String, dynamic> metrics = _analyzeFrames();
    final double score = metrics['parkinson_probability'] as double;

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
        taskSegments: {
          for (final segment in _segments)
            if (segment.frames.isNotEmpty) segment.taskId: segment.toJson(),
        },
      );
    } catch (e) {
      debugPrint('Could not save camera test result: $e');
    }

    if (_disposed) return;
    setBusy(false);
    locator<NavigationService>().back(result: true);
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
