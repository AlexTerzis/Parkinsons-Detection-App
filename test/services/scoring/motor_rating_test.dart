import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/services/scoring/camera_recording.dart';
import 'package:parkinsondetetion/services/scoring/motor_rating.dart';

import 'synthetic_recording.dart';

void main() {
  const scorer = MotorRatingScorer();

  group('RatingAnchors', () {
    test('interpolates between anchors, rising', () {
      const anchors = RatingAnchors(<double>[0, 1, 2, 3, 4]);
      expect(anchors.rate(-1), 0);
      expect(anchors.rate(1.5), closeTo(1.5, 1e-9));
      expect(anchors.rate(9), 4);
    });

    test('interpolates between anchors, falling (lower is worse)', () {
      expect(MotorRatingRules.tapRate.rate(4.0), 0);
      expect(MotorRatingRules.tapRate.rate(2.3), closeTo(1, 1e-9));
      expect(MotorRatingRules.tapRate.rate(1.6), closeTo(2, 1e-9));
      expect(MotorRatingRules.tapRate.rate(0.1), 4);
    });
  });

  group('MotorRatingScorer', () {
    test('a healthy recording rates near normal and scores low', () {
      final rating = scorer.rate(Synthetic.healthy());

      for (final hand in rating.hands) {
        expect(hand.bradykinesia, isNotNull);
        expect(hand.bradykinesia!, lessThan(1.0), reason: hand.hand);
        expect(hand.tremor, isNotNull);
        expect(hand.tremor!, lessThan(0.5), reason: hand.hand);
      }
      expect(rating.score, isNotNull);
      expect(rating.score!, lessThan(0.25));
    });

    test('a parkinsonian recording rates worse and scores higher', () {
      final healthy = scorer.rate(Synthetic.healthy());
      final pd = scorer.rate(Synthetic.parkinsonian());

      expect(pd.score!, greaterThan(healthy.score!));
      expect(pd.score!, greaterThan(0.3), reason: "at least borderline");
      expect(pd.tremor!, greaterThan(1.0));
    });

    test('the worse hand drives the score, and the asymmetry is seen', () {
      // A normal left hand and a slow, decrementing right one.
      final rec = Synthetic.recording(
        rateHz: 1.4,
        amplitude: 1.0,
        decrement: 0.5,
        leftRateHz: 4.5,
        includeRest: false,
      );
      final leftNormal = CameraRecording(tasks: <RecordedTask>[
        for (final t in rec.tasks)
          if (t.hand == 'Right')
            t
          else
            Synthetic.task(type: t.type, hand: 'Left', rateHz: 4.5),
      ]);
      final rating = scorer.rate(leftNormal);

      expect(rating.worseHand!.hand, 'Right');
      expect(rating.asymmetry!, greaterThan(1.0));
      expect(rating.handRating('Left')!.bradykinesia!, lessThan(0.5));
    });

    test('one pause is counted once, not again as irregular rhythm', () {
      final item = scorer.rateMovement(Synthetic.task(
        type: CameraTaskType.fingerTap,
        hand: 'Right',
        rateHz: 4,
        pauseAt: 5,
        pauseDuration: 1.2,
      ))!;

      expect(item.signs['pauses']!.raw, 1);
      expect(item.signs['rhythm']!.rating, lessThan(0.5));
      expect(item.rating, lessThan(1.0), reason: 'one hesitation is slight');
    });

    test('every movement and still task gets an item rating per hand', () {
      final rating = scorer.rate(Synthetic.healthy());
      for (final hand in rating.hands) {
        expect(hand.items.map((i) => i.type), containsAll(CameraTaskType.values));
        for (final item in hand.items) {
          expect(item.rating, inInclusiveRange(0, 4));
          expect(item.grade, inInclusiveRange(0, 4));
        }
      }
    });

    test('slower tapping rates worse on speed', () {
      double speedOf(double hz) => scorer
          .rateMovement(Synthetic.task(
              type: CameraTaskType.fingerTap, hand: 'Right', rateHz: hz))!
          .signs['speed']!
          .rating;

      expect(speedOf(1.5), greaterThan(speedOf(3.5)));
    });

    test('a hand that barely moves is rated as unable to perform', () {
      final item = scorer.rateMovement(Synthetic.task(
          type: CameraTaskType.openClose, hand: 'Right', rateHz: 0.15))!;
      expect(item.rating, 4);
    });

    test('nothing usable means no score, never a reassuring zero', () {
      final empty = scorer.rate(const CameraRecording(tasks: <RecordedTask>[]));
      expect(empty.score, isNull);
    });

    test('only tremor measured still gives no score', () {
      final rating = scorer.rate(CameraRecording(tasks: <RecordedTask>[
        Synthetic.task(
            type: CameraTaskType.rest,
            hand: 'Right',
            rateHz: 0,
            amplitude: 0,
            tremorAmplitude: 0.1),
      ]));
      expect(rating.tremor, isNotNull);
      expect(rating.score, isNull,
          reason: 'the score follows the movement items');
    });

    test('serializes the ratings and the score', () {
      final json = scorer.rate(Synthetic.parkinsonian()).toJson();
      expect(json['scorer_id'], MotorRatingRules.version);
      expect(json['score'], isA<double>());
      expect((json['hands'] as Map).keys, containsAll(<String>['Right', 'Left']));
    });
  });
}
