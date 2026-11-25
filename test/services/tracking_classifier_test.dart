import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/frame_data.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/models/tracking_event.dart';
import 'package:parkinsondetetion/services/tracking_classifier.dart';

/// 21 landmarks centred on ([x], [y]), comfortably inside the frame.
List<LandmarkPoint> _points({
  int count = 21,
  double x = 0.5,
  double y = 0.5,
}) =>
    List<LandmarkPoint>.generate(
      count,
      (i) => LandmarkPoint(x: x, y: y + i * 0.001, z: 0),
    );

LandmarkData _hand({
  double x = 0.5,
  String label = 'Right',
  List<LandmarkPoint>? landmarks,
}) =>
    LandmarkData(
      handedness: label,
      landmarks: landmarks ?? _points(x: x),
    );

FrameData _frame(List<LandmarkData> hands, {int t = 1000}) =>
    FrameData(timestamp: t, hands: hands);

void main() {
  const classifier = TrackingClassifier();

  group('HandAssignment', () {
    test('with two hands, the rightmost in the picture is the right hand', () {
      final left = _hand(x: 0.25, label: 'Right');
      final right = _hand(x: 0.75, label: 'Right');
      final assigned =
          HandAssignment.assign(_frame([right, left]), ['Right', 'Left']);

      expect(assigned['Right'], same(right));
      expect(assigned['Left'], same(left));
    });

    test('labels are ignored — even when both say the same side', () {
      final a = _hand(x: 0.2, label: 'Left');
      final b = _hand(x: 0.8, label: 'Left');
      final assigned = HandAssignment.assign(_frame([a, b]), ['Right', 'Left']);

      expect(assigned['Right'], same(b));
      expect(assigned['Left'], same(a));
    });

    test('a one-hand step picks the hand on its own side when two are seen',
        () {
      final resting = _hand(x: 0.3);
      final moving = _hand(x: 0.7);
      final frame = _frame([resting, moving]);

      expect(HandAssignment.assign(frame, ['Right'])['Right'], same(moving));
      expect(HandAssignment.assign(frame, ['Left'])['Left'], same(resting));
    });

    test('a one-hand step takes a lone hand wherever it is', () {
      final only = _hand(x: 0.2, label: 'Left');
      expect(HandAssignment.assign(_frame([only]), ['Right'])['Right'],
          same(only));
    });

    test('a lone hand in a both-hands step goes to the side it is on', () {
      final only = _hand(x: 0.8);
      final assigned =
          HandAssignment.assign(_frame([only]), ['Right', 'Left']);

      expect(assigned['Right'], same(only));
      expect(assigned['Left'], isNull);
    });
  });

  group('TrackingClassifier', () {
    TrackingEvent classify(FrameData frame, {String hand = 'Right'}) =>
        classifier.classify(frame: frame, targetHand: hand);

    test('a clean detection is tracked', () {
      final event = classify(_frame([_hand()]));

      expect(event.state, TrackingState.tracked);
      expect(event.landmarks, isNotNull);
    });

    test('an empty frame is recorded as noHand, not discarded', () {
      final event = classify(_frame(const []));

      expect(event.state, TrackingState.noHand);
      expect(event.landmarks, isNull);
      expect(event.timestamp, 1000);
    });

    test('a short landmark list is incompleteLandmarks', () {
      final event = classify(_frame([_hand(landmarks: _points(count: 5))]));
      expect(event.state, TrackingState.incompleteLandmarks);
      expect(event.landmarks, isNull);
    });

    test('a landmark past the frame edge is partiallyOutOfFrame', () {
      final points = _points()
        ..[8] = const LandmarkPoint(x: 1.2, y: 0.5, z: 0);
      final event = classify(_frame([_hand(landmarks: points)]));

      expect(event.state, TrackingState.partiallyOutOfFrame);
      expect(event.landmarks, isNotNull,
          reason: 'clipped frames still carry signal');
    });

    test('a landmark just over the boundary is still tracked', () {
      final points = _points()
        ..[8] = const LandmarkPoint(x: 1.05, y: 0.5, z: 0);
      expect(classify(_frame([_hand(landmarks: points)])).state,
          TrackingState.tracked);
    });

    test('both hands of a two-hand step get their own event', () {
      final events = classifier.classifyAll(
        frame: _frame([_hand(x: 0.3), _hand(x: 0.7)]),
        targetHands: ['Right', 'Left'],
      );

      expect(events['Right']!.state, TrackingState.tracked);
      expect(events['Left']!.state, TrackingState.tracked);
      expect(events['Right']!.landmarks!.first.x, 0.7);
      expect(events['Left']!.landmarks!.first.x, 0.3);
    });

    test('a missing hand of a two-hand step is noHand', () {
      final events = classifier.classifyAll(
        frame: _frame([_hand(x: 0.7)]),
        targetHands: ['Right', 'Left'],
      );

      expect(events['Right']!.state, TrackingState.tracked);
      expect(events['Left']!.state, TrackingState.noHand);
    });
  });

  group('TrackingState', () {
    test('only the three hand-present states contribute landmarks', () {
      expect(TrackingState.tracked.contributesLandmarks, isTrue);
      expect(TrackingState.lowConfidence.contributesLandmarks, isTrue);
      expect(TrackingState.partiallyOutOfFrame.contributesLandmarks, isTrue);
      expect(TrackingState.incompleteLandmarks.contributesLandmarks, isFalse);
      expect(TrackingState.wrongHand.contributesLandmarks, isFalse);
      expect(TrackingState.noHand.contributesLandmarks, isFalse);
    });
  });
}
