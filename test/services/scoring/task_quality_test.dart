import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/models/camera_task_segment.dart';
import 'package:parkinsondetetion/models/tracking_event.dart';
import 'package:parkinsondetetion/services/scoring/camera_recording.dart';
import 'package:parkinsondetetion/services/scoring/task_quality.dart';
import 'package:parkinsondetetion/services/tremor_analysis_service.dart';

import 'synthetic_recording.dart';

/// Rebuilds a synthetic task with per-frame samples attached, so the quality
/// rules can be pointed at a recording whose losses are described exactly.
///
/// [states] is applied to the task's frames in order: frames whose state does
/// not carry landmarks are removed, and every state becomes a sample. This is
/// how a clean synthetic movement is turned into a badly recorded one without
/// changing the movement itself.
RecordedTask _withStates(RecordedTask task, List<TrackingState> states) {
  final frames = <TaggedFrame>[];
  final samples = <TrackingSample>[];

  for (int i = 0; i < task.frames.length && i < states.length; i++) {
    final state = states[i];
    samples.add(TrackingSample(
      timestamp: task.frames[i].timestamp,
      state: state,
    ));
    if (state.contributesLandmarks) {
      frames.add(TaggedFrame(
        taskId: task.taskId,
        hand: task.hand,
        timestamp: task.frames[i].timestamp,
        landmarks: task.frames[i].landmarks,
        state: state,
      ));
    }
  }

  return RecordedTask(
    taskId: task.taskId,
    type: task.type,
    hand: task.hand,
    plannedDuration: task.plannedDuration,
    frames: frames,
    samples: samples,
  );
}

/// A clean 10s, 30fps finger-tapping task at a comfortable rate.
RecordedTask _clean({double rateHz = 4, double fps = 30, double seconds = 10}) =>
    Synthetic.task(
      type: CameraTaskType.fingerTap,
      hand: 'Right',
      seconds: seconds,
      fps: fps,
      rateHz: rateHz,
    );

List<TrackingState> _all(RecordedTask task, TrackingState state) =>
    List<TrackingState>.filled(task.frames.length, state);

