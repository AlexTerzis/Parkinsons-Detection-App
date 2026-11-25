import '../services/hand_geometry.dart';

/// What one frame's hand actually looked like.
///
/// A small, discrete description rather than raw landmarks: postures are
/// compared on shape, and reducing to a handful of booleans and palm-relative
/// distances first is what makes matching explainable and testable.
class HandShape {
  const HandShape({
    required this.extended,
    required this.thumbExtended,
    required this.thumbAbduction,
    required this.thumbGaps,
    required this.indexMiddleGap,
    required this.facing,
  });

  /// Which of the four fingers are straightened. The thumb is kept separate —
  /// it moves in a different plane and its "extension" means something else.
  final Set<Finger> extended;

  final bool thumbExtended;

  /// How far the thumb sits from the index knuckle, in palm widths. Separates a
  /// thumb held out from one folded flat across the palm.
  final double thumbAbduction;

  /// Thumb tip to each fingertip, in palm widths.
  final Map<Finger, double> thumbGaps;

  /// Index tip to middle tip, in palm widths.
  final double indexMiddleGap;

  final PalmFacing facing;

  /// The fingertip the thumb is pinched against, if any.
  Finger? get thumbTouching {
    Finger? nearest;
    double best = double.infinity;
    for (final entry in thumbGaps.entries) {
      if (entry.value < best) {
        best = entry.value;
        nearest = entry.key;
      }
    }
    return best <= HandPosture.contactGap ? nearest : null;
  }

  bool get indexMiddleApart => indexMiddleGap > HandPosture.spreadGap;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'extended': extended.map((f) => f.name).toList(growable: false),
        'thumbExtended': thumbExtended,
        'thumbAbduction': thumbAbduction,
        'thumbTouching': thumbTouching?.name,
        'indexMiddleGap': indexMiddleGap,
        'facing': facing.name,
      };
}

/// One posture the patient is asked to copy.
///
/// Declarative on purpose. Every posture is a small set of conditions rather
/// than a hand-written predicate, so the catalogue can be corrected against the
/// printed sheet by editing data, and each condition can be tested on its own.
class HandPosture {
  const HandPosture({
    required this.id,
    required this.emoji,
    required this.fingers,
    this.thumbExtended,
    this.thumbTouches,
    this.indexMiddleApart,
  });

  /// Fingertips closer than this, in palm widths, count as pinched together.
  ///
  /// Tight, because a thumb resting against curled fingers is common and should
  /// not read as a deliberate pinch.
  static const double contactGap = 0.35;

  /// Index and middle tips further apart than this count as spread.
  static const double spreadGap = 0.7;

  /// Stable key, stored with results.
  final String id;

  /// Shown to the patient alongside the written instruction. Not a substitute
  /// for the instruction — several of these postures have no good emoji.
  final String emoji;

  /// Exactly which of the four fingers must be straight.
  final Set<Finger> fingers;

  /// Whether the thumb must be out or tucked. `null` means it does not matter.
  ///
  /// Most of these postures are performed with the thumb in whatever position
  /// is comfortable, and insisting on one would fail people for something the
  /// task never asked of them.
  final bool? thumbExtended;

  /// A fingertip the thumb must be pinched against, for ring shapes.
  final Finger? thumbTouches;

  /// Whether index and middle must be spread apart. `null` means it does not
  /// matter, which is the case unless both are extended.
  final bool? indexMiddleApart;

  /// Whether [shape] is this posture.
  bool matches(HandShape shape) {
    if (!_sameFingers(shape.extended, fingers)) return false;

    if (thumbExtended != null && shape.thumbExtended != thumbExtended) {
      return false;
    }

    // A ring shape is defined by the contact, so it has to be the right one.
    if (thumbTouches != null && shape.thumbTouching != thumbTouches) {
      return false;
    }

    // There is deliberately no converse rule rejecting an *unintended* pinch.
    // A thumb tucked into a fist genuinely lies across the curled fingertips,
    // so "the thumb is near a fingertip" is anatomy rather than intent, and
    // rejecting on it failed ordinary fists and V-signs. Nothing is lost:
    // no two postures in the catalogue differ only by a thumb contact — the
    // finger set already separates them — so the contact is only ever needed
    // as a positive requirement.

    if (indexMiddleApart != null &&
        shape.indexMiddleApart != indexMiddleApart) {
      return false;
    }

    return true;
  }

