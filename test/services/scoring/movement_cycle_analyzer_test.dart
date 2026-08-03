import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/services/scoring/movement_cycle_analyzer.dart';

import 'synthetic_recording.dart';

void main() {
  const analyzer = MovementCycleAnalyzer();

  group('MovementCycleAnalyzer - cycle counting -', () {
    test('recovers the rate it was given', () {
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        seconds: 10,
        rateHz: 4,
      ));

      expect(metrics.cycleCount, greaterThan(30));
      expect(metrics.rateHz, closeTo(4.0, 0.5));
    });

    test('counts a full pronation/supination turn as one cycle', () {
      // The rotation signal is signed, so a turn out and back is one
      // oscillation rather than two.
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.pronationSupination,
        hand: 'Right',
        seconds: 10,
        rateHz: 3,
      ));

      expect(metrics.rateHz, closeTo(3.0, 0.5));
    });

    test('reads the open/close aperture signal', () {
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.openClose,
        hand: 'Left',
        seconds: 10,
        rateHz: 2,
      ));

      expect(metrics.rateHz, closeTo(2.0, 0.4));
    });

    test('rest tasks have no cycles', () {
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.rest,
        hand: 'Right',
        seconds: 3,
      ));

      expect(metrics.cycleCount, 0);
      expect(metrics.rateHz, isNull);
    });
  });

  group('MovementCycleAnalyzer - scale invariance -', () {
    test('a hand nearer the camera yields the same metrics', () {
      // Doubling every coordinate doubles both the movement and the palm, so
      // dividing by palm size must cancel it out. Without this the amplitude
      // decrement would partly measure the patient drifting toward the lens.
      final near = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
        decrement: 0.3,
        scale: 2.0,
      ));
      final far = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
        decrement: 0.3,
        scale: 1.0,
      ));

      expect(near.cycleCount, far.cycleCount);
      expect(near.rateHz, closeTo(far.rateHz!, 1e-9));
      expect(near.meanSpeed, closeTo(far.meanSpeed!, 1e-9));
      expect(near.amplitudeDecrement,
          closeTo(far.amplitudeDecrement!, 1e-9));
    });
  });

  group('MovementCycleAnalyzer - decrement -', () {
    test('reports no decrement for constant amplitude', () {
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
        decrement: 0,
      ));

      expect(metrics.amplitudeDecrement, isNotNull);
      expect(metrics.amplitudeDecrement, lessThan(0.05));
    });

    test('recovers a known amplitude decrement', () {
      // Amplitude falls linearly to 60% by the end. Comparing the first third
      // (centred ~1/6 through) with the last (centred ~5/6) should show
      // roughly 0.4 * (5/6 - 1/6) = 0.27 of the original lost.
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        seconds: 10,
        rateHz: 4,
        decrement: 0.4,
      ));

      expect(metrics.amplitudeDecrement, closeTo(0.27, 0.07));
    });

    test('a movement that grows is not a negative decrement', () {
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
        decrement: -0.3,
      ));

      expect(metrics.amplitudeDecrement, 0);
    });

    test('needs enough cycles before estimating decrement', () {
      // Two cycles cannot support a first-third to last-third comparison.
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        seconds: 4,
        rateHz: 0.5,
      ));

      expect(metrics.cycleCount, lessThan(6));
      expect(metrics.amplitudeDecrement, isNull);
    });
  });

  group('MovementCycleAnalyzer - rhythm, pauses and initiation -', () {
    test('regular tapping is more rhythmic than jittery tapping', () {
      final regular = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
        jitterFraction: 0.02,
      ));
      final irregular = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
        jitterFraction: 0.4,
      ));

      expect(regular.rhythmVariability, isNotNull);
      expect(irregular.rhythmVariability,
          greaterThan(regular.rhythmVariability!));
    });

    test('detects a mid-task halt', () {
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        seconds: 12,
        rateHz: 4,
        pauseAt: 5,
        pauseDuration: 1.5,
      ));

      expect(metrics.pauseCount, greaterThanOrEqualTo(1));
      expect(metrics.pauseSeconds, greaterThan(1.0));
    });

    test('uninterrupted tapping reports no halts', () {
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
        jitterFraction: 0.05,
      ));

      expect(metrics.pauseCount, 0);
      expect(metrics.pauseSeconds, 0);
    });

    test('measures a delayed start', () {
      final prompt = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
      ));
      final delayed = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
        startDelay: 1.5,
      ));

      expect(prompt.initiationDelaySeconds, lessThan(0.5));
      expect(delayed.initiationDelaySeconds, greaterThan(1.2));
    });
  });

  group('MovementCycleAnalyzer - speed and smoothness -', () {
    test('faster tapping measures as faster', () {
      final slow = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 2,
      ));
      final fast = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 5,
      ));

      expect(fast.meanSpeed, greaterThan(slow.meanSpeed!));
      expect(fast.maxSpeed, greaterThan(slow.maxSpeed!));
    });

    test('smooth oscillation scores smoother than an interrupted one', () {
      final smooth = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
      ));
      final broken = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
        jitterFraction: 0.5,
        pauseAt: 4,
        pauseDuration: 1.0,
      ));

      expect(smooth.smoothness, isNotNull);
      expect(broken.smoothness, isNotNull);
      expect(smooth.smoothness, greaterThan(broken.smoothness!));
    });
  });

  group('MovementCycleAnalyzer - degenerate input -', () {
    test('a motionless hand reports no cycles but still reports speed', () {
      final metrics = analyzer.analyze(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 0,
        amplitude: 0,
      ));

      expect(metrics.cycleCount, 0);
      expect(metrics.rateHz, isNull);
      expect(metrics.meanSpeed, isNotNull);
    });

    test('too few frames returns empty rather than throwing', () {
      final task = Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        seconds: 0.05,
        fps: 30,
      );
      final metrics = analyzer.analyze(task);

      expect(metrics.cycleCount, 0);
      expect(metrics.durationSeconds, 0);
    });
  });
}
