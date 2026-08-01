import 'dart:math' as math;

import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/models/camera_task_segment.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/services/scoring/camera_recording.dart';

/// Builders for synthetic camera recordings with known properties.
///
/// The scorers are pure functions of a [CameraRecording], so a whole session
/// can be fabricated here with the exact rate, decrement and tremor wanted, and
/// the resulting score checked against what was put in.
///
/// Landmarks are laid out to match how [MovementCycleAnalyzer] reads them:
/// wrist at index 0, middle MCP at 9 (together fixing palm size), thumb tip 4
/// and index tip 8 (finger tapping), fingertips 8/12/16/20 relative to the
/// wrist (aperture), and index/pinky MCPs 5 and 17 (rotation).
abstract final class Synthetic {
  /// Palm size in frame-normalized units. Every spatial measure the analyzer
  /// produces is divided by this, so its exact value should not matter — which
  /// [scale] exists to verify.
  static const double palm = 0.10;

  /// Builds one task's frames.
  ///
  /// [amplitude] is the movement size in palm-widths at the start;
  /// [decrement] is the fraction of it lost linearly by the end;
  /// [tremorAmplitude] (also in palm-widths) and [tremorHz] add an involuntary
  /// oscillation on top — 0.15 is a pronounced tremor, 0.01 a subtle one;
  /// [pauseAt]/[pauseDuration] freeze the hand mid-task;
  /// [startDelay] holds it still before movement begins;
  /// [scale] multiplies every coordinate, simulating a hand nearer the lens.
  static RecordedTask task({
    required CameraTaskType type,
    required String hand,
    double seconds = 10,
    double fps = 30,
    double rateHz = 4,
    double amplitude = 1.0,
    double decrement = 0,
    double tremorAmplitude = 0,
    double tremorHz = 5,
    double? pauseAt,
    double pauseDuration = 0,
    double startDelay = 0,
    double scale = 1.0,
    double jitterFraction = 0,
    int missedFrames = 0,
    int startTimestampMs = 0,
    int? seed,
  }) {
    final int count = (seconds * fps).round();
    final random = math.Random(seed ?? 11);
    final frames = <TaggedFrame>[];

    // Phase is integrated rather than computed from t, so a pause genuinely
    // freezes the movement instead of letting it jump ahead while stopped.
    double phase = 0;
    double previousT = 0;

    for (int i = 0; i < count; i++) {
      final double t = i / fps;
      final double dt = t - previousT;
      previousT = t;

      final bool inPause = pauseAt != null &&
          t >= pauseAt &&
          t < pauseAt + pauseDuration;
      final bool waiting = t < startDelay;

      // Rhythm jitter makes the intervals irregular without changing the mean.
      final double instantRate = jitterFraction == 0
          ? rateHz
          : rateHz * (1 + (random.nextDouble() - 0.5) * 2 * jitterFraction);

      if (!inPause && !waiting) phase += 2 * math.pi * instantRate * dt;

      final double progress = seconds == 0 ? 0 : t / seconds;
      final double currentAmplitude =
          amplitude * (1 - decrement * progress);

      double value = (inPause || waiting)
          ? 0
          : currentAmplitude * 0.5 * (1 - math.cos(phase));
      value += tremorAmplitude * math.sin(2 * math.pi * tremorHz * t);

      frames.add(TaggedFrame(
        taskId: '${hand.toLowerCase()}_${type.name}',
        hand: hand,
        timestamp: startTimestampMs + (t * 1000).round(),
        landmarks: _landmarks(type, value, scale),
      ));
    }

    return RecordedTask(
      taskId: '${hand.toLowerCase()}_${type.name}',
      type: type,
      hand: hand,
      plannedDuration: Duration(milliseconds: (seconds * 1000).round()),
      frames: frames,
      missedFrames: missedFrames,
    );
  }

