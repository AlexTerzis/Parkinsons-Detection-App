import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/models/camera_task_segment.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/services/scoring/camera_recording.dart';
import 'package:parkinsondetetion/services/scoring/movement_cycle_analyzer.dart';

import 'synthetic_recording.dart';

const double _palm = 0.10;

/// One frame of a hand whose palm is rolled by [roll] radians about the
/// forearm, with the whole hand additionally rotated by [inPlane] radians
/// within the image plane.
///
/// The two are independent on purpose: [roll] is the movement item 3.6 asks
/// for, [inPlane] is the patient tilting their wrist without turning the palm
/// over. A signal that cannot tell them apart measures the second as the first.
List<LandmarkPoint> _frame({
  double roll = 0,
  double inPlane = 0,
  double depth = 1,
  bool mirrored = false,
}) {
  const double r = _palm / 2;
  final points = List<LandmarkPoint>.generate(
    21,
    (_) => const LandmarkPoint(x: 0.5, y: 0.5, z: 0),
  );

  // A left hand is the mirror image of a right one, so its index and pinky
  // knuckles sit on opposite sides of the forearm from the right hand's. That
  // mirroring is exactly what the analyzer's handedness correction exists to
  // undo, so a fixture that skipped it could not exercise the correction.
  final double side = mirrored ? -1.0 : 1.0;

  // Local coordinates about the wrist, before the in-plane rotation.
  final local = <int, List<double>>{
    0: <double>[0, 0, 0],
    9: <double>[0, -_palm, 0],
    5: <double>[
      side * r * math.cos(roll),
      -_palm,
      side * r * math.sin(roll) * depth,
    ],
    17: <double>[
      -side * r * math.cos(roll),
      -_palm,
      -side * r * math.sin(roll) * depth,
    ],
  };

  final double c = math.cos(inPlane);
  final double s = math.sin(inPlane);

  local.forEach((index, v) {
    // Rotate x/y about the wrist; depth is untouched by an image-plane turn.
    points[index] = LandmarkPoint(
      x: 0.5 + v[0] * c - v[1] * s,
      y: 0.5 + v[0] * s + v[1] * c,
      z: v[2],
    );
  });

  return points;
}

RecordedTask _task(
  List<List<LandmarkPoint>> frames, {
  String hand = 'Right',
}) {
  return RecordedTask(
    taskId: '${hand.toLowerCase()}_pronationSupination',
    type: CameraTaskType.pronationSupination,
    hand: hand,
    plannedDuration: const Duration(seconds: 10),
    frames: <TaggedFrame>[
      for (int i = 0; i < frames.length; i++)
        TaggedFrame(
          taskId: '${hand.toLowerCase()}_pronationSupination',
          hand: hand,
          timestamp: i * 33,
          landmarks: frames[i],
        ),
    ],
  );
}

/// Peak-to-peak span of a signal.
double _span(List<double> signal) {
  double lo = signal.first, hi = signal.first;
  for (final v in signal) {
    lo = math.min(lo, v);
    hi = math.max(hi, v);
  }
  return hi - lo;
}

