import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/app/app.locator.dart';
import 'package:parkinsondetetion/models/frame_data.dart';
import 'package:parkinsondetetion/models/hand_posture.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/models/posture_test_result.dart';
import 'package:parkinsondetetion/services/hand_geometry.dart';
import 'package:parkinsondetetion/ui/views/posture_test/posture_test_viewmodel.dart';

import '../helpers/test_helpers.dart';
import '../services/hand_posture_classifier_test.dart' show handFor;
import '../services/synthetic_hand.dart';

FrameData _frame(List<LandmarkPoint>? landmarks, {int t = 0}) => FrameData(
      timestamp: t,
      hands: landmarks == null
          ? const <LandmarkData>[]
          : <LandmarkData>[
              LandmarkData(handedness: 'Right', landmarks: landmarks),
            ],
    );

/// Feeds [count] frames of [landmarks]; `null` means no hand in view.
void _feed(
  PostureTestViewModel model,
  List<LandmarkPoint>? landmarks, {
  int count = 1,
}) {
  for (int i = 0; i < count; i++) {
    model.onFrame(_frame(landmarks, t: i * 33));
  }
}

/// Copies the posture currently being asked for.
void _copyCurrent(PostureTestViewModel model, {int count = 10}) {
  _feed(model, handFor(model.currentPosture!), count: count);
}

