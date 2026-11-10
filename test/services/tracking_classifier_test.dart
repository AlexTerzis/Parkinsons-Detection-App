import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/frame_data.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/models/tracking_event.dart';
import 'package:parkinsondetetion/services/tracking_classifier.dart';

/// 21 landmarks comfortably inside the frame.
List<LandmarkPoint> _hand({
  int count = 21,
  double x = 0.5,
  double y = 0.5,
}) =>
    List<LandmarkPoint>.generate(
      count,
      (i) => LandmarkPoint(x: x, y: y + i * 0.001, z: 0),
    );

LandmarkData _right({
  List<LandmarkPoint>? landmarks,
  double? confidence,
  String handedness = 'Right',
}) =>
    LandmarkData(
      handedness: handedness,
      landmarks: landmarks ?? _hand(),
      handednessConfidence: confidence,
    );

FrameData _frame(List<LandmarkData> hands, {int t = 1000}) =>
    FrameData(timestamp: t, hands: hands);

void main() {
  const classifier = TrackingClassifier();

  TrackingEvent classify(FrameData frame, {String hand = 'Right'}) =>
      classifier.classify(frame: frame, targetHand: hand);

  group('TrackingClassifier', () {
    group('every frame lands in exactly one state', () {
      test('a clean detection of the examined hand is tracked', () {
        final event = classify(_frame([_right(confidence: 0.99)]));

        expect(event.state, TrackingState.tracked);
        expect(event.landmarks, isNotNull);
        expect(event.state.isFullQuality, isTrue);
      });

      test('an empty frame is recorded as noHand, not discarded', () {
        final event = classify(_frame(const []));

        expect(event.state, TrackingState.noHand);
        expect(event.landmarks, isNull);
        expect(event.timestamp, 1000);
      });

      test('a hand of the wrong label, alongside another, is wrongHand', () {
        // Two hands in the frame are never ambiguous about which is which, so
        // the labels are taken at their word.
        final event = classify(_frame([
          _right(handedness: 'Left'),
          _right(handedness: 'Unknown'),
        ]));

        expect(event.state, TrackingState.wrongHand);
        expect(event.handCount, 2);
        expect(event.landmarks, isNull);
      });

      test('a lone hand is accepted as the target despite its label', () {
        // The front camera mirrors its frames before the detector sees them, so
        // a right hand is reported as "Left". Rejecting it meant no step of the
        // guided protocol could pass. The instruction the patient was given is
        // better evidence than a label that inverts wholesale.
        final event = classify(_frame([_right(handedness: 'Left')]));

        expect(event.state, TrackingState.lowConfidence,
            reason: 'accepted, but never as a clean detection');
        expect(event.landmarks, isNotNull);
      });

      test('the fallback can be turned off', () {
        const strict = TrackingClassifier(acceptLoneHandAsTarget: false);
        final event = strict.classify(
          frame: _frame([_right(handedness: 'Left')]),
          targetHand: 'Right',
        );

        expect(event.state, TrackingState.wrongHand);
        expect(event.landmarks, isNull);
      });

      test('a short landmark list is incompleteLandmarks', () {
        final event = classify(_frame([_right(landmarks: _hand(count: 12))]));

        expect(event.state, TrackingState.incompleteLandmarks);
        expect(event.landmarks, isNull);
      });

      test('a landmark past the frame edge is partiallyOutOfFrame', () {
        final clipped = _hand()..[8] = const LandmarkPoint(x: 1.4, y: 0.5, z: 0);
        final event = classify(_frame([_right(landmarks: clipped)]));

        expect(event.state, TrackingState.partiallyOutOfFrame);
        // Still carries landmarks: dropping them would open a gap in the
        // signal that reads as a hesitation.
        expect(event.landmarks, isNotNull);
        expect(event.state.contributesLandmarks, isTrue);
      });

      test('a marginal handedness score is lowConfidence', () {
        final event = classify(_frame([_right(confidence: 0.55)]));

        expect(event.state, TrackingState.lowConfidence);
        expect(event.landmarks, isNotNull);
      });
    });

    group('degrading safely', () {
      test('an absent handedness score is not treated as low confidence', () {
        // A build whose native layer predates the score reports null. Treating
        // that as zero would mark every frame of every run as marginal.
        final event = classify(_frame([_right(confidence: null)]));

        expect(event.state, TrackingState.tracked);
        expect(event.handednessConfidence, isNull);
      });

      test('clipping is reported ahead of low confidence', () {
        // The patient can act on "keep the hand in view"; they can do nothing
        // about the classifier being unsure.
        final clipped = _hand()..[0] = const LandmarkPoint(x: -0.3, y: 0.5, z: 0);
        final event = classify(
          _frame([_right(landmarks: clipped, confidence: 0.4)]),
        );

        expect(event.state, TrackingState.partiallyOutOfFrame);
      });

      test('a landmark on the boundary is still fully tracked', () {
        final edge = _hand()..[4] = const LandmarkPoint(x: 1.0, y: 0.5, z: 0);
        final event = classify(_frame([_right(landmarks: edge)]));

        expect(event.state, TrackingState.tracked);
      });
    });

    group('state semantics', () {
      test('only the three hand-present states contribute landmarks', () {
        expect(
          TrackingState.values.where((s) => s.contributesLandmarks),
          unorderedEquals(<TrackingState>[
            TrackingState.tracked,
            TrackingState.lowConfidence,
            TrackingState.partiallyOutOfFrame,
          ]),
        );
      });

      test('only a clean detection counts as full quality', () {
        expect(
          TrackingState.values.where((s) => s.isFullQuality),
          equals(<TrackingState>[TrackingState.tracked]),
        );
      });

      test('wrongHand and noHand did not see the examined hand', () {
        expect(TrackingState.wrongHand.sawTargetHand, isFalse);
        expect(TrackingState.noHand.sawTargetHand, isFalse);
        expect(TrackingState.incompleteLandmarks.sawTargetHand, isTrue);
      });
    });
  });
}
