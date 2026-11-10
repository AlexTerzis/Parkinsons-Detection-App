import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_segment.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';

void main() {
  group('CameraTaskProtocol -', () {
    test('examines both hands, one full block at a time', () {
      final tasks = CameraTaskProtocol.build(CameraTestMode.full);

      expect(tasks.length, 8);
      expect(tasks.take(4).every((t) => t.hands.single == 'Right'), isTrue);
      expect(tasks.skip(4).every((t) => t.hands.single == 'Left'), isTrue);
    });

    test('each hand opens with rest, then the three MDS-UPDRS items', () {
      final right = CameraTaskProtocol.build(CameraTestMode.full)
          .where((t) => t.hands.single == 'Right')
          .toList();

      expect(right.map((t) => t.type), [
        CameraTaskType.rest,
        CameraTaskType.openClose,
        CameraTaskType.fingerTap,
        CameraTaskType.pronationSupination,
      ]);
      expect(right.map((t) => t.mdsUpdrsItem), [null, '3.5', '3.4', '3.6']);
    });

    test('full mode records 6s of rest and 12s of each movement', () {
      for (final task in CameraTaskProtocol.build(CameraTestMode.full)) {
        expect(
          task.duration,
          task.type == CameraTaskType.rest
              ? CameraTaskProtocol.restDuration
              : CameraTaskProtocol.movementDuration,
        );
        expect(task.leadIn, greaterThan(Duration.zero),
            reason: 'every step gets a pause to read and settle first');
      }
    });

    test('short mode records both hands together in half the steps', () {
      final short = CameraTaskProtocol.build(CameraTestMode.short);

      expect(short.length, 4);
      for (final task in short) {
        expect(task.isBothHands, isTrue);
        expect(task.hands, <String>['Right', 'Left']);
      }

      expect(
        CameraTaskProtocol.totalDuration(CameraTestMode.short),
        lessThan(CameraTaskProtocol.totalDuration(CameraTestMode.full)),
      );
    });

    test('both modes produce the same per-hand storage keys', () {
      // A short run examines two hands per step, but each hand is still stored
      // under its own key, so nothing downstream has to know which mode ran.
      Set<String> keysOf(CameraTestMode mode) => <String>{
            for (final task in CameraTaskProtocol.build(mode))
              for (final hand in task.hands) task.segmentId(hand),
          };

      expect(keysOf(CameraTestMode.short), keysOf(CameraTestMode.full));
      expect(keysOf(CameraTestMode.full), contains('right_rest'));
      expect(keysOf(CameraTestMode.full), hasLength(8));
    });

    test('step ids are unique within a mode', () {
      for (final mode in CameraTestMode.values) {
        final ids = CameraTaskProtocol.build(mode).map((t) => t.id).toList();
        expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
      }
    });

    test('total duration counts the pauses, recorded duration does not', () {
      expect(
        CameraTaskProtocol.totalDuration(CameraTestMode.full),
        greaterThan(CameraTaskProtocol.recordedDuration(CameraTestMode.full)),
      );
    });

    test('rest is excluded from scoring, movements are not', () {
      final tasks = CameraTaskProtocol.build(CameraTestMode.full);
      expect(tasks.where((t) => t.isScored).length, 6);
      expect(
        tasks.where((t) => !t.isScored).every(
              (t) => t.type == CameraTaskType.rest,
            ),
        isTrue,
      );
    });
  });

  group('CameraTaskSegment -', () {
    CameraTaskSegment segmentWith(List<int> timestamps) {
      final segment = CameraTaskSegment(
        task: CameraTaskProtocol.build(CameraTestMode.full).first,
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