void main() {
  const analyzer = MovementCycleAnalyzer();

  group('palm rotation signal', () {
    test('reads a real roll of the palm', () {
      final frames = <List<LandmarkPoint>>[
        for (int i = 0; i < 300; i++)
          _frame(roll: math.pi * 0.5 * (1 - math.cos(2 * math.pi * 2 * i / 30))),
      ];

      final signal = analyzer.cycleSignalFor(_task(frames));

      expect(signal, isNotEmpty);
      expect(_span(signal), greaterThan(0.5),
          reason: 'a half-turn should span about 1 in half-turn units');
    });

    test('a hand tilted in the image plane is not read as rotating', () {
      // The fault in the old horizontal-difference signal. The palm never turns
      // over here; only the wrist tilts. Anything the signal shows is spurious.
      final frames = <List<LandmarkPoint>>[
        for (int i = 0; i < 300; i++)
          _frame(
            roll: 0.6,
            inPlane: math.pi * 0.4 * math.sin(2 * math.pi * 2 * i / 30),
          ),
      ];

      final signal = analyzer.cycleSignalFor(_task(frames));
      final metrics = analyzer.analyze(_task(frames));

      expect(_span(signal), lessThan(0.05),
          reason: 'in-plane tilt must not appear as roll');
      expect(metrics.cycleCount, 0,
          reason: 'no palm rotation happened, so no cycles should be counted');
    });

    test('both hands measure the same physical movement identically', () {
      List<List<LandmarkPoint>> turning() => <List<LandmarkPoint>>[
            for (int i = 0; i < 300; i++)
              _frame(
                roll: math.pi *
                    0.5 *
                    (1 - math.cos(2 * math.pi * 2 * i / 30)),
              ),
          ];

      final right = analyzer.analyze(_task(turning(), hand: 'Right'));
      final left = analyzer.analyze(_task(turning(), hand: 'Left'));

      expect(left.cycleCount, right.cycleCount);
      expect(left.rateHz, closeTo(right.rateHz!, 1e-9));
      expect(left.meanAmplitude, closeTo(right.meanAmplitude!, 1e-9));
    });

    test('mirrored anatomy changes no measurement', () {
      // A left hand is the mirror of a right one, so the same movement yields
      // an angle reflected and offset by pi. No handedness correction is
      // applied, because every metric taken from the signal is invariant to
      // both — which is what this pins.
      List<List<LandmarkPoint>> turning({required bool mirrored}) =>
          <List<LandmarkPoint>>[
            for (int i = 0; i < 300; i++)
              _frame(
                roll: math.pi *
                    0.5 *
                    (1 - math.cos(2 * math.pi * 2 * i / 30)),
                mirrored: mirrored,
              ),
          ];

      final right =
          analyzer.analyze(_task(turning(mirrored: false), hand: 'Right'));
      final left =
          analyzer.analyze(_task(turning(mirrored: true), hand: 'Left'));

      expect(left.cycleCount, right.cycleCount);
      expect(left.rateHz, closeTo(right.rateHz!, 1e-9));
      expect(left.meanAmplitude, closeTo(right.meanAmplitude!, 1e-9));
      expect(left.rhythmVariability, closeTo(right.rhythmVariability!, 1e-9));
    });

    test('is unaffected by how near the hand is to the lens', () {
      List<List<LandmarkPoint>> turning(double scale) => <List<LandmarkPoint>>[
            for (int i = 0; i < 300; i++)
              _frame(
                roll: math.pi *
                    0.5 *
                    (1 - math.cos(2 * math.pi * 2 * i / 30)),
              ).map((p) => LandmarkPoint(
                    x: p.x * scale,
                    y: p.y * scale,
                    z: p.z * scale,
                  )).toList(),
          ];

      final near = analyzer.analyze(_task(turning(1.6)));
      final far = analyzer.analyze(_task(turning(1.0)));

      expect(near.cycleCount, far.cycleCount);
      expect(near.meanAmplitude, closeTo(far.meanAmplitude!, 1e-6));
    });

    test('an angle passing through the wrap boundary stays continuous', () {
      // A turn through +-pi would otherwise jump by 2*pi and register as an
      // enormous spurious movement.
      final frames = <List<LandmarkPoint>>[
        for (int i = 0; i < 120; i++) _frame(roll: -math.pi + i * 0.05),
      ];

      final signal = analyzer.cycleSignalFor(_task(frames));

      double biggestStep = 0;
      for (int i = 1; i < signal.length; i++) {
        biggestStep = math.max(biggestStep, (signal[i] - signal[i - 1]).abs());
      }

      expect(biggestStep, lessThan(0.2),
          reason: 'no 2*pi discontinuity should survive unwrapping');
    });

    group('depth-less input', () {
      test('falls back rather than reporting rotation from flat landmarks', () {
        // Some builds report z as a constant. Every angle then collapses onto
        // 0 or pi, and a rotation measured from that would be an artefact.
        final frames = <List<LandmarkPoint>>[
          for (int i = 0; i < 300; i++)
            _frame(
              roll: math.pi * 0.5 * (1 - math.cos(2 * math.pi * 2 * i / 30)),
              depth: 0,
            ),
        ];

        final signal = analyzer.cycleSignalFor(_task(frames));

        // The fallback is the older horizontal signal: still a signal, and
        // still honest about the movement's rate, just weaker. It is a cosine
        // of the roll in palm-widths, so it is bounded — unlike the unwrapped
        // angle, which grows without limit as the hand keeps turning.
        expect(signal, isNotEmpty);
        for (final value in signal) {
          expect(value.abs(), lessThanOrEqualTo(1.001),
              reason: 'fallback is a bounded palm-width ratio');
        }
      });

      test('the fallback still counts the movement', () {
        final frames = <List<LandmarkPoint>>[
          for (int i = 0; i < 300; i++)
            _frame(
              roll: math.pi * 0.5 * (1 - math.cos(2 * math.pi * 2 * i / 30)),
              depth: 0,
            ),
        ];

        expect(analyzer.analyze(_task(frames)).cycleCount, greaterThan(0));
      });
    });

    test('still integrates with the synthetic protocol fixtures', () {
      final recording = Synthetic.healthy();
      final rotation = recording.taskFor(
        'Right',
        CameraTaskType.pronationSupination,
      )!;

      final metrics = analyzer.analyze(rotation);

      expect(metrics.cycleCount, greaterThan(0));
      expect(metrics.rateHz, isNotNull);
    });
  });
}