void main() {
  const validator = TaskQualityValidator();

  group('TaskQualityValidator', () {
    group('a well recorded task', () {
      test('passes every check', () {
        final task = _withStates(_clean(), _all(_clean(), TrackingState.tracked));
        final quality = validator.validate(task);

        expect(quality.valid, isTrue);
        expect(quality.failures, isEmpty);
        expect(quality.retryRecommended, isFalse);
        expect(quality.primaryMessage, isNull);
        expect(quality.confidence, greaterThan(0.8));
      });

      test('reports the cycles it found', () {
        final task = _withStates(_clean(), _all(_clean(), TrackingState.tracked));
        final quality = validator.validate(task);

        expect(quality.cycleCount, greaterThan(30));
      });
    });

    group('a task that must be repeated', () {
      test('a hand out of view for most of the step fails', () {
        final base = _clean();
        final states = <TrackingState>[
          ...List.filled(60, TrackingState.tracked),
          ...List.filled(240, TrackingState.noHand),
        ];

        final quality = validator.validate(_withStates(base, states));

        expect(quality.valid, isFalse);
        expect(quality.retryRecommended, isTrue);
        expect(
          quality.failures.map((f) => f.check),
          contains(QualityCheck.usableFrames),
        );
      });

      test('the message names something the patient can change', () {
        final base = _clean();
        final quality = validator.validate(
          _withStates(base, _all(base, TrackingState.noHand)),
        );

        expect(quality.primaryMessage, isNotNull);
        expect(quality.primaryMessage, contains('hand'));
      });

      test('no messages use medical language', () {
        final base = _clean();
        final states = <TrackingState>[
          ...List.filled(30, TrackingState.tracked),
          ...List.filled(270, TrackingState.wrongHand),
        ];
        final quality = validator.validate(_withStates(base, states));

        const forbidden = <String>[
          'parkinson',
          'symptom',
          'tremor',
          'abnormal',
          'diagnos',
          'disease',
          'impair',
        ];
        for (final failure in quality.failures) {
          final lower = failure.message.toLowerCase();
          for (final word in forbidden) {
            expect(lower, isNot(contains(word)),
                reason: '"${failure.message}" contains "$word"');
          }
        }
      });

      test('showing the wrong hand fails the handedness check', () {
        final base = _clean();
        final states = <TrackingState>[
          ...List.filled(40, TrackingState.tracked),
          ...List.filled(260, TrackingState.wrongHand),
        ];

        final quality = validator.validate(_withStates(base, states));

        expect(
          quality.failures.map((f) => f.check),
          contains(QualityCheck.handedness),
        );
      });

      test('a long dropout fails continuity even at acceptable coverage', () {
        final base = _clean();
        final states = <TrackingState>[
          ...List.filled(120, TrackingState.tracked),
          ...List.filled(75, TrackingState.noHand),
          ...List.filled(105, TrackingState.tracked),
        ];

        final quality = validator.validate(_withStates(base, states));

        expect(quality.valid, isFalse);
        expect(
          quality.failures.map((f) => f.check),
          contains(QualityCheck.trackingContinuity),
        );
      });

      test('a clipped hand fails, and says to move the phone back', () {
        final base = _clean();
        final states = <TrackingState>[
          ...List.filled(100, TrackingState.tracked),
          ...List.filled(200, TrackingState.partiallyOutOfFrame),
        ];

        final quality = validator.validate(_withStates(base, states));

        expect(
          quality.failures.map((f) => f.check),
          contains(QualityCheck.handInFrame),
        );
        expect(
          quality.failures
              .firstWhere((f) => f.check == QualityCheck.handInFrame)
              .message,
          contains('farther away'),
        );
      });

      test('a low capture rate fails', () {
        final slow = _clean(fps: 8);
        final quality =
            validator.validate(_withStates(slow, _all(slow, TrackingState.tracked)));

        expect(
          quality.failures.map((f) => f.check),
          contains(QualityCheck.effectiveFps),
        );
      });

      test('a task that recorded nothing reports one plain failure', () {
        const empty = RecordedTask(
          taskId: 'right_fingerTap',
          type: CameraTaskType.fingerTap,
          hand: 'Right',
          plannedDuration: Duration(seconds: 10),
          frames: <TaggedFrame>[],
        );

        final quality = validator.validate(empty);

        expect(quality.valid, isFalse);
        expect(quality.confidence, 0);
        expect(quality.failures, hasLength(1));
      });

      test('a failed task cannot report high confidence', () {
        final base = _clean();
        final states = <TrackingState>[
          ...List.filled(100, TrackingState.tracked),
          ...List.filled(200, TrackingState.noHand),
        ];

        final quality = validator.validate(_withStates(base, states));

        expect(quality.valid, isFalse);
        expect(quality.confidence, lessThanOrEqualTo(0.4));
      });
    });

    group('slow movement is a finding, not a recording fault', () {
      test('a barely-moving hand is still a valid recording', () {
        // The rule this protects: a patient with pronounced bradykinesia may
        // genuinely manage very few cycles. Forcing them to repeat the task
        // would discard exactly the recordings worth having.
        final slow = Synthetic.task(
          type: CameraTaskType.fingerTap,
          hand: 'Right',
          seconds: 10,
          fps: 30,
          rateHz: 0.3,
          amplitude: 0.4,
        );

        final quality =
            validator.validate(_withStates(slow, _all(slow, TrackingState.tracked)));

        expect(quality.valid, isTrue,
            reason: 'slow movement is the measurement, not a fault');
        expect(quality.retryRecommended, isFalse);
      });

      test('few cycles becomes a note and lowers confidence', () {
        final slow = Synthetic.task(
          type: CameraTaskType.fingerTap,
          hand: 'Right',
          seconds: 10,
          fps: 30,
          rateHz: 0.3,
          amplitude: 0.4,
        );
        final fast = _clean();

        final slowQuality =
            validator.validate(_withStates(slow, _all(slow, TrackingState.tracked)));
        final fastQuality =
            validator.validate(_withStates(fast, _all(fast, TrackingState.tracked)));

        expect(slowQuality.notes.map((n) => n.code), contains('few_cycles'));
        expect(slowQuality.confidence, lessThan(fastQuality.confidence));
      });

      test('the cycle threshold is advisory, never a validity rule', () {
        const rules = QualityRules();
        // Documented intent, pinned so a later edit has to be deliberate.
        expect(rules.advisoryCycleCount, lessThan(rules.confidentCycleCount));
      });
    });

    group('notes', () {
      test('a rate too low for tremor frequency is noted, not failed', () {
        // 13 fps clears the validity floor but sits under the rate at which a
        // frequency can be trusted.
        final task = _clean(fps: 13);
        final quality =
            validator.validate(_withStates(task, _all(task, TrackingState.tracked)));

        expect(quality.valid, isTrue);
        expect(
          quality.notes.map((n) => n.code),
          contains('no_tremor_frequency'),
        );
      });

      test('the noted frequency floor matches the analysis service', () {
        final task = _clean(fps: 16);
        final quality =
            validator.validate(_withStates(task, _all(task, TrackingState.tracked)));

        expect(TremorAnalysisService.minimumFrequencyFps, 15.0);
        expect(
          quality.notes.map((n) => n.code),
          isNot(contains('no_tremor_frequency')),
        );
      });
    });

    group('serialization', () {
      test('carries the verdict, the failures and the notes', () {
        final base = _clean();
        final quality = validator.validate(
          _withStates(base, _all(base, TrackingState.noHand)),
        );

        final json = quality.toJson();

        expect(json['valid'], isFalse);
        expect(json['taskId'], 'right_fingerTap');
        expect(json['hand'], 'Right');
        expect(json['failures'], isNotEmpty);
        expect(
          (json['failures'] as List).first,
          allOf(contains('check'), contains('measured'), contains('message')),
        );
      });
    });

    group('whole recordings', () {
      test('validates every task independently', () {
        final recording = Synthetic.healthy();
        final results = validator.validateAll(recording);

        expect(results, hasLength(recording.tasks.length));
        expect(
          results.map((r) => r.taskId).toSet(),
          recording.tasks.map((t) => t.taskId).toSet(),
        );
      });
    });
  });
}
