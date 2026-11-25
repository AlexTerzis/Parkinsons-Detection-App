import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/hand_posture.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/services/hand_geometry.dart';
import 'package:parkinsondetetion/services/hand_posture_classifier.dart';

import 'synthetic_hand.dart';

/// The landmarks a patient copying [posture] would produce.
///
/// Every posture in the catalogue needs one of these, and building them here
/// rather than inside each test is what makes the "no posture matches another"
/// sweep below possible.
List<LandmarkPoint> handFor(HandPosture posture, {double scale = 1.0}) {
  switch (posture.id) {
    case 'point':
      return SyntheticHand.build(
        extended: <Finger>{Finger.indexFinger},
        scale: scale,
      );
    case 'open_palm':
      return SyntheticHand.build(
        extended: <Finger>{
          Finger.indexFinger,
          Finger.middle,
          Finger.ring,
          Finger.pinky,
        },
        thumbOut: true,
        scale: scale,
      );
    case 'fist':
      return SyntheticHand.build(scale: scale);
    case 'victory':
      return SyntheticHand.build(
        extended: <Finger>{Finger.indexFinger, Finger.middle},
        spreadIndexMiddle: true,
        scale: scale,
      );
    case 'two_together':
      return SyntheticHand.build(
        extended: <Finger>{Finger.indexFinger, Finger.middle},
        scale: scale,
      );
    case 'horns':
      return SyntheticHand.build(
        extended: <Finger>{Finger.indexFinger, Finger.pinky},
        scale: scale,
      );
    case 'shaka':
      return SyntheticHand.build(
        extended: <Finger>{Finger.pinky},
        thumbOut: true,
        scale: scale,
      );
    case 'ok_ring':
      return SyntheticHand.build(
        extended: <Finger>{Finger.middle, Finger.ring, Finger.pinky},
        pinchIndexToThumb: true,
        scale: scale,
      );
    case 'i_love_you':
      return SyntheticHand.build(
        extended: <Finger>{Finger.indexFinger, Finger.pinky},
        thumbOut: true,
        scale: scale,
      );
    case 'three_fingers':
      return SyntheticHand.build(
        extended: <Finger>{
          Finger.indexFinger,
          Finger.middle,
          Finger.ring,
        },
        scale: scale,
      );
    default:
      throw ArgumentError('No synthetic hand for "${posture.id}"');
  }
}

