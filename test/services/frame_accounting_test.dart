import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/models/camera_task_segment.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/models/tracking_event.dart';
import 'package:parkinsondetetion/services/scoring/camera_recording.dart';

const CameraTask _task = CameraTask(
  id: 'right_fingerTap',
  type: CameraTaskType.fingerTap,
  hands: <String>['Right'],
  duration: Duration(seconds: 10),
);

List<LandmarkPoint> _hand({double palm = 0.1}) {
  final points = List<LandmarkPoint>.generate(
    21,
    (_) => const LandmarkPoint(x: 0.5, y: 0.5, z: 0),
  );
  points[0] = const LandmarkPoint(x: 0.5, y: 0.5, z: 0);
  points[9] = LandmarkPoint(x: 0.5, y: 0.5 - palm, z: 0);
  return points;
}

TrackingEvent _event(int t, TrackingState state, {double palm = 0.1}) =>
    TrackingEvent(
      timestamp: t,
      state: state,
      landmarks: state.contributesLandmarks ? _hand(palm: palm) : null,
    );

/// Fills a segment at 30 fps with the given run of states.
CameraTaskSegment _segmentOf(List<TrackingState> states) {
  final segment = CameraTaskSegment(task: _task, hand: 'Right');
  for (int i = 0; i < states.length; i++) {
    segment.add(_event(i * 33, states[i]));
  }
  return segment;
}

