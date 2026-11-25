import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_segment.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';

void main() {
  group('CameraTaskProtocol -', () {
    final tasks = CameraTaskProtocol.build();

    test('opens with both hands still, then each hand on its own', () {
      expect(tasks.length, 8);
      expect(tasks.map((t) => t.id), <String>[
        'both_rest',
        'both_posture',
        'right_fingerTap',
        'right_openClose',
        'right_pronationSupination',
        'left_fingerTap',
        'left_openClose',
        'left_pronationSupination',
      ]);
      expect(tasks.take(2).every((t) => t.isBothHands), isTrue);
      expect(tasks.skip(2).take(3).every((t) => t.hands.single == 'Right'),
          isTrue);
      expect(tasks.skip(5).every((t) => t.hands.single == 'Left'), isTrue);
    });

    test('every step maps to an MDS-UPDRS item', () {
      expect(tasks.map((t) => t.mdsUpdrsItem),
          <String>['3.17', '3.15', '3.4', '3.5', '3.6', '3.4', '3.5', '3.6']);
    });

    test('each step records 10 seconds after a countdown', () {
      for (final task in tasks) {
        expect(task.duration, const Duration(seconds: 10));
        expect(task.leadIn, greaterThan(Duration.zero));
      }
    });

    test('the first step of each hand announces the change of hand', () {
      final switches = tasks.where((t) => t.switchesHand).map((t) => t.id);
      expect(switches, <String>['right_fingerTap', 'left_fingerTap']);
      for (final task in tasks.where((t) => t.switchesHand)) {
        expect(task.leadIn, CameraTaskProtocol.longLeadIn);
      }
    });

    test('per-hand storage keys cover every hand and step', () {
      final keys = <String>{
        for (final task in tasks)
          for (final hand in task.hands) task.segmentId(hand),
      };
      expect(keys, hasLength(10));
      expect(keys, containsAll(<String>['right_rest', 'left_posture']));
    });

    test('step ids are unique', () {
      final ids = tasks.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('total duration counts the countdowns, recorded duration does not',
        () {
      expect(CameraTaskProtocol.recordedDuration(),
          const Duration(seconds: 80));
      expect(CameraTaskProtocol.totalDuration(),
          greaterThan(CameraTaskProtocol.recordedDuration()));
    });

    test('the still steps are tremor tasks, the rest are movements', () {
      expect(tasks.where((t) => t.isScored).length, 6);
      expect(
        tasks.where((t) => !t.isScored).map((t) => t.type),
        <CameraTaskType>[CameraTaskType.rest, CameraTaskType.posture],
      );
    });
  });

  group('CameraTaskSegment -', () {
    CameraTaskSegment segmentWith(List<int> timestamps) {
      final segment = CameraTaskSegment(
        task: CameraTaskProtocol.build().first,
        hand: 'Right',
      );
      for (final t in timestamps) {
        segment.frames.add(TaggedFrame(
          taskId: segment.taskId,
          hand: segment.hand,
          timestamp: t,
          landmarks: List.generate(
            21,
            (i) => LandmarkPoint(x: i / 21, y: t / 1000, z: 0),
          ),
        ));
      }
      return segment;
    }

    test('derives fps from frame timestamps', () {
      // 11 frames spanning one second is ten intervals, so 10 fps.
      final segment =
          segmentWith(List.generate(11, (i) => 1000 + i * 100));
      expect(segment.fps, closeTo(10.0, 0.001));
    });

    test('reports zero fps rather than dividing by an empty span', () {
      expect(segmentWith(const []).fps, 0);
      expect(segmentWith(const [1000]).fps, 0);
      expect(segmentWith(const [1000, 1000]).fps, 0);
    });

    test('rebuilds one trajectory per landmark across frames', () {
      final segment = segmentWith(const [1000, 1100, 1200]);
      final trajectories = segment.toTrajectories();

      expect(trajectories.length, 21);
      expect(trajectories.every((t) => t.length == 3), isTrue);
      // Landmark 5 keeps its own x across every frame.
      expect(trajectories[5].map((p) => p.x).toSet(), {5 / 21});
    });

    test('every frame carries its own task id and hand', () {
      final segment = segmentWith(const [1000, 1100]);
      for (final frame in segment.frames) {
        final json = frame.toJson();
        expect(json['taskId'], 'right_rest');
        expect(json['hand'], 'Right');
      }
    });
  });
}
