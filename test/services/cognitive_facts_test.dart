import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/test_result.dart';
import 'package:parkinsondetetion/models/test_type.dart';
import 'package:parkinsondetetion/services/cognitive_facts.dart';

TestResult _result(TestType type, DateTime at, Map<String, dynamic> data) =>
    TestResult(
      id: 'r',
      patientId: 'p',
      type: type,
      performedAt: at,
      score: 0,
      data: data,
    );

void main() {
  final day1 = DateTime(2026, 11, 1);
  final day2 = DateTime(2026, 11, 2);

  group('CognitiveFacts.factsFrom', () {
    test('writes nothing when no cognitive test was taken', () {
      expect(CognitiveFacts.factsFrom(const []), isEmpty);
      expect(
        CognitiveFacts.factsFrom([_result(TestType.tremor, day1, const {})]),
        isEmpty,
      );
    });

    test('sets the MoCA fact below the limit and clears it at the limit', () {
      final below = CognitiveFacts.factsFrom(
          [_result(TestType.neuro, day1, const {'mocaScore': 23.5})]);
      expect(below[CognitiveFacts.mocaKey], isTrue);

      final atLimit = CognitiveFacts.factsFrom(
          [_result(TestType.neuro, day1, const {'mocaScore': 24})]);
      expect(atLimit[CognitiveFacts.mocaKey], isFalse);
    });

    test('sets the FAB fact below the limit and clears it at the limit', () {
      final below = CognitiveFacts.factsFrom(
          [_result(TestType.fab, day1, const {'fabScore': 11.25})]);
      expect(below[CognitiveFacts.fabKey], isTrue);

      final atLimit = CognitiveFacts.factsFrom(
          [_result(TestType.fab, day1, const {'fabScore': 12})]);
      expect(atLimit[CognitiveFacts.fabKey], isFalse);
    });

    test('uses the most recent result of each test', () {
      final facts = CognitiveFacts.factsFrom([
        _result(TestType.neuro, day2, const {'mocaScore': 28}),
        _result(TestType.neuro, day1, const {'mocaScore': 10}),
      ]);
      expect(facts[CognitiveFacts.mocaKey], isFalse);
      final meta = facts[CognitiveFacts.metaKey] as Map;
      expect(meta['mocaScore'], 28);
      expect(meta['mocaAt'], day2.toIso8601String());
    });

    test('ignores a result that carries no total', () {
      final facts = CognitiveFacts.factsFrom(
          [_result(TestType.neuro, day1, const {'other': 1})]);
      expect(facts, isEmpty);
    });

    test('one test taken leaves the other fact unwritten', () {
      final facts = CognitiveFacts.factsFrom(
          [_result(TestType.fab, day1, const {'fabScore': 14})]);
      expect(facts.containsKey(CognitiveFacts.mocaKey), isFalse);
      expect(facts[CognitiveFacts.fabKey], isFalse);
    });
  });

  group('CognitiveFacts.missing', () {
    test('lists both tests when none was taken', () {
      expect(CognitiveFacts.missing(const []), [TestType.neuro, TestType.fab]);
    });

    test('lists only the test without a result', () {
      expect(
        CognitiveFacts.missing(
            [_result(TestType.neuro, day1, const {'mocaScore': 26})]),
        [TestType.fab],
      );
    });
  });

  group('CognitiveFacts.merge', () {
    test('adds facts without changing the answers passed in', () {
      final answers = <String, dynamic>{'A1': true};
      final merged = CognitiveFacts.merge(
          answers, [_result(TestType.neuro, day1, const {'mocaScore': 20})]);
      expect(merged['A1'], isTrue);
      expect(merged[CognitiveFacts.mocaKey], isTrue);
      expect(answers.containsKey(CognitiveFacts.mocaKey), isFalse);
    });

    test('keeps facts stored with the answers when no result is given', () {
      final answers = <String, dynamic>{
        'A1': true,
        CognitiveFacts.mocaKey: true,
        CognitiveFacts.metaKey: {'mocaScore': 20},
      };
      final merged = CognitiveFacts.merge(answers, const []);
      expect(merged[CognitiveFacts.mocaKey], isTrue);
      expect((merged[CognitiveFacts.metaKey] as Map)['mocaScore'], 20);
    });

    test('a newer result replaces a stored fact', () {
      final answers = <String, dynamic>{
        CognitiveFacts.mocaKey: true,
        CognitiveFacts.metaKey: {'mocaScore': 20, 'fabScore': 14},
      };
      final merged = CognitiveFacts.merge(
          answers, [_result(TestType.neuro, day2, const {'mocaScore': 27})]);
      expect(merged[CognitiveFacts.mocaKey], isFalse);
      final meta = merged[CognitiveFacts.metaKey] as Map;
      expect(meta['mocaScore'], 27);
      expect(meta['fabScore'], 14);
    });
  });
}
