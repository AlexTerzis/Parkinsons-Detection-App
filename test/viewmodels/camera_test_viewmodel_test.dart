import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/app/app.locator.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/models/frame_data.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/ui/views/camera_test/camera_test_viewmodel.dart';

import '../helpers/test_helpers.dart';

/// A hand centred at [x], with a palm length of [palm] (wrist to middle
/// knuckle). [offset] moves the index tip away from the thumb, so alternating
/// it produces a tapping cycle.
List<LandmarkPoint> _hand({double x = 0.5, double offset = 0, double palm = 0.1}) {
  final points = List<LandmarkPoint>.generate(
    21,
    (_) => LandmarkPoint(x: x, y: 0.5, z: 0),
  );
  points[0] = LandmarkPoint(x: x, y: 0.5, z: 0);
  points[9] = LandmarkPoint(x: x, y: 0.5 - palm, z: 0);
  points[4] = LandmarkPoint(x: x, y: 0.5 - palm, z: 0);
  points[8] = LandmarkPoint(x: x + offset, y: 0.5 - palm, z: 0);
  return points;
}

LandmarkData _data(List<LandmarkPoint> points, {String label = 'Right'}) =>
    LandmarkData(handedness: label, landmarks: points, handednessConfidence: 0.9);

/// Feeds [count] frames at 30 fps. [xs] places one hand at each position;
/// the hand at [movingX] (if any) taps, the others hold still.
void _feed(
  CameraTestViewModel model, {
  required int count,
  List<double> xs = const <double>[0.5],
  double? movingX,
  double palm = 0.1,
  int startMs = 0,
}) {
  for (int i = 0; i < count; i++) {
    final tap = (i % 8 < 4) ? 0.0 : 0.06;
    model.onFrame(FrameData(
      timestamp: startMs + i * 33,
      hands: <LandmarkData>[
        for (final x in xs)
          _data(_hand(x: x, offset: x == movingX ? tap : 0, palm: palm)),
      ],
    ));
  }
}