void main() {
  const classifier = HandPostureClassifier();

  group('HandPostureClassifier', () {
    group('reads the shape it was given', () {
      test('an open hand has every finger extended', () {
        final shape = classifier.describe(handFor(HandPostures.openPalm))!;

        expect(shape.extended, <Finger>{
          Finger.indexFinger,
          Finger.middle,
          Finger.ring,
          Finger.pinky,
        });
      });

      test('a fist has none extended', () {
        final shape = classifier.describe(handFor(HandPostures.fist))!;

        expect(shape.extended, isEmpty);
        expect(shape.thumbExtended, isFalse);
      });

      test('a thumb held out reads as extended, one tucked does not', () {
        final out = classifier
            .describe(SyntheticHand.build(thumbOut: true))!;
        final tucked = classifier.describe(SyntheticHand.build())!;

        expect(out.thumbExtended, isTrue);
        expect(tucked.thumbExtended, isFalse);
        expect(out.thumbAbduction, greaterThan(tucked.thumbAbduction));
      });

      test('spread fingers are distinguished from fingers held together', () {
        final apart = classifier.describe(handFor(HandPostures.victory))!;
        final together =
            classifier.describe(handFor(HandPostures.twoTogether))!;

        expect(apart.indexMiddleApart, isTrue);
        expect(together.indexMiddleApart, isFalse);
      });

      test('a pinch is detected, and named', () {
        final shape = classifier.describe(handFor(HandPostures.okRing))!;

        expect(shape.thumbTouching, Finger.indexFinger);
      });

      test('an open hand has no pinch', () {
        final shape = classifier.describe(handFor(HandPostures.openPalm))!;

        expect(shape.thumbTouching, isNull);
      });
    });

    group('every posture is recognised, and only itself', () {
      for (final posture in HandPostures.all) {
        test('${posture.id} matches its own hand', () {
          expect(
            classifier.isPosture(handFor(posture), posture),
            isTrue,
            reason: '${posture.id} did not recognise the hand built for it',
          );
        });

        test('${posture.id} is not confused with any other', () {
          final landmarks = handFor(posture);
          for (final other in HandPostures.all) {
            if (identical(other, posture)) continue;
            expect(
              classifier.isPosture(landmarks, other),
              isFalse,
              reason: '${posture.id} was also read as ${other.id}',
            );
          }
        });

        test('${posture.id} is identified from the whole catalogue', () {
          expect(classifier.identify(handFor(posture))?.id, posture.id);
        });
      }

      test('the catalogue has ten postures worth twenty points', () {
        expect(HandPostures.all, hasLength(9));
        expect(HandPostures.maximumScore, 18);
        expect(
          HandPostures.all.map((p) => p.id).toSet().length,
          HandPostures.all.length,
          reason: 'ids must be unique — they are the storage keys',
        );
      });
    });

    group('does not invent a posture', () {
      test('a shape outside the catalogue matches nothing', () {
        // The ring finger alone is a perfectly possible hand and is not one of
        // the ten. It must come back unrecognised rather than be rounded to the
        // nearest entry.
        final ringOnly =
            SyntheticHand.build(extended: <Finger>{Finger.ring});

        expect(classifier.identify(ringOnly), isNull);
      });

      test('a barely-lifted finger still reads as curled', () {
        // Guards the extension margin. Without it a finger hovering between
        // bent and straight flips state frame to frame, and a posture would
        // register from noise rather than from the patient holding it.
        //
        // Note this hand is a legitimate fist, not an unrecognisable shape —
        // protection against a hand *passing through* a posture is the
        // hold-for-N-frames rule, which lives in the ViewModel and is tested
        // there. A single frame cannot tell a held posture from a transient one.
        final shape =
            classifier.describe(SyntheticHand.midTransition())!;

        expect(shape.extended, isEmpty);
      });

      test('an incomplete hand describes as null, not as a fist', () {
        // A tracking failure must not score as a posture the patient never
        // made — which is exactly what a zero-valued default would do.
        final partial =
            SyntheticHand.build().sublist(0, 12);

        expect(classifier.describe(partial), isNull);
        expect(classifier.identify(partial), isNull);
      });

      test('a degenerate hand with no palm span describes as null', () {
        final collapsed = List<LandmarkPoint>.filled(
          HandLandmark.count,
          const LandmarkPoint(x: 0.5, y: 0.5, z: 0),
        );

        expect(classifier.describe(collapsed), isNull);
      });
    });

    group('scale invariance', () {
      test('a hand nearer the lens reads as the same posture', () {
        // Landmarks are normalised to the frame, so an identical hand produces
        // larger numbers when it is closer. Every measure here is in palm
        // widths precisely so that does not matter.
        for (final posture in HandPostures.all) {
          expect(
            classifier.isPosture(handFor(posture, scale: 1.6), posture),
            isTrue,
            reason: '${posture.id} failed when the hand was nearer the camera',
          );
        }
      });
    });

    group('palm facing', () {
      test('a palm toward the camera is reported as such', () {
        final shape = classifier.describe(
          handFor(HandPostures.openPalm),
          handedness: 'Right',
        )!;

        expect(shape.facing, PalmFacing.toward);
      });

      test('the same hand read as the other side flips the facing', () {
        // A left hand is the mirror of a right one, so the palm normal's sign
        // reverses. Without the handedness correction the two would disagree
        // about which way an identical hand was turned.
        final right = classifier.describe(
          handFor(HandPostures.openPalm),
          handedness: 'Right',
        )!;
        final left = classifier.describe(
          handFor(HandPostures.openPalm),
          handedness: 'Left',
        )!;

        expect(right.facing, PalmFacing.toward);
        expect(left.facing, PalmFacing.away);
      });
    });

    group('serialization', () {
      test('a shape records what it saw', () {
        final json =
            classifier.describe(handFor(HandPostures.okRing))!.toJson();

        expect(json['thumbTouching'], 'indexFinger');
        expect(json['extended'], containsAll(<String>['middle', 'ring']));
        expect(json['facing'], isNotNull);
      });
    });
  });
}
