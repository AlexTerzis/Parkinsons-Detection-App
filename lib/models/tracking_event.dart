import 'landmark_point.dart';

/// What the detector produced for one processed camera frame, relative to the
/// hand a task is currently examining.
///
/// Every frame the camera delivers lands in exactly one of these, which is the
/// point: an earlier version of the pipeline simply dropped frames with no
/// hand in them, so "the hand was out of view for eight seconds" and "the hand
/// was held perfectly still for eight seconds" produced identical records. The
/// denominators used for coverage, effective frame rate and confidence were
/// therefore computed over the frames that happened to succeed, which made
/// quality look best exactly when the recording was emptiest.
enum TrackingState {
  /// The examined hand, complete, inside the frame, confidently classified.
  tracked,

  /// The examined hand, but the detector's Left/Right call was marginal.
  ///
  /// No longer produced since hands are assigned by position (protocol
  /// version 4); kept so older stored recordings still parse.
  ///
  /// Landmarks are kept: discarding them would open gaps in the signal that
  /// the cycle analyzer reads as hesitations. They are counted separately so
  /// quality validation can weigh them.
  lowConfidence,

  /// The examined hand, but at least one landmark fell outside the frame.
  ///
  /// Kept for the same reason, but amplitude measured from a clipped hand is
  /// an underestimate, so this is worth telling the patient about.
  partiallyOutOfFrame,

  /// A hand arrived with fewer than the expected 21 landmarks.
  incompleteLandmarks,

  /// Hands were visible, but none of them was the hand under examination.
  ///
  /// No longer produced since hands are assigned by position; kept for older
  /// stored recordings.
  wrongHand,

  /// The detector found no hand at all in this frame.
  noHand,
}

extension TrackingStateInfo on TrackingState {
  /// Whether this frame contributed landmarks to the recorded signal.
  ///
  /// The three "hand was there, imperfectly" states do; the three "no usable
  /// hand" states do not.
  bool get contributesLandmarks =>
      this == TrackingState.tracked ||
      this == TrackingState.lowConfidence ||
      this == TrackingState.partiallyOutOfFrame;

  /// Whether this frame was clean on every dimension checked.
  bool get isFullQuality => this == TrackingState.tracked;

  /// Whether the examined hand was seen at all, however imperfectly.
  bool get sawTargetHand =>
      contributesLandmarks || this == TrackingState.incompleteLandmarks;
}

/// The accounting record for one processed frame: when, and in what state.
///
/// Deliberately holds no landmarks. The landmark-bearing frames are stored once
/// as `TaggedFrame`s; duplicating them here would double the size of every
/// uploaded segment for no gain.
class TrackingSample {
  const TrackingSample({required this.timestamp, required this.state});

  /// Milliseconds since epoch, as reported when the frame was processed.
  final int timestamp;

  final TrackingState state;

  Map<String, dynamic> toJson() => <String, dynamic>{
        't': timestamp,
        'state': state.name,
      };

  static TrackingSample fromJson(Map<String, dynamic> json) => TrackingSample(
        timestamp: (json['t'] as num?)?.toInt() ?? 0,
        state: TrackingState.values.firstWhere(
          (s) => s.name == json['state'],
          orElse: () => TrackingState.noHand,
        ),
      );
}

/// A classified frame, together with its landmarks when it had usable ones.
class TrackingEvent {
  const TrackingEvent({
    required this.timestamp,
    required this.state,
    this.landmarks,
    this.handednessConfidence,
    this.handCount = 0,
  });

  final int timestamp;
  final TrackingState state;

  /// The 21 landmarks of the examined hand, or `null` when this frame carried
  /// none. Never an empty list standing in for missing data.
  final List<LandmarkPoint>? landmarks;

  /// The detector's confidence in its Left/Right call, or `null` when the
  /// native layer did not report one.
  ///
  /// `null` means unknown, not zero. A build without the score must not have
  /// every frame classified as low confidence.
  final double? handednessConfidence;

  /// How many hands the detector saw in this frame, of any handedness.
  final int handCount;

  TrackingSample get sample =>
      TrackingSample(timestamp: timestamp, state: state);
}
