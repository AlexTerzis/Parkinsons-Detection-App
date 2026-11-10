import 'hand_posture.dart';

/// How one attempt at a posture ended.
enum PostureOutcome {
  /// The posture was copied and held.
  copied,

  /// A hand was tracked throughout, but never made this shape.
  notCopied,

  /// No usable view of the hand, so nothing can be said either way.
  ///
  /// Kept distinct from [notCopied] on purpose. "You did not make the shape"
  /// and "the camera never saw your hand" look identical in a bare score and
  /// mean completely different things — only one of them is about the patient.
  notRecorded,
}

/// What happened on one attempt at one posture.
class PostureAttempt {
  const PostureAttempt({
    required this.trial,
    required this.outcome,
    required this.usableFrames,
    required this.totalFrames,
    this.secondsTaken,
    this.observedPostureId,
  });

  /// 1 or 2 — the paper form gives each item two rows.
  final int trial;

  final PostureOutcome outcome;

  /// Frames in which the hand was usable, and frames processed in total.
  final int usableFrames;
  final int totalFrames;

  /// Time from the attempt starting to the posture being held, when it was.
  final double? secondsTaken;

  /// The posture actually recognised, when it was one of the others.
  ///
  /// Copying the wrong shape is a different kind of error from making no
  /// recognisable shape at all, and worth keeping.
  final String? observedPostureId;

  double get usableFrameRatio =>
      totalFrames == 0 ? 0 : usableFrames / totalFrames;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'trial': trial,
        'outcome': outcome.name,
        'usableFrames': usableFrames,
        'totalFrames': totalFrames,
        'usableFrameRatio': usableFrameRatio,
        'secondsTaken': secondsTaken,
        'observedPostureId': observedPostureId,
      };
}

/// One posture's result across its attempts.
class PostureItemResult {
  const PostureItemResult({required this.postureId, required this.attempts});

  final String postureId;
  final List<PostureAttempt> attempts;

  /// The trial on which it was copied, or `null` if it never was.
  int? get copiedOnTrial {
    for (final attempt in attempts) {
      if (attempt.outcome == PostureOutcome.copied) return attempt.trial;
    }
    return null;
  }

  /// Two points on the first trial, one on the second, none otherwise.
  int get points {
    final int? trial = copiedOnTrial;
    if (trial == null) return 0;
    return HandPostures.pointsForFirstTrial - (trial - 1);
  }

  /// Whether every attempt failed for want of a usable view of the hand.
  ///
  /// Such an item scores zero, and that zero should not be read as the patient
  /// having failed the task.
  bool get neverRecorded =>
      attempts.isNotEmpty &&
      attempts.every((a) => a.outcome == PostureOutcome.notRecorded);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'postureId': postureId,
        'points': points,
        'copiedOnTrial': copiedOnTrial,
        'neverRecorded': neverRecorded,
        'attempts': attempts.map((a) => a.toJson()).toList(growable: false),
      };
}

/// The whole run.
class PostureTestResult {
  const PostureTestResult({required this.items, required this.performedAt});

  /// Bumped when the stored shape changes.
  static const int protocolVersion = 1;

  final List<PostureItemResult> items;
  final DateTime performedAt;

  int get points => items.fold<int>(0, (sum, item) => sum + item.points);

  int get maximumPoints => HandPostures.maximumScore;

  /// 0-1, where higher is more concerning — the convention `TestResult.score`
  /// stores under schema 2. Copying every posture gives 0.
  double get concern {
    if (maximumPoints == 0) return 0;
    return (1 - points / maximumPoints).clamp(0.0, 1.0);
  }

  /// Items whose zero came from never seeing the hand rather than from the
  /// patient not copying the shape.
  List<PostureItemResult> get unrecordedItems =>
      items.where((i) => i.neverRecorded).toList(growable: false);

  /// Fraction of processed frames across the run in which the hand was usable.
  double get recordingQuality {
    int usable = 0;
    int total = 0;
    for (final item in items) {
      for (final attempt in item.attempts) {
        usable += attempt.usableFrames;
        total += attempt.totalFrames;
      }
    }
    return total == 0 ? 0 : usable / total;
  }

  /// True when enough of the run was actually seen for the score to mean
  /// anything.
  bool get hasUsableRecording =>
      items.isNotEmpty && unrecordedItems.length < items.length;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'protocol_version': protocolVersion,
        'points': points,
        'maximum_points': maximumPoints,
        'recording_quality': recordingQuality,
        'unrecorded_items':
            unrecordedItems.map((i) => i.postureId).toList(growable: false),
        'items': items.map((i) => i.toJson()).toList(growable: false),
      };
}