  /// Places 21 landmarks so that the signal for [type] equals [value] palm
  /// widths. Landmarks not used by that task's signal are held fixed.
  static List<LandmarkPoint> _landmarks(
      CameraTaskType type, double value, double scale) {
    final points = List<LandmarkPoint>.generate(
      21,
      (_) => const LandmarkPoint(x: 0.5, y: 0.5, z: 0),
    );

    LandmarkPoint at(double x, double y) =>
        LandmarkPoint(x: x * scale, y: y * scale, z: 0);

    // Wrist and middle MCP define palm size.
    points[0] = at(0.5, 0.5);
    points[9] = at(0.5, 0.5 - palm);

    switch (type) {
      case CameraTaskType.fingerTap:
        // Thumb-to-index distance carries the signal.
        points[4] = at(0.5, 0.5 - palm);
        points[8] = at(0.5 + value * palm, 0.5 - palm);
      case CameraTaskType.openClose:
        // All four fingertips move together, wrist-to-tip = value palm widths.
        for (final tip in <int>[8, 12, 16, 20]) {
          points[tip] = at(0.5, 0.5 - value * palm);
        }
      case CameraTaskType.pronationSupination:
        // Signed horizontal offset between the knuckles.
        points[5] = at(0.5 + value * palm, 0.5 - palm);
        points[17] = at(0.5, 0.5 - palm);
      case CameraTaskType.rest:
        // Whole-hand translation, so palm size is unchanged and the tremor
        // shows up as position residual on every landmark — which is what
        // TremorAnalysisService measures.
        for (int i = 0; i < points.length; i++) {
          points[i] = LandmarkPoint(
            x: points[i].x + value * palm,
            y: points[i].y,
            z: 0,
          );
        }
    }
    return points;
  }

  /// A full six-movement-task recording, both hands, with the same character
  /// on each unless [leftOverrides] says otherwise.
  static CameraRecording recording({
    double fps = 30,
    double seconds = 10,
    double rateHz = 4,
    double amplitude = 1.0,
    double decrement = 0,
    double tremorAmplitude = 0,
    double tremorHz = 5,
    double jitterFraction = 0,
    double startDelay = 0,
    double? pauseAt,
    double pauseDuration = 0,
    int missedFrames = 0,
    double leftRateHz = -1,
    double leftAmplitude = -1,
    bool includeRest = true,
  }) {
    final tasks = <RecordedTask>[];

    for (final hand in CameraTaskProtocol.hands) {
      final bool isLeft = hand == 'Left';
      final double handRate =
          isLeft && leftRateHz > 0 ? leftRateHz : rateHz;
      final double handAmplitude =
          isLeft && leftAmplitude > 0 ? leftAmplitude : amplitude;

      if (includeRest) {
        tasks.add(task(
          type: CameraTaskType.rest,
          hand: hand,
          seconds: 3,
          fps: fps,
          rateHz: 0,
          amplitude: 0,
          tremorAmplitude: tremorAmplitude,
          tremorHz: tremorHz,
        ));
      }

      for (final type in <CameraTaskType>[
        CameraTaskType.openClose,
        CameraTaskType.fingerTap,
        CameraTaskType.pronationSupination,
      ]) {
        tasks.add(task(
          type: type,
          hand: hand,
          seconds: seconds,
          fps: fps,
          rateHz: handRate,
          amplitude: handAmplitude,
          decrement: decrement,
          tremorAmplitude: tremorAmplitude,
          tremorHz: tremorHz,
          jitterFraction: jitterFraction,
          startDelay: startDelay,
          pauseAt: pauseAt,
          pauseDuration: pauseDuration,
          missedFrames: missedFrames,
        ));
      }
    }

    return CameraRecording(tasks: tasks, mode: CameraTestMode.full);
  }

  /// Fast, regular, full-amplitude, no tremor — what a healthy adult produces.
  static CameraRecording healthy() => recording(
        rateHz: 5.0,
        amplitude: 1.2,
        decrement: 0,
        jitterFraction: 0.03,
        tremorAmplitude: 0,
      );

  /// Slow, irregular, decrementing, tremulous, hesitant, asymmetric.
  static CameraRecording parkinsonian() => recording(
        rateHz: 2.0,
        amplitude: 0.5,
        decrement: 0.45,
        jitterFraction: 0.35,
        tremorAmplitude: 0.15,
        tremorHz: 5,
        startDelay: 1.2,
        pauseAt: 5.0,
        pauseDuration: 1.5,
        leftRateHz: 3.6,
        leftAmplitude: 1.0,
      );
}
