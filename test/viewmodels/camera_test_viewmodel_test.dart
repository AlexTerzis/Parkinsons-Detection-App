import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/app/app.locator.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/models/frame_data.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/models/tracking_event.dart';
import 'package:parkinsondetetion/ui/views/camera_test/camera_test_viewmodel.dart';

import '../helpers/test_helpers.dart';

/// A hand placed well inside the frame, with a stable palm size.
///
/// [offset] moves the index tip away from the thumb, so alternating it
/// produces a detectable tapping cycle.
List<LandmarkPoint> _hand({double offset = 0}) {
  final points = List<LandmarkPoint>.generate(
    21,
    (_) => const LandmarkPoint(x: 0.5, y: 0.5, z: 0),
  );
  points[0] = const LandmarkPoint(x: 0.5, y: 0.5, z: 0);
  points[9] = const LandmarkPoint(x: 0.5, y: 0.4, z: 0);
  points[4] = const LandmarkPoint(x: 0.5, y: 0.4, z: 0);
  points[8] = LandmarkPoint(x: 0.5 + offset, y: 0.4, z: 0);
  return points;
}

/// Feeds [count] frames into the ViewModel at 30 fps.
void _feed(
  CameraTestViewModel model, {
  required int count,
  required String hand,
  bool visible = true,
  int startMs = 0,
}) {
  for (int i = 0; i < count; i++) {
    model.onFrame(FrameData(
      timestamp: startMs + i * 33,
      hands: visible
          ? <LandmarkData>[
              LandmarkData(
                handedness: hand,
                landmarks: _hand(offset: (i % 8 < 4) ? 0.0 : 0.06),
                handednessConfidence: 0.95,
              ),
            ]
          : const <LandmarkData>[],
    ));
  }
}

int _frameCount(CameraTestViewModel model, String taskId) =>
    model.segments.firstWhere((s) => s.taskId == taskId).frames.length;