void main() {
  group('PostureTestViewModel -', () {
    setUp(registerServices);
    tearDown(locator.reset);

    PostureTestViewModel started() {
      final model = PostureTestViewModel()..start();
      model.beginWatching();
      return model;
    }

    group('holding a posture', () {
      test('a copied posture is accepted and the run moves on', () {
        final model = started();
        final first = model.currentPosture!;

        _copyCurrent(model);

        expect(model.currentPosture, isNot(first));
        expect(model.index, 1);
      });

      test('one frame is not enough — the posture must be held', () {
        // A hand on its way between shapes passes through others. This is the
        // guard that stops a posture registering from a frame in passing.
        final model = started();
        final first = model.currentPosture!;

        _feed(model, handFor(first), count: PostureTestViewModel.framesToHold - 1);

        expect(model.currentPosture, first, reason: 'not yet held long enough');
        expect(model.holdProgress, lessThan(1.0));
      });

      test('a broken run starts the count again', () {
        final model = started();
        final first = model.currentPosture!;

        _feed(model, handFor(first), count: 3);
        _feed(model, SyntheticHand.build(), count: 1); // a fist, breaking it
        _feed(model, handFor(first), count: 3);

        expect(model.currentPosture, first);
      });
    });

    group('two trials per posture', () {
      test('a second attempt is offered before moving on', () {
        final model = started();
        final first = model.currentPosture!;

        expect(model.trial, 1);
        model.skipCurrent();

        expect(model.currentPosture, first, reason: 'same posture, next trial');
        expect(model.trial, 2);
        expect(model.isRetry, isTrue);
      });

      test('after both trials the run moves on regardless', () {
        final model = started();
        final first = model.currentPosture!;

        model.skipCurrent();
        model.beginWatching();
        model.skipCurrent();

        expect(model.currentPosture, isNot(first));
        expect(model.trial, 1, reason: 'trial counter resets per posture');
      });

      test('copying on the first trial scores two, the second one', () async {
        final model = PostureTestViewModel()..start();

        for (int i = 0; i < HandPostures.all.length; i++) {
          model.beginWatching();
          // Miss the first posture once, then copy everything.
          if (i == 0) {
            model.skipCurrent();
            model.beginWatching();
          }
          _copyCurrent(model);
        }

        await Future<void>.delayed(Duration.zero);

        final result = model.result!;
        expect(result.items.first.copiedOnTrial, 2);
        expect(result.items.first.points, 1);
        expect(result.items[1].copiedOnTrial, 1);
        expect(result.items[1].points, 2);
        expect(result.points, HandPostures.maximumScore - 1);
      });
    });

    group('a missing hand is not a failed posture', () {
      test('an attempt with no hand in view is recorded as unrecorded', () {
        final model = started();

        _feed(model, null, count: 20);
        model.skipCurrent();

        expect(model.handVisible, isFalse);
      });

      test('a run that never saw a hand is not saved', () async {
        // Zero on this scale means "copied none of them", which is a statement
        // about the patient that an empty recording gives no grounds for.
        final model = PostureTestViewModel()..start();

        for (int i = 0; i < HandPostures.all.length; i++) {
          model.beginWatching();
          _feed(model, null, count: 5);
          model.skipCurrent();
          model.beginWatching();
          _feed(model, null, count: 5);
          model.skipCurrent();
        }

        await Future<void>.delayed(Duration.zero);

        expect(model.result!.hasUsableRecording, isFalse);
        expect(model.resultSaved, isFalse);
        expect(model.result!.unrecordedItems, hasLength(HandPostures.all.length));
      });

      test('an unrecorded item is distinguishable from a failed one', () {
        const unrecorded = PostureItemResult(
          postureId: 'point',
          attempts: <PostureAttempt>[
            PostureAttempt(
              trial: 1,
              outcome: PostureOutcome.notRecorded,
              usableFrames: 0,
              totalFrames: 30,
            ),
          ],
        );
        const failed = PostureItemResult(
          postureId: 'point',
          attempts: <PostureAttempt>[
            PostureAttempt(
              trial: 1,
              outcome: PostureOutcome.notCopied,
              usableFrames: 30,
              totalFrames: 30,
            ),
          ],
        );

        expect(unrecorded.points, 0);
        expect(failed.points, 0);
        // Same score, different meaning.
        expect(unrecorded.neverRecorded, isTrue);
        expect(failed.neverRecorded, isFalse);
      });
    });

    group('scoring', () {
      test('a perfect run stores a concern of zero', () async {
        final model = PostureTestViewModel()..start();

        for (int i = 0; i < HandPostures.all.length; i++) {
          model.beginWatching();
          _copyCurrent(model);
        }
        await Future<void>.delayed(Duration.zero);

        final result = model.result!;
        expect(result.points, HandPostures.maximumScore);
        // Stored under schema 2, where 0 is the best possible outcome. Getting
        // this backwards would show a perfect score as maximum concern.
        expect(result.concern, 0);
      });

      test('copying nothing stores full concern', () {
        final result = PostureTestResult(
          performedAt: DateTime(2026),
          items: <PostureItemResult>[
            for (final posture in HandPostures.all)
              PostureItemResult(
                postureId: posture.id,
                attempts: const <PostureAttempt>[
                  PostureAttempt(
                    trial: 1,
                    outcome: PostureOutcome.notCopied,
                    usableFrames: 30,
                    totalFrames: 30,
                  ),
                ],
              ),
          ],
        );

        expect(result.points, 0);
        expect(result.concern, 1);
        expect(result.hasUsableRecording, isTrue);
      });

      test('copying the wrong posture records which one it was', () async {
        // Making a different recognisable shape is a different error from
        // making no recognisable shape, and the distinction is worth keeping.
        final model = PostureTestViewModel()..start();
        final asked = model.currentPosture!;
        final other = HandPostures.all.firstWhere((p) => p.id != asked.id);

        for (int i = 0; i < HandPostures.all.length; i++) {
          for (int trial = 0; trial < HandPostures.trialsPerPosture; trial++) {
            model.beginWatching();
            if (i == 0) _feed(model, handFor(other), count: 10);
            model.skipCurrent();
          }
        }
        await Future<void>.delayed(Duration.zero);

        final first = model.result!.items.first;
        expect(first.points, 0);
        expect(first.neverRecorded, isFalse,
            reason: 'the hand was seen — it was simply the wrong shape');
        expect(first.attempts.first.observedPostureId, other.id);
      });
    });

    group('serialization', () {
      test('records points, quality and every attempt', () {
        final result = PostureTestResult(
          performedAt: DateTime(2026),
          items: <PostureItemResult>[
            const PostureItemResult(
              postureId: 'point',
              attempts: <PostureAttempt>[
                PostureAttempt(
                  trial: 1,
                  outcome: PostureOutcome.copied,
                  usableFrames: 28,
                  totalFrames: 30,
                  secondsTaken: 1.4,
                ),
              ],
            ),
          ],
        );

        final json = result.toJson();

        expect(json['points'], 2);
        expect(json['maximum_points'], HandPostures.maximumScore);
        expect(json['recording_quality'], closeTo(28 / 30, 1e-9));
        expect((json['items'] as List).single, containsPair('points', 2));
      });
    });

    group('geometry sanity', () {
      test('the synthetic hands are the right size', () {
        // Guards the fixture itself: if the palm span drifted, every
        // palm-relative threshold in the classifier would shift with it and the
        // tests would keep passing while measuring something else.
        expect(
          HandGeometry.palmSpan(SyntheticHand.build()),
          closeTo(SyntheticHand.palm, 1e-9),
        );
      });
    });
  });
}