void main() {
  group('per-frame accounting', () {
    test('a task where the hand was never visible is fully accounted for', () {
      // The regression this whole change exists for. Previously the ViewModel
      // was only called when the detector found *something*, and counted a miss
      // only when it found the other hand — so a task spent entirely out of
      // frame recorded no frames and no misses, and coverage came out as 0/0.
      final segment = _segmentOf(List.filled(300, TrackingState.noHand));

      expect(segment.samples, hasLength(300));
      expect(segment.frames, isEmpty);
      expect(segment.missedFrames, 300);

      final task = CameraRecording.fromSegments(
        [segment],
        CameraTestMode.full,
      ).tasks.single;

      expect(task.processedFrameCount, 300);
      expect(task.coverage, 0);
    });

    test('coverage is measured against every processed frame', () {
      final segment = _segmentOf([
        ...List.filled(60, TrackingState.tracked),
        ...List.filled(140, TrackingState.noHand),
        ...List.filled(100, TrackingState.wrongHand),
      ]);

      expect(segment.frames, hasLength(60));
      expect(segment.missedFrames, 240);

      final task = CameraRecording.fromSegments(
        [segment],
        CameraTestMode.full,
      ).tasks.single;

      expect(task.coverage, closeTo(0.2, 1e-9));
    });

    test('imperfect frames count toward coverage but not tracked ratio', () {
      final segment = _segmentOf([
        ...List.filled(50, TrackingState.tracked),
        ...List.filled(25, TrackingState.partiallyOutOfFrame),
        ...List.filled(25, TrackingState.lowConfidence),
      ]);

      final task = CameraRecording.fromSegments(
        [segment],
        CameraTestMode.full,
      ).tasks.single;

      expect(task.coverage, 1.0, reason: 'all three carry landmarks');
      expect(task.trackedRatio, closeTo(0.5, 1e-9));
    });

    test('processed rate and usable rate answer different questions', () {
      // The device kept up at 30 fps throughout; only half the frames held the
      // hand. Device throughput must not be reported as signal quality.
      final states = <TrackingState>[];
      for (int i = 0; i < 200; i++) {
        states.add(i.isEven ? TrackingState.tracked : TrackingState.noHand);
      }
      final segment = _segmentOf(states);

      expect(segment.processedFps, closeTo(30.3, 0.5));
      expect(segment.fps, closeTo(15.2, 0.5));
    });

    test('state counts survive into the uploaded segment', () {
      final segment = _segmentOf([
        ...List.filled(3, TrackingState.tracked),
        ...List.filled(2, TrackingState.noHand),
        TrackingState.wrongHand,
      ]);

      final json = segment.toJson();

      expect(json['processedFrames'], 6);
      expect(json['frameCount'], 3);
      expect(json['missedFrames'], 3);
      expect(json['frameStates'], <String, int>{
        'tracked': 3,
        'noHand': 2,
        'wrongHand': 1,
      });
      // The tracking log is what lets an offline job reconstruct *when*
      // tracking was lost; the frame list alone cannot, since lost frames
      // leave no frame behind.
      expect(json['tracking'], hasLength(6));
      expect((json['frames'] as List).first, containsPair('state', 'tracked'));
    });

    test('a frame keeps the state it was captured in', () {
      final segment = CameraTaskSegment(task: _task, hand: 'Right');
      segment.add(_event(0, TrackingState.partiallyOutOfFrame));

      expect(segment.frames.single.state, TrackingState.partiallyOutOfFrame);
    });
  });

  group('tracking continuity', () {
    test('a long dropout is distinguished from evenly scattered losses', () {
      // Both recordings have identical coverage. Only the second destroys the
      // rhythm measurements, because the analyzer cannot tell the resulting
      // gap from a genuine pause in the movement.
      final scattered = <TrackingState>[];
      for (int i = 0; i < 200; i++) {
        scattered.add(i.isEven ? TrackingState.tracked : TrackingState.noHand);
      }
      final blocked = <TrackingState>[
        ...List.filled(100, TrackingState.tracked),
        ...List.filled(100, TrackingState.noHand),
        ...List.filled(0, TrackingState.tracked),
      ];

      final a = CameraRecording.fromSegments(
        [_segmentOf(scattered)],
        CameraTestMode.full,
      ).tasks.single;
      final b = CameraRecording.fromSegments(
        [_segmentOf(blocked)],
        CameraTestMode.full,
      ).tasks.single;

      expect(a.coverage, closeTo(0.5, 1e-9));
      expect(b.coverage, closeTo(0.5, 1e-9));

      expect(a.longestGapSeconds, lessThan(0.1));
      expect(b.longestGapSeconds, lessThan(0.1),
          reason: 'the dropout is at the end, so no gap sits between frames');

      // A dropout in the middle is what the metric is for.
      final middle = <TrackingState>[
        ...List.filled(50, TrackingState.tracked),
        ...List.filled(100, TrackingState.noHand),
        ...List.filled(50, TrackingState.tracked),
      ];
      final c = CameraRecording.fromSegments(
        [_segmentOf(middle)],
        CameraTestMode.full,
      ).tasks.single;

      expect(c.coverage, closeTo(0.5, 1e-9));
      expect(c.longestGapSeconds, greaterThan(3.0));
    });

    test('a task with no usable frames reports no usable duration', () {
      final task = CameraRecording.fromSegments(
        [_segmentOf(List.filled(50, TrackingState.noHand))],
        CameraTestMode.full,
      ).tasks.single;

      expect(task.usableDurationSeconds, 0);
    });
  });

  group('hand size stability', () {
    test('a steady hand distance scores near 1', () {
      final segment = CameraTaskSegment(task: _task, hand: 'Right');
      for (int i = 0; i < 100; i++) {
        segment.add(_event(i * 33, TrackingState.tracked, palm: 0.1));
      }

      final task = CameraRecording.fromSegments(
        [segment],
        CameraTestMode.full,
      ).tasks.single;

      expect(task.handSizeStability, closeTo(1.0, 1e-6));
    });

    test('drifting toward the camera lowers stability', () {
      // This is the confound the metric exists to expose: every spatial feature
      // is divided by palm size, so a patient moving closer adds a trend to
      // amplitude that looks exactly like decrement.
      final segment = CameraTaskSegment(task: _task, hand: 'Right');
      for (int i = 0; i < 100; i++) {
        segment.add(
          _event(i * 33, TrackingState.tracked, palm: 0.08 + i * 0.0006),
        );
      }

      final task = CameraRecording.fromSegments(
        [segment],
        CameraTestMode.full,
      ).tasks.single;

      expect(task.handSizeStability, lessThan(0.9));
    });
  });

  group('backward compatibility', () {
    test('a recording without per-frame samples still reports coverage', () {
      // Synthetic fixtures and any pre-existing consumer construct tasks with
      // a declared miss count and no samples.
      const task = RecordedTask(
        taskId: 'right_fingerTap',
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        plannedDuration: Duration(seconds: 10),
        frames: <TaggedFrame>[],
        missedFrames: 40,
      );

      expect(task.processedFrameCount, 40);
      expect(task.missedFrames, 40);
      expect(task.coverage, 0);
      expect(task.trackedRatio, 0);
    });
  });
}
