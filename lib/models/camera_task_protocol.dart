/// Guided task protocol for the camera-based hand assessment.
///
/// The phone is propped up on its side (landscape) about an arm's length away,
/// so both hands fit in the picture at once. The run is hands-free: every step
/// starts on its own after a spoken countdown, and nobody has to touch the
/// phone between steps.
///
/// The movements mirror the hand items of the MDS-UPDRS Part III motor
/// examination, the standard clinical rating scale for Parkinson's disease:
///
/// * Item 3.17 — Rest tremor (both hands resting, still)
/// * Item 3.15 — Postural tremor (both hands raised, palms to the camera)
/// * Item 3.4  — Finger tapping (thumb to index finger, big and fast)
/// * Item 3.5  — Hand movements (open and close the fist)
/// * Item 3.6  — Pronation/supination (turn the palm up and down)
///
/// The two tremor steps record both hands together: nothing is moving, so
/// there is nothing for one hand to hide about the other, and it halves their
/// length. The three movement items are examined one hand at a time, as the
/// scale requires — the right hand's three, then the left hand's three, with
/// the resting hand kept down on the table out of the way.
///
/// Two poses differ from the clinical examination because the camera is in
/// front of the patient rather than beside them. Postural tremor is held with
/// the hands raised and palms to the camera, not arms stretched forward: with
/// the fingers pointing at the lens the hand is foreshortened and detected
/// poorly. Pronation/supination is done with the elbow on the table and the
/// hand upright, turning palm to camera and back: the roll is measured about
/// the forearm, which cannot be done when the forearm points at the lens.
///
/// Reference: Goetz CG et al., "Movement Disorder Society-Sponsored Revision of
/// the Unified Parkinson's Disease Rating Scale (MDS-UPDRS)", Mov Disord 2008.
///
/// The app's ratings follow the scale's 0-4 structure but are produced by an
/// automated, uncalibrated rule set — see `MotorRatingScorer`. They are not an
/// examiner's MDS-UPDRS score.
library;

/// The movements a patient is asked to perform.
enum CameraTaskType {
  /// Both hands resting and relaxed. Rest-tremor baseline, no movement.
  rest,

  /// Both hands raised, palms to the camera, fingers spread. Postural
  /// tremor, no movement.
  posture,

  /// MDS-UPDRS item 3.4 — tap thumb against index finger repeatedly.
  fingerTap,

  /// MDS-UPDRS item 3.5 — open and close the fist repeatedly.
  openClose,

  /// MDS-UPDRS item 3.6 — rotate the forearm palm-up to palm-down.
  pronationSupination,
}

extension CameraTaskTypeInfo on CameraTaskType {
  /// The MDS-UPDRS Part III item this task corresponds to.
  String get mdsUpdrsItem {
    switch (this) {
      case CameraTaskType.rest:
        return '3.17';
      case CameraTaskType.posture:
        return '3.15';
      case CameraTaskType.fingerTap:
        return '3.4';
      case CameraTaskType.openClose:
        return '3.5';
      case CameraTaskType.pronationSupination:
        return '3.6';
    }
  }

  /// Whether this is a repetitive movement, analysed as cycles.
  ///
  /// The two still tasks are analysed for tremor instead.
  bool get isScored =>
      this != CameraTaskType.rest && this != CameraTaskType.posture;

  /// Whether this task is a still hold analysed for tremor.
  bool get isTremor => !isScored;
}

/// One timed step of the protocol.
class CameraTask {
  const CameraTask({
    required this.id,
    required this.type,
    required this.hands,
    required this.duration,
    this.leadIn = Duration.zero,
    this.switchesHand = false,
  });

  /// Stable identifier for the step, e.g. `right_openClose` or `both_rest`.
  final String id;

  final CameraTaskType type;

  /// The hands examined in this step. Values match `'Left'` / `'Right'`.
  final List<String> hands;

  /// How long frames are recorded for.
  final Duration duration;

  /// The spoken countdown before recording starts, during which nothing is
  /// kept. Gives the patient time to get into position, so the first seconds of
  /// the step are not them arranging their hand — which would otherwise be
  /// measured as a hesitant start.
  final Duration leadIn;

  /// True for the first step of a hand's block, which is announced as a hand
  /// change and given a longer countdown.
  final bool switchesHand;

  bool get isBothHands => hands.length > 1;

  String get mdsUpdrsItem => type.mdsUpdrsItem;

  bool get isScored => type.isScored;

  /// The storage key for one hand's recording of this step.
  String segmentId(String hand) => '${hand.toLowerCase()}_${type.name}';
}

/// Builds the ordered task list for a run.
class CameraTaskProtocol {
  const CameraTaskProtocol._();

  /// Long enough for an intermittent rest tremor to show itself, and for a
  /// frequency estimate over many oscillations.
  static const Duration tremorDuration = Duration(seconds: 10);

  /// Ten seconds of each movement.
  ///
  /// Decrement is a trend across the task, so it needs enough cycles to fit;
  /// ten seconds gives 20-40 taps for a typical tapper. Long enough to show
  /// fatigue, short enough not to cause it.
  static const Duration movementDuration = Duration(seconds: 10);

  /// Countdown before an ordinary step.
  static const Duration leadIn = Duration(seconds: 5);

  /// Countdown before the first step, and before each change of hand: the
  /// patient may have to sit back from the phone or put the other hand down.
  static const Duration longLeadIn = Duration(seconds: 8);

  /// The right hand is examined first, then the left.
  static const List<String> hands = <String>['Right', 'Left'];

  static const List<CameraTaskType> _movementOrder = <CameraTaskType>[
    CameraTaskType.fingerTap,
    CameraTaskType.openClose,
    CameraTaskType.pronationSupination,
  ];

  /// The ordered protocol.
  static List<CameraTask> build() {
    return <CameraTask>[
      const CameraTask(
        id: 'both_rest',
        type: CameraTaskType.rest,
        hands: hands,
        duration: tremorDuration,
        leadIn: longLeadIn,
      ),
      const CameraTask(
        id: 'both_posture',
        type: CameraTaskType.posture,
        hands: hands,
        duration: tremorDuration,
        leadIn: leadIn,
      ),
      for (final hand in hands)
        for (int i = 0; i < _movementOrder.length; i++)
          CameraTask(
            id: '${hand.toLowerCase()}_${_movementOrder[i].name}',
            type: _movementOrder[i],
            hands: <String>[hand],
            duration: movementDuration,
            leadIn: i == 0 ? longLeadIn : leadIn,
            switchesHand: i == 0,
          ),
    ];
  }

  /// Total wall-clock length, counting the countdowns.
  static Duration totalDuration() => build().fold(
        Duration.zero,
        (sum, task) => sum + task.duration + task.leadIn,
      );

  /// Time spent actually recording.
  static Duration recordedDuration() => build().fold(
        Duration.zero,
        (sum, task) => sum + task.duration,
      );
}
