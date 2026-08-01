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

/// How long the whole protocol runs.
enum CameraTestMode {
  /// The full protocol: 3s rest plus three 10s movements, per hand.
  full,

  /// Roughly half the durations, for patients who cannot sustain the full run.
  short,
}

/// One timed step of the protocol: a single movement, on a single hand.
class CameraTask {
  const CameraTask({
    required this.id,
    required this.type,
    required this.hand,
    required this.duration,
  });

  /// Stable identifier used as the Firestore/Storage key for this task's
  /// segment, e.g. `right_openClose`. Deliberately independent of the task's
  /// position in the sequence so short and full runs share the same keys.
  final String id;

  final CameraTaskType type;

  /// `'Left'` or `'Right'`, matching `LandmarkData.handedness` so frames can be
  /// filtered to the hand under examination.
  final String hand;

  final Duration duration;

  String? get mdsUpdrsItem => type.mdsUpdrsItem;

  bool get isScored => type.isScored;
}

/// Builds the ordered task list for a run.
class CameraTaskProtocol {
  const CameraTaskProtocol._();

  /// Full-length durations. Short mode halves these, with a floor (see [build]).
  static const Duration restDuration = Duration(seconds: 3);
  static const Duration movementDuration = Duration(seconds: 10);

  /// Shortening never goes below this, because a window of a couple of seconds
  /// yields too few frames for the variance metrics to mean anything.
  static const Duration minimumDuration = Duration(seconds: 2);

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

  static Duration _durationFor(CameraTaskType type, CameraTestMode mode) {
    final Duration full = type == CameraTaskType.rest
        ? restDuration
        : movementDuration;
    if (mode == CameraTestMode.full) return full;

    final int halved = full.inSeconds ~/ 2;
    return Duration(
      seconds: halved < minimumDuration.inSeconds
          ? minimumDuration.inSeconds
          : halved,
    );
  }

  /// The ordered protocol for [mode].
  static List<CameraTask> build(CameraTestMode mode) {
    final tasks = <CameraTask>[];
    for (final hand in hands) {
      for (final type in _perHandOrder) {
        tasks.add(CameraTask(
          id: '${hand.toLowerCase()}_${type.name}',
          type: type,
          hand: hand,
          duration: _durationFor(type, mode),
        ));
      }
    }
    return tasks;
  }

  /// Total wall-clock length of [mode], excluding any time spent paused.
  static Duration totalDuration(CameraTestMode mode) => build(mode).fold(
        Duration.zero,
        (sum, task) => sum + task.duration,
      );
}