void main() {
  group('CameraTestViewModel -', () {
    setUp(registerServices);
    tearDown(locator.reset);

    group('task validation gates progression', () {
      test('a task recorded with no hand visible stops the run', () {
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        final firstTask = model.currentTask!;

        _feed(model, count: 420, hand: firstTask.hands.first, visible: false);
        model.completeCurrentTask();

        // The old behaviour: the run advanced regardless, and the whole test
        // completed as long as a hand had appeared once anywhere in it.
        expect(model.phase, CameraTestPhase.taskReview);
        expect(model.currentTask, firstTask,
            reason: 'the run must not have moved on');
        expect(model.currentQuality?.valid, isFalse);
        expect(model.currentQuality?.retryRecommended, isTrue);
      });

      test('a well recorded task advances without interruption', () {
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        final firstTask = model.currentTask!;

        _feed(model, count: 420, hand: firstTask.hands.first);
        model.completeCurrentTask();

        expect(model.phase, CameraTestPhase.preparing,
            reason: 'the next step waits on its instruction, not a retry');
        expect(model.currentTask, isNot(firstTask));
        expect(model.qualities[firstTask.id]?.valid, isTrue);
      });

      test('a lone hand is accepted even when labelled as the other side', () {
        // The regression that made the test impossible to finish on a device.
        // The front camera mirrors its frames before the detector sees them, so
        // a right hand is reported as "Left" and every step failed. The
        // instruction the patient was given is better evidence than a label
        // that can be inverted wholesale.
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        final task = model.currentTask!;
        final wrong = task.hands.first == 'Right' ? 'Left' : 'Right';

        _feed(model, count: 420, hand: wrong);
        model.completeCurrentTask();

        expect(model.phase, CameraTestPhase.preparing);
        expect(model.qualities[task.id]?.valid, isTrue);
      });

      test('the disagreement is recorded rather than smoothed away', () {
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        final task = model.currentTask!;
        final wrong = task.hands.first == 'Right' ? 'Left' : 'Right';

        _feed(model, count: 420, hand: wrong);

        final segment =
            model.segments.firstWhere((s) => s.taskId == task.id);
        expect(
          segment.stateCounts[TrackingState.lowConfidence],
          420,
          reason: 'accepted, but never counted as a clean detection',
        );
        expect(segment.stateCounts[TrackingState.tracked], isNull);
      });
    });

    group('retry', () {
      test('re-records only the failed task, keeping completed ones', () {
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        final first = model.currentTask!;

        _feed(model, count: 420, hand: first.hands.first);
        model.completeCurrentTask();
        expect(model.phase, CameraTestPhase.preparing);
        model.beginRecordingNow();

        final second = model.currentTask!;
        expect(second, isNot(first));

        _feed(model, count: 200, hand: second.hands.first, visible: false);
        model.completeCurrentTask();
        expect(model.phase, CameraTestPhase.taskReview);

        model.retryCurrentTask();
        expect(model.phase, CameraTestPhase.preparing);
        model.beginRecordingNow();
        expect(model.currentTask, second, reason: 'same task, fresh recording');

        _feed(model, count: 500, hand: second.hands.first);
        model.completeCurrentTask();

        expect(model.qualities[first.id]?.valid, isTrue,
            reason: 'the earlier valid task survives the retry');
        expect(model.qualities[second.id]?.valid, isTrue);
      });

      test('a retry starts the task from an empty recording', () {
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        final task = model.currentTask!;

        _feed(model, count: 200, hand: task.hands.first);
        expect(_frameCount(model, task.id), 200);

        // Force a failure the frames alone cannot cause.
        _feed(model, count: 400, hand: task.hands.first, visible: false);
        model.completeCurrentTask();
        expect(model.phase, CameraTestPhase.taskReview);

        model.retryCurrentTask();

        expect(_frameCount(model, task.id), 0,
            reason: 'the rejected attempt must not bleed into the new one');
      });

      test('attempts are counted and capped', () {
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        final task = model.currentTask!;

        expect(model.currentAttempt, 1);

        for (int attempt = 1;
            attempt < CameraTestViewModel.maxAttemptsPerTask;
            attempt++) {
          _feed(model, count: 200, hand: task.hands.first, visible: false);
          model.completeCurrentTask();
          expect(model.phase, CameraTestPhase.taskReview);
          expect(model.canRetryCurrentTask, isTrue);
          model.retryCurrentTask();
          model.beginRecordingNow();
        }

        expect(model.currentAttempt, CameraTestViewModel.maxAttemptsPerTask);

        _feed(model, count: 200, hand: task.hands.first, visible: false);
        model.completeCurrentTask();

        // Past the cap the run advances rather than offering another go, so the
        // patient cannot be trapped repeating a step their room or their phone
        // will never let them pass. The failure stays on the record.
        expect(model.phase, CameraTestPhase.preparing);
        expect(model.currentTask, isNot(task));
        expect(model.qualities[task.id]?.valid, isFalse);
        expect(model.attemptsFor(task.id),
            CameraTestViewModel.maxAttemptsPerTask);
      });

      test('the patient can always continue without a clean recording', () {
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        final task = model.currentTask!;

        _feed(model, count: 200, hand: task.hands.first, visible: false);
        model.completeCurrentTask();
        expect(model.phase, CameraTestPhase.taskReview);

        model.keepAndContinue();

        expect(model.phase, CameraTestPhase.preparing);
        expect(model.currentTask, isNot(task));
        expect(model.qualities[task.id]?.valid, isFalse,
            reason: 'the failure is kept on the record, not erased');
      });
    });

    group('task boundaries', () {
      test('frames are filed against the task that was running', () {
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        final first = model.currentTask!;

        _feed(model, count: 420, hand: first.hands.first);
        model.completeCurrentTask();
        model.beginRecordingNow();
        final second = model.currentTask!;
        _feed(model, count: 420, hand: second.hands.first, startMs: 100000);

        expect(_frameCount(model, first.id), 420);
        expect(_frameCount(model, second.id), 420);
      });

      test('frames arriving outside a running task are ignored', () {
        final model = CameraTestViewModel();
        final tasks = CameraTaskProtocol.build(CameraTestMode.full);

        _feed(model, count: 30, hand: tasks.first.hands.first);
        model.start();

        expect(_frameCount(model, tasks.first.id), 0);
      });
    });

    group('every frame is accounted for', () {
      test('frames with no hand are recorded, not dropped', () {
        final model = CameraTestViewModel()..start();
        model.beginRecordingNow();
        final task = model.currentTask!;

        _feed(model, count: 40, hand: task.hands.first);
        _feed(model, count: 60, hand: task.hands.first, visible: false, startMs: 2000);

        final segment = model.segments.firstWhere((s) => s.taskId == task.id);

        expect(segment.samples, hasLength(100));
        expect(segment.frames, hasLength(40));
        expect(segment.missedFrames, 60,
            reason: 'frames holding no hand at all used to be invisible');
      });
    });

    group('pacing', () {
      test('a run opens on the instruction, recording nothing', () {
        final model = CameraTestViewModel()..start();
        final task = model.currentTask!;

        expect(model.phase, CameraTestPhase.preparing);
        expect(model.isAwaitingReady, isTrue);

        // The patient is still reading. Anything captured now would be them
        // arranging their hand, and would be measured as a hesitant start.
        _feed(model, count: 200, hand: task.hands.first);

        expect(_frameCount(model, task.id), 0);
      });

      test('self-paced waits for the patient rather than a clock', () {
        final model = CameraTestViewModel()
          ..setPacing(CameraPacing.selfPaced)
          ..start();

        expect(model.isAwaitingReady, isTrue);
        expect(model.leadInCountdown, isNull,
            reason: 'no countdown is running while it waits on the tap');

        // The tap starts the short get-ready, not the recording itself.
        model.startCurrentStep();

        expect(model.isAwaitingReady, isFalse);
        expect(model.phase, CameraTestPhase.preparing);
        expect(model.leadInCountdown, isNotNull);
      });

      test('timed pacing counts down on its own', () {
        final model = CameraTestViewModel()
          ..setPacing(CameraPacing.timed)
          ..start();

        expect(model.isAwaitingReady, isFalse);
        expect(model.leadInCountdown, isNotNull);
      });

      test('pacing is fixed once the run starts', () {
        final model = CameraTestViewModel()..start();
        model.setPacing(CameraPacing.timed);

        expect(model.pacing, CameraPacing.selfPaced);
      });
    });

    group('both hands together', () {
      CameraTestViewModel shortRun() {
        final model = CameraTestViewModel()..setMode(CameraTestMode.short);
        model.start();
        model.beginRecordingNow();
        return model;
      }

      test('a step records one segment per hand', () {
        final model = shortRun();
        final task = model.currentTask!;

        expect(task.isBothHands, isTrue);
        expect(
          model.segments.where((s) => s.taskId == task.segmentId('Right')),
          hasLength(1),
        );
        expect(
          model.segments.where((s) => s.taskId == task.segmentId('Left')),
          hasLength(1),
        );
      });

      test('frames are filed against the hand they belong to', () {
        final model = shortRun();
        final task = model.currentTask!;

        for (int i = 0; i < 300; i++) {
          model.onFrame(FrameData(
            timestamp: i * 33,
            hands: <LandmarkData>[
              LandmarkData(
                handedness: 'Right',
                landmarks: _hand(offset: (i % 8 < 4) ? 0.0 : 0.06),
                handednessConfidence: 0.95,
              ),
              LandmarkData(
                handedness: 'Left',
                landmarks: _hand(offset: (i % 8 < 4) ? 0.0 : 0.06),
                handednessConfidence: 0.95,
              ),
            ],
          ));
        }

        expect(_frameCount(model, task.segmentId('Right')), 300);
        expect(_frameCount(model, task.segmentId('Left')), 300);
      });

      test('one hand missing fails the step, since both were asked for', () {
        final model = shortRun();
        final task = model.currentTask!;

        // Only the right hand is shown. With two hands under examination the
        // lone-hand fallback cannot apply — the labels are what tell them
        // apart — so the left hand simply has no recording.
        _feed(model, count: 300, hand: 'Right');
        model.completeCurrentTask();

        expect(model.phase, CameraTestPhase.taskReview);
        expect(model.qualities[task.segmentId('Left')]?.valid, isFalse);
      });

      test('storage keys match a full run\'s', () {
        final model = shortRun();

        expect(
          model.segments.map((s) => s.taskId).toSet(),
          CameraTaskProtocol.build(CameraTestMode.full)
              .map((t) => t.id)
              .toSet(),
        );
      });

      test('a retry re-records both hands of the step', () {
        final model = shortRun();
        final task = model.currentTask!;

        _feed(model, count: 300, hand: 'Right');
        model.completeCurrentTask();
        expect(model.phase, CameraTestPhase.taskReview);

        model.retryCurrentTask();

        expect(_frameCount(model, task.segmentId('Right')), 0);
        expect(_frameCount(model, task.segmentId('Left')), 0);
      });
    });
  });
}
