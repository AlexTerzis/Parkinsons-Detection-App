/// Guided task protocol for the camera-based hand assessment.
///
/// The tasks mirror the hand items of the MDS-UPDRS Part III motor examination,
/// which is the standard clinical rating scale for Parkinson's disease. Each
/// item is examined **one hand at a time**, which is why the protocol below is
/// built per hand rather than asking the patient to move both at once:
///
/// * Item 3.4 — Finger tapping (thumb to index finger, as big and as fast as
///   possible)
/// * Item 3.5 — Hand movements (open and close the fist)
/// * Item 3.6 — Pronation/supination movements of the hands
///
/// A short rest period opens each hand's block. It is not scored as a movement
/// task; it provides a resting baseline against which the movement tasks are
/// read, and it gives the patient a moment to settle before the timer starts.
///
/// Reference: Goetz CG et al., "Movement Disorder Society-Sponsored Revision of
/// the Unified Parkinson's Disease Rating Scale (MDS-UPDRS)", Mov Disord 2008.
///
/// Note that this app does **not** produce an MDS-UPDRS score. The item numbers
/// describe which movement the patient is asked to perform, so that recordings
/// are comparable with the clinical protocol; scoring remains the app's own
/// weighted metric (see `ParkinsonConfig`).
library;

/// The movements a patient is asked to perform, in protocol order.
enum CameraTaskType {
  /// Hand held still and relaxed. Baseline only, never scored as movement.
  rest,

  /// MDS-UPDRS item 3.5 — open and close the fist repeatedly.
  openClose,

  /// MDS-UPDRS item 3.4 — tap thumb against index finger repeatedly.
  fingerTap,

  /// MDS-UPDRS item 3.6 — rotate the forearm palm-up to palm-down.
  pronationSupination,
}

extension CameraTaskTypeInfo on CameraTaskType {
  /// The MDS-UPDRS Part III item this task corresponds to, or `null` for rest,
  /// which is a baseline rather than a rated item.
  String? get mdsUpdrsItem {
    switch (this) {
      case CameraTaskType.rest:
        return null;
      case CameraTaskType.openClose:
        return '3.5';
      case CameraTaskType.fingerTap:
        return '3.4';
      case CameraTaskType.pronationSupination:
        return '3.6';
    }
  }

  /// Whether this task's frames feed the movement score.
  bool get isScored => this != CameraTaskType.rest;
}

/// How the protocol is run.
enum CameraTestMode {
  /// One hand at a time, unhurried, with a countdown before each movement.
  ///
  /// The clinically faithful form: MDS-UPDRS examines each hand separately, and
  /// separating them is also what makes the left-versus-right comparison mean
  /// anything. It takes a couple of minutes, deliberately — a patient who feels
  /// rushed performs worse in ways that look like the signs being measured.
  full,

  /// Both hands in view together, for a quicker run.
  ///
  /// Halves the number of steps by recording both hands at once. The trade-off
  /// is real and worth stating: each hand is smaller in the frame, so landmark
  /// precision drops; the hands can occlude one another; and performing a
  /// movement with both hands simultaneously is not the same task as performing
  /// it with one, so results are not directly comparable with a full run.
  short,
}

/// Who decides when a step starts.
enum CameraPacing {
  /// The patient reads the instruction and taps when ready.
  ///
  /// The default, because the slowest part of this assessment is understanding
  /// what to do, and that is not something to put a stopwatch on. Someone
  /// reading every instruction carefully takes several minutes over the full
  /// protocol; someone who has done it before goes as fast as they like. Only
  /// the recording itself is timed, because comparing one run with another —
  /// and one hand with the other — depends on them being the same length.
  selfPaced,

  /// Each step starts on its own after a countdown.
  ///
  /// For a phone propped out of arm's reach, where tapping between every step
  /// would mean leaning in and disturbing the setup.
  timed,
}

/// One timed step of the protocol.
class CameraTask {
  const CameraTask({
    required this.id,
    required this.type,
    required this.hands,
    required this.duration,
    this.leadIn = Duration.zero,
  });

  /// Stable identifier for the step, e.g. `right_openClose` or `both_openClose`.
  /// Deliberately independent of position in the sequence.
  final String id;

  final CameraTaskType type;