void main() {
  group('CameraTestViewModel -', () {
    setUp(registerServices);
    tearDown(locator.reset);

    group('setup checks', () {
      test('no hands, one hand, then both', () {
        final model = CameraTestViewModel();
        expect(model.setupHint, SetupHint.noHands);

        _feed(model, count: 1, xs: <double>[0.7]);
        expect(model.setupHint, SetupHint.oneHand);

        _feed(model, count: 1, xs: <double>[0.3, 0.7]);
        expect(model.setupHint, SetupHint.ready);
      });

      test('small hands ask the patient to move closer', () {
        final model = CameraTestViewModel();
        _feed(model, count: 1, xs: <double>[0.3, 0.7], palm: 0.04);
        expect(model.setupHint, SetupHint.tooFar);
      });

      test('a hand off the edge asks the patient to move back', () {
        final model = CameraTestViewModel();
        _feed(model, count: 1, xs: <double>[0.3, 0.7], palm: 0.6);
        expect(model.setupHint, SetupHint.tooClose);
      });

      test('frame rate is measured from the capture timestamps', () {
        final model = CameraTestViewModel();
        _feed(model, count: 31, xs: <double>[0.5]);
        expect(model.measuredFps, closeTo(30, 0.5));
        expect(model.cameraIsSlow, isFalse);
      });

      test('a slow camera is flagged', () {
        final model = CameraTestViewModel();
        for (int i = 0; i < 11; i++) {
          model.onFrame(FrameData(
            timestamp: i * 100,
            hands: <LandmarkData>[_data(_hand())],
          ));
        }
        expect(model.measuredFps, closeTo(10, 0.5));
        expect(model.cameraIsSlow, isTrue);
      });
    });

    group('hands-free flow', () {
      test('start opens the first step countdown and announces it', () {
        final cues = <CameraCueKind>[];
        final model = CameraTestViewModel()..onCue = (c) => cues.add(c.kind);
        model.start();

        expect(model.phase, CameraTestPhase.preparing);
        expect(model.currentTask!.id, 'both_rest');
        expect(cues, <CameraCueKind>[CameraCueKind.instruction]);
        expect(model.segments.every((s) => s.samples.isEmpty), isTrue,
            reason: 'nothing is recorded during the countdown');
      });

      test('the countdown waits until both hands are seen for a both-hands step',
          () {
        final model = CameraTestViewModel()..start();
        expect(model.awaitingHand, isTrue);

        _feed(model, count: 1, xs: <double>[0.7]);
        expect(model.awaitingHand, isTrue, reason: 'one hand is not enough');

        _feed(model, count: 1, xs: <double>[0.3, 0.7]);
        expect(model.awaitingHand, isFalse);
      });

      test('a clean step moves on by itself, with go and stop cues', () {
        final cues = <CameraCueKind>[];
        final model = CameraTestViewModel()..onCue = (c) => cues.add(c.kind);
        model.start();
        model.beginRecordingNow();

        _feed(model, count: 300, xs: <double>[0.3, 0.7]);
        model.completeCurrentTask();

        expect(model.phase, CameraTestPhase.preparing);
        expect(model.currentTask!.id, 'both_posture');
        expect(model.qualities['right_rest']?.valid, isTrue);
        expect(model.qualities['left_rest']?.valid, isTrue);
        expect(cues, containsAllInOrder(<CameraCueKind>[
          CameraCueKind.go,
          CameraCueKind.stop,
          CameraCueKind.instruction,
        ]));
      });

      test('a failed step is repeated once automatically, then kept', () {
        final cues = <CameraCueKind>[];
        final model = CameraTestViewModel()..onCue = (c) => cues.add(c.kind);
        model.start();
        final first = model.currentTask!;

        model.beginRecordingNow();
        _feed(model, count: 300, xs: const <double>[]);
        model.completeCurrentTask();

        expect(model.phase, CameraTestPhase.preparing,
            reason: 'no tap is needed to repeat');
        expect(model.currentTask, same(first));
        expect(model.retryReason, isNotNull);
        expect(cues.last, CameraCueKind.retry);
        expect(model.segments.where((s) => identical(s.task, first))
            .every((s) => s.samples.isEmpty), isTrue,
            reason: 'the repeat starts from an empty recording');

        model.beginRecordingNow();
        _feed(model, count: 300, xs: const <double>[]);
        model.completeCurrentTask();

        expect(model.currentTask, isNot(same(first)),
            reason: 'after the repeat the run carries on regardless');
        expect(model.attemptsFor(first.id),
            CameraTestViewModel.maxAttemptsPerTask);
        expect(model.retryReason, isNull);
      });

      test('frames outside a recording are not kept', () {
        final model = CameraTestViewModel()..start();
        _feed(model, count: 30, xs: <double>[0.3, 0.7]);
        expect(model.segments.every((s) => s.samples.isEmpty), isTrue);
      });
    });

    group('which hand is which', () {
      test('both-hands steps file each hand by its side of the picture', () {
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        _feed(model, count: 30, xs: <double>[0.25, 0.75]);

        final right = model.segments.firstWhere((s) => s.taskId == 'right_rest');
        final left = model.segments.firstWhere((s) => s.taskId == 'left_rest');
        expect(right.frames.first.landmarks.first.x, 0.75);
        expect(left.frames.first.landmarks.first.x, 0.25);
      });

      test('a one-hand step records the moving hand, not the resting one', () {
        // The bug behind "changing hands does not work": with both hands in
        // view, the label decided which was recorded, and it was the wrong one.
        final model = CameraTestViewModel()..start();
        for (int i = 0; i < 2; i++) {
          model.beginRecordingNow();
          _feed(model, count: 300, xs: <double>[0.3, 0.7]);
          model.completeCurrentTask();
        }
        expect(model.currentTask!.id, 'right_fingerTap');
        expect(model.currentTask!.switchesHand, isTrue);

        model.beginRecordingNow();
        _feed(model, count: 300, xs: <double>[0.3, 0.7], movingX: 0.7);

        final segment =
            model.segments.firstWhere((s) => s.taskId == 'right_fingerTap');
        expect(segment.frames, isNotEmpty);
        expect(segment.frames.every((f) => f.landmarks.first.x == 0.7), isTrue);
      });
    });
  });
}
