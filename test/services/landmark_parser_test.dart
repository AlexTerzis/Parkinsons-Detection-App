import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/services/landmark_parser.dart';

Map<String, dynamic> _point(double x, double y) =>
    <String, dynamic>{'x': x, 'y': y, 'z': 0.0};

List<Map<String, dynamic>> _points(int count) =>
    List<Map<String, dynamic>>.generate(count, (i) => _point(0.5, i / 100));

void main() {
  const parser = LandmarkParser();

  group('LandmarkParser', () {
    test('reads handedness, landmarks and the confidence score', () {
      final hands = parser.parseHands(<dynamic>[
        <String, dynamic>{
          'handedness': 'Right',
          'handednessScore': 0.93,
          'landmarks': _points(21),
        },
      ]);

      expect(hands, hasLength(1));
      expect(hands.first.handedness, 'Right');
      expect(hands.first.landmarks, hasLength(21));
      expect(hands.first.handednessConfidence, closeTo(0.93, 1e-9));
    });

    test('a missing confidence score parses as null, never as zero', () {
      // Older native builds send no score. Zero would mean "certainly wrong",
      // which is a different claim from "not reported".
      final hands = parser.parseHands(<dynamic>[
        <String, dynamic>{
          'handedness': 'Left',
          'landmarks': _points(21),
        },
      ]);

      expect(hands.first.handednessConfidence, isNull);
    });

    test('keeps a short landmark list rather than dropping the hand', () {
      // Classification decides what a frame was worth; the parser must not
      // quietly erase the evidence that a frame arrived malformed.
      final hands = parser.parseHands(<dynamic>[
        <String, dynamic>{'handedness': 'Right', 'landmarks': _points(9)},
      ]);

      expect(hands, hasLength(1));
      expect(hands.first.landmarks, hasLength(9));
    });

    test('an empty payload yields no hands without throwing', () {
      expect(parser.parseHands(<dynamic>[]), isEmpty);
    });

    test('survives malformed entries at the channel boundary', () {
      final hands = parser.parseHands(<dynamic>[
        'not a map',
        <String, dynamic>{'handedness': 'Right'},
        <String, dynamic>{'landmarks': 'not a list'},
        <String, dynamic>{'handedness': 'Left', 'landmarks': _points(21)},
      ]);

      expect(hands, hasLength(1));
      expect(hands.first.handedness, 'Left');
    });

    test('missing coordinates default to zero rather than throwing', () {
      final hands = parser.parseHands(<dynamic>[
        <String, dynamic>{
          'handedness': 'Right',
          'landmarks': <dynamic>[
            <String, dynamic>{'x': 0.4},
          ],
        },
      ]);

      expect(hands.first.landmarks.single.x, closeTo(0.4, 1e-9));
      expect(hands.first.landmarks.single.y, 0);
    });

    test('two hands with the same label are both kept', () {
      // MediaPipe often labels both raised hands the same side; the test tells
      // them apart by position, so neither may be dropped here.
      final hands = parser.parseHands(<dynamic>[
        <String, dynamic>{'handedness': 'Right', 'landmarks': _points(21)},
        <String, dynamic>{'handedness': 'Right', 'landmarks': _points(5)},
      ]);

      expect(hands, hasLength(2));
    });

    test('a frame payload carries the capture timestamp', () {
      final frame = parser.parseFrame(<String, dynamic>{
        'timestampMs': 12345,
        'hands': <dynamic>[
          <String, dynamic>{'handedness': 'Left', 'landmarks': _points(21)},
        ],
      }, fallbackTimestamp: 1);

      expect(frame.timestamp, 12345);
      expect(frame.hands, hasLength(1));
    });

    test('a bare list from an older native build still parses', () {
      final frame = parser.parseFrame(<dynamic>[
        <String, dynamic>{'handedness': 'Left', 'landmarks': _points(21)},
      ], fallbackTimestamp: 99);

      expect(frame.timestamp, 99);
      expect(frame.hands, hasLength(1));
    });
  });
}