  /// The hands examined in this step: one of them in [CameraTestMode.full],
  /// both in [CameraTestMode.short]. Values match `LandmarkData.handedness`.
  final List<String> hands;

  /// How long frames are recorded for.
  final Duration duration;

  /// The pause before recording starts, during which nothing is kept.
  ///
  /// Serves both pacings: in [CameraPacing.timed] it is the countdown that
  /// auto-starts the step, and in [CameraPacing.selfPaced] it is the short
  /// "get ready" between the patient tapping and the first recorded frame.
  ///
  /// Either way it exists so the patient can get into position and settle
  /// before anything counts. Without it the first second or two of every step
  /// is the patient still arranging their hand, which is recorded as a hesitant
  /// start and measured as delayed initiation.
  final Duration leadIn;

  bool get isBothHands => hands.length > 1;

  String? get mdsUpdrsItem => type.mdsUpdrsItem;

  bool get isScored => type.isScored;

  /// The storage key for one hand's recording of this step.
  ///
  /// Always per hand, even when both were recorded together, so a short run and
  /// a full run produce the same keys and anything reading them stays simple.
  String segmentId(String hand) => '${hand.toLowerCase()}_${type.name}';
}

/// Builds the ordered task list for a run.
class CameraTaskProtocol {
  const CameraTaskProtocol._();

  // --- Full mode: one hand at a time, unhurried ---

  /// Long enough to settle and for a rest tremor to show itself. Rest tremor is
  /// intermittent, and three seconds could easily fall between episodes.
  static const Duration restDuration = Duration(seconds: 6);

  /// Twelve seconds of movement.
  ///
  /// Decrement is the most specific thing measured here, and it is a *trend*
  /// across the task — the more cycles it is fitted over, the less it is
  /// dominated by the first few. Long enough to show fatigue, short enough not
  /// to cause it.
  static const Duration movementDuration = Duration(seconds: 12);

  /// Countdown before each movement starts recording.
  static const Duration movementLeadIn = Duration(seconds: 4);

  /// Countdown before a rest period, which needs less preparation.
  static const Duration restLeadIn = Duration(seconds: 3);

  // --- Short mode: both hands together ---

  static const Duration shortRestDuration = Duration(seconds: 4);
  static const Duration shortMovementDuration = Duration(seconds: 8);
  static const Duration shortLeadIn = Duration(seconds: 3);

  /// Hands are examined right first, then left, and the whole block for one
  /// hand completes before the other starts — switching hands mid-item makes
  /// the instructions much harder to follow.
  static const List<String> hands = <String>['Right', 'Left'];

  static const List<CameraTaskType> _perHandOrder = <CameraTaskType>[
    CameraTaskType.rest,
    CameraTaskType.openClose,
    CameraTaskType.fingerTap,
    CameraTaskType.pronationSupination,
  ];

  /// The ordered protocol for [mode].
  static List<CameraTask> build(CameraTestMode mode) {
    if (mode == CameraTestMode.short) return _buildShort();

    final tasks = <CameraTask>[];
    for (final hand in hands) {
      for (final type in _perHandOrder) {
        final bool isRest = type == CameraTaskType.rest;
        tasks.add(CameraTask(
          id: '${hand.toLowerCase()}_${type.name}',
          type: type,
          hands: <String>[hand],
          duration: isRest ? restDuration : movementDuration,
          leadIn: isRest ? restLeadIn : movementLeadIn,
        ));
      }
    }
    return tasks;
  }

  /// Four steps instead of eight, each recording both hands at once.
  static List<CameraTask> _buildShort() {
    return <CameraTask>[
      for (final type in _perHandOrder)
        CameraTask(
          id: 'both_${type.name}',
          type: type,
          hands: hands,
          duration: type == CameraTaskType.rest
              ? shortRestDuration
              : shortMovementDuration,
          leadIn: shortLeadIn,
        ),
    ];
  }

  /// Total wall-clock length of [mode], counting the countdowns and excluding
  /// any time spent paused.
  static Duration totalDuration(CameraTestMode mode) => build(mode).fold(
        Duration.zero,
        (sum, task) => sum + task.duration + task.leadIn,
      );

  /// Time spent actually recording in [mode].
  static Duration recordedDuration(CameraTestMode mode) => build(mode).fold(
        Duration.zero,
        (sum, task) => sum + task.duration,
      );
}
