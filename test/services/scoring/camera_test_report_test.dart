import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/services/scoring/camera_recording.dart';
import 'package:parkinsondetetion/services/scoring/camera_test_report.dart';
import 'package:parkinsondetetion/services/scoring/motor_rating.dart';

import 'synthetic_recording.dart';

void main() {
  const builder = CameraReportBuilder();

  group('CameraReportBuilder', () {
    group('structure', () {
      test('separates results by hand and by task', () {
        final report = builder.build(Synthetic.healthy());

        expect(report.hands.map((h) => h.hand),
            containsAll(<String>['Left', 'Right']));

        for (final hand in report.hands) {
          expect(
            hand.tasks.map((t) => t.type),
            containsAll(<CameraTaskType>[
              CameraTaskType.rest,
              CameraTaskType.posture,
              CameraTaskType.openClose,
              CameraTaskType.fingerTap,
              CameraTaskType.pronationSupination,
            ]),
          );
        }
      });

      test('each task carries its own measurements and its own quality', () {
        final report = builder.build(Synthetic.healthy());
        final tap = report
            .handReport('Right')!
            .taskOf(CameraTaskType.fingerTap)!;

        expect(tap.cycles, isNotNull);
        expect(tap.cycles!.cycleCount, greaterThan(0));
        expect(tap.quality.taskId, tap.taskId);
      });

      test('tremor is measured on the still tasks only', () {
        // The separation of tremor from voluntary movement assumes voluntary
        // movement stays below 4 Hz. Tapping at 5 a second breaks that, so a
        // fast healthy tapper would otherwise measure as a severe tremor.
        final report = builder.build(Synthetic.healthy());
        final hand = report.handReport('Right')!;

        expect(hand.taskOf(CameraTaskType.rest)!.tremor, isNotNull);
        expect(hand.taskOf(CameraTaskType.posture)!.tremor, isNotNull);
        expect(hand.taskOf(CameraTaskType.fingerTap)!.tremor, isNull);
        expect(hand.taskOf(CameraTaskType.openClose)!.tremor, isNull);
      });

      test('rest tasks carry no cycle metrics', () {
        final report = builder.build(Synthetic.healthy());
        final rest =
            report.handReport('Left')!.taskOf(CameraTaskType.rest)!;

        expect(rest.cycles, isNull);
      });
    });

    group('measurements are not invented', () {
      test('too few cycles leaves decrement null, not zero', () {
        // Zero decrement means "the movement held its size". Unmeasurable means
        // "there were too few movements to tell". Collapsing the second into
        // the first turns missing evidence into a reassuring result.
        final recording = CameraRecording(
          tasks: <RecordedTask>[
            Synthetic.task(
              type: CameraTaskType.fingerTap,
              hand: 'Right',
              seconds: 10,
              rateHz: 0.2,
            ),
          ],
        );

        final cycles = builder
            .build(recording)
            .handReport('Right')!
            .cyclesOf(CameraTaskType.fingerTap)!;

        expect(cycles.cycleCount, lessThan(6));
        expect(cycles.amplitudeDecrement, isNull);
        expect(cycles.speedDecrement, isNull);
      });

      test('a hand that produced nothing reports no valid tasks', () {
        final recording = CameraRecording(
          tasks: <RecordedTask>[
            Synthetic.task(
              type: CameraTaskType.fingerTap,
              hand: 'Right',
              seconds: 10,
            ),
          ],
        );

        final report = builder.build(recording);

        expect(report.handReport('Right')!.hasAnyValidTask, isTrue);
        expect(report.handReport('Left')!.hasAnyValidTask, isFalse);
        expect(report.handReport('Left')!.tasks, isEmpty);
      });
    });

    group('confidence', () {
      test('is never the placeholder 1.0 of the old scorer', () {
        final report = builder.build(Synthetic.healthy());

        expect(report.confidence, lessThan(1.0));
        expect(report.confidence, greaterThan(0.0));
      });

      test('a badly recorded run is less trusted than a clean one', () {
        final clean = builder.build(Synthetic.recording(fps: 30));
        final sparse = builder.build(Synthetic.recording(fps: 10));

        expect(sparse.confidence, lessThan(clean.confidence));
      });

      test('is reported per hand as well as overall', () {
        final report = builder.build(Synthetic.healthy());

        for (final hand in report.hands) {
          expect(hand.confidence, inInclusiveRange(0.0, 1.0));
        }
        expect(report.confidence, inInclusiveRange(0.0, 1.0));
      });

      test('explains itself in plain language', () {
        final report = builder.build(Synthetic.healthy());

        expect(report.confidenceReasons, isNotEmpty);
        for (final reason in report.confidenceReasons) {
          expect(reason.toLowerCase(), isNot(contains('parkinson')));
        }
      });

      test('an empty recording has zero confidence and no measurements', () {
        const empty = CameraRecording(tasks: <RecordedTask>[]);
        final report = builder.build(empty);

        expect(report.confidence, 0);
        expect(report.hasAnyMeasurement, isFalse);
      });
    });

    group('left versus right', () {
      test('reports both sides and the gap between them', () {
        final report = builder.build(
          Synthetic.recording(rateHz: 5.0, leftRateHz: 2.5),
        );

        final tapRate =
            report.comparisons.firstWhere((c) => c.name == 'tap_rate');

        expect(tapRate.measured, isTrue);
        expect(tapRate.left, isNotNull);
        expect(tapRate.right, isNotNull);
        expect(tapRate.difference, greaterThan(0));
        expect(tapRate.relativeDifference, inInclusiveRange(0.0, 1.0));
      });

      test('matched hands show no difference', () {
        final report = builder.build(Synthetic.recording(rateHz: 4.0));
        final tapRate =
            report.comparisons.firstWhere((c) => c.name == 'tap_rate');

        expect(tapRate.relativeDifference, lessThan(0.1));
      });

      test('one hand alone yields no comparison rather than a fake one', () {
        final recording = CameraRecording(
          tasks: <RecordedTask>[
            Synthetic.task(
              type: CameraTaskType.fingerTap,
              hand: 'Right',
              seconds: 10,
            ),
          ],
        );

        final report = builder.build(recording);

        expect(report.comparisons.where((c) => c.measured), isEmpty);
        for (final comparison in report.comparisons) {
          expect(comparison.difference, isNull);
        }
      });
    });

    group('serialization', () {
      test('stores the score and the ratings it came from', () {
        final recording = Synthetic.parkinsonian();
        final rating = const MotorRatingScorer().rate(recording);
        final json = builder.build(recording, rating: rating).toJson();

        expect(json['score'], rating.score);
        expect(json['motor_rating'], isA<Map<String, dynamic>>());
        // The names this must never be stored under.
        expect(json.containsKey('parkinsonProbability'), isFalse);
        expect(json.containsKey('diagnosis'), isFalse);
        expect(json.containsKey('clinicalScore'), isFalse);
      });

      test('carries the versions a stored result needs to stay readable', () {
        final json = builder.build(Synthetic.healthy()).toJson();

        expect(json['protocol_version'], CameraTestReport.protocolVersion);
        expect(json['feature_extractor_version'], isNotNull);
        expect(json['quality_rules_version'], isNotNull);
      });

      test('nests results under each hand', () {
        final json = builder.build(Synthetic.healthy()).toJson();
        final hands = json['hands'] as Map<String, dynamic>;

        expect(hands.keys, containsAll(<String>['Left', 'Right']));
        final right = hands['Right'] as Map<String, dynamic>;
        expect(right['confidence'], isNotNull);
        expect(right['tasks'], hasLength(5));
      });

      test('an unmeasurable value serializes as null, never as zero', () {
        final recording = CameraRecording(
          tasks: <RecordedTask>[
            Synthetic.task(
              type: CameraTaskType.fingerTap,
              hand: 'Right',
              seconds: 10,
              rateHz: 0.2,
            ),
          ],
        );

        final json = builder.build(recording).toJson();
        final hands = json['hands'] as Map<String, dynamic>;
        final tasks = (hands['Right'] as Map<String, dynamic>)['tasks'] as List;
        final tap = (tasks.first as Map<String, dynamic>)['cycles']
            as Map<String, dynamic>;

        expect(tap['amplitudeDecrement'], isNull);
        expect(tap.containsKey('amplitudeDecrement'), isTrue,
            reason: 'the key is present so a reader can tell null from absent');
      });
    });

    group('degrades instead of falling off a cliff', () {
      // The regression this group exists for: a recording full of real
      // movement came back showing nothing, because the only fields the
      // analyzer can always produce were being discarded the moment cycle
      // detection failed.
      CameraRecording barelyMoving() => CameraRecording(
            tasks: <RecordedTask>[
              Synthetic.task(
                type: CameraTaskType.fingerTap,
                hand: 'Right',
                seconds: 10,
                // Far below the range at which cycles can be picked out.
                amplitude: 0.005,
                rateHz: 3,
              ),
            ],
          );

      test('a task with no detected cycles still reports speed', () {
        final cycles = builder
            .build(barelyMoving())
            .handReport('Right')!
            .cyclesOf(CameraTaskType.fingerTap)!;

        expect(cycles.cycleCount, 0);
        // These survive cycle detection failing, and are what the screen must
        // keep showing.
        expect(cycles.meanSpeed, isNotNull);
        expect(cycles.maxSpeed, isNotNull);
        expect(cycles.durationSeconds, greaterThan(0));
      });

      test('such a run still counts as having measurements', () {
        // hasAnyMeasurement drives the "nothing could be measured" screen. It
        // must not be true only when a task passed every quality check.
        expect(builder.build(barelyMoving()).hasAnyMeasurement, isTrue);
      });

      test('a genuinely empty recording still reports nothing', () {
        const empty = CameraRecording(tasks: <RecordedTask>[]);

        expect(builder.build(empty).hasAnyMeasurement, isFalse);
      });
    });
  });
}