  static bool _sameFingers(Set<Finger> a, Set<Finger> b) =>
      a.length == b.length && a.containsAll(b);
}

/// The postures the test asks for.
///
/// # These are provisional
///
/// They are a clearly-distinguishable set chosen to exercise the whole range of
/// finger differentiation — one finger, two adjacent, two separated, opposition,
/// and a closed fist. They are **not** transcribed from a specific printed form;
/// the scan they were drawn from is not legible enough to be certain of several
/// items. Correct them against the paper sheet before using results for
/// anything, and note that doing so is a data edit here, not a code change.
abstract final class HandPostures {
  static const HandPosture point = HandPosture(
    id: 'point',
    emoji: '☝️',
    fingers: <Finger>{Finger.indexFinger},
  );

  static const HandPosture openPalm = HandPosture(
    id: 'open_palm',
    emoji: '🖐️',
    fingers: <Finger>{
      Finger.indexFinger,
      Finger.middle,
      Finger.ring,
      Finger.pinky,
    },
    // Thumb deliberately unconstrained: no other posture has all four fingers
    // out, so nothing is gained by failing someone who tucks it.
  );

  static const HandPosture fist = HandPosture(
    id: 'fist',
    emoji: '✊',
    fingers: <Finger>{},
    thumbExtended: false,
  );

  static const HandPosture victory = HandPosture(
    id: 'victory',
    emoji: '✌️',
    fingers: <Finger>{Finger.indexFinger, Finger.middle},
    indexMiddleApart: true,
  );

  static const HandPosture twoTogether = HandPosture(
    id: 'two_together',
    emoji: '🤞',
    fingers: <Finger>{Finger.indexFinger, Finger.middle},
    indexMiddleApart: false,
  );

  /// Index and pinky out, thumb tucked.
  ///
  /// The thumb condition is what separates this from [iLoveYou], which is the
  /// same two fingers with the thumb held out. Without it the two postures are
  /// the same shape and whichever came first in the catalogue would swallow the
  /// other.
  static const HandPosture horns = HandPosture(
    id: 'horns',
    emoji: '🤘',
    fingers: <Finger>{Finger.indexFinger, Finger.pinky},
    thumbExtended: false,
  );

  static const HandPosture shaka = HandPosture(
    id: 'shaka',
    emoji: '🤙',
    fingers: <Finger>{Finger.pinky},
    thumbExtended: true,
  );

  static const HandPosture okRing = HandPosture(
    id: 'ok_ring',
    emoji: '👌',
    fingers: <Finger>{Finger.middle, Finger.ring, Finger.pinky},
    thumbTouches: Finger.indexFinger,
  );

  static const HandPosture iLoveYou = HandPosture(
    id: 'i_love_you',
    emoji: '🤟',
    fingers: <Finger>{Finger.indexFinger, Finger.pinky},
    thumbExtended: true,
  );

  static const HandPosture threeFingers = HandPosture(
    id: 'three_fingers',
    emoji: '🖖',
    fingers: <Finger>{Finger.indexFinger, Finger.middle, Finger.ring},
  );

  /// The protocol order. Nine postures, two trials each, eighteen points.
  ///
  /// [threeFingers] was dropped from the run: holding the ring finger up
  /// with the pinky folded is too hard for most patients to copy. It stays
  /// defined so results saved before the change still show its emoji.
  static const List<HandPosture> all = <HandPosture>[
    point,
    openPalm,
    fist,
    victory,
    twoTogether,
    horns,
    shaka,
    okRing,
    iLoveYou,
  ];

  /// Trials allowed per posture, matching the two rows the paper form gives
  /// each item.
  static const int trialsPerPosture = 2;

  /// Points for a posture copied on the first trial; one fewer on the second.
  static const int pointsForFirstTrial = 2;

  static int get maximumScore => all.length * pointsForFirstTrial;
}
