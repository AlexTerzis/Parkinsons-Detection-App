import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/patient_report.dart';
import 'package:parkinsondetetion/models/test_result.dart';
import 'package:parkinsondetetion/models/test_type.dart';
import 'package:parkinsondetetion/services/test_series_analysis.dart';

/// A result of [type] on day [day] of August 2026, with concern [score].
TestResult at(TestType type, int day, double score) => TestResult(
      id: '$type-$day',
      patientId: 'patient-1',
      type: type,
      performedAt: DateTime(2026, 8, day),
      score: score,
    );

/// [count] results of [type], oldest first, all at the same level.
List<TestResult> series(TestType type, int count, double score) =>
    [for (var day = 1; day <= count; day++) at(type, day, score)];

TestSeriesSummary summaryFor(List<TestResult> results, TestType type) =>
    TestSeriesAnalysis.summarise(results).firstWhere((s) => s.type == type);

void main() {
  group('median', () {
    test('is the middle value on an odd count', () {
      expect(TestSeriesAnalysis.median([0.1, 0.9, 0.5]), 0.5);
    });

    test('averages the two middles on an even count', () {
      expect(TestSeriesAnalysis.median([0.2, 0.4, 0.6, 0.8]), closeTo(0.5, 1e-9));
    });

    test('is unmoved by a single wild reading', () {
      // The reason this is a median and not a mean. One recording where the
      // hand left frame should not drag the figure a doctor reads.
      final steady = [0.2, 0.2, 0.25, 0.2, 0.2];
      final withOutlier = [0.2, 0.2, 0.25, 0.2, 1.0];

      expect(
        TestSeriesAnalysis.median(withOutlier),
        TestSeriesAnalysis.median(steady),
      );
    });

    test('an empty series is zero rather than a crash', () {
      expect(TestSeriesAnalysis.median(const []), 0);
    });
  });

  group('direction', () {
    test('falling concern is the patient improving', () {
      // Concern down means better, so the direction must not simply follow the
      // sign of the change.
      expect(
        TestSeriesAnalysis.directionOf([0.8, 0.7, 0.3, 0.2]),
        SeriesDirection.improving,
      );
    });

    test('rising concern is worsening', () {
      expect(
        TestSeriesAnalysis.directionOf([0.2, 0.3, 0.7, 0.8]),
        SeriesDirection.worsening,
      );
    });

    test('a small wobble is stable, not a direction', () {
      // Below the threshold the honest answer is "stable" rather than an arrow
      // pointing at sensor noise.
      expect(
        TestSeriesAnalysis.directionOf([0.40, 0.41, 0.42, 0.41]),
        SeriesDirection.stable,
      );
    });

    test('too few sittings gives no verdict at all', () {
      for (var count = 0; count < TestSeriesAnalysis.minimumForDirection; count++) {
        expect(
          TestSeriesAnalysis.directionOf(List.filled(count, 0.5)),
          SeriesDirection.tooFewToSay,
          reason: '$count readings should not support a direction',
        );
      }
    });

    test('the middle reading is excluded on an odd count', () {
      // Counting it in both halves would drag them towards each other and
      // flatten a real change into "stable".
      expect(
        TestSeriesAnalysis.directionOf([0.9, 0.9, 0.5, 0.1, 0.1]),
        SeriesDirection.improving,
      );
    });
  });

  group('recentPerType', () {
    test('keeps only the newest window of each test', () {
      final results = series(TestType.tremor, 25, 0.3);

      final kept = TestSeriesAnalysis.recentPerType(results);

      expect(kept, hasLength(TestSeriesAnalysis.recentWindow));
      // The newest, not the first ten written.
      expect(kept.first.performedAt, DateTime(2026, 8, 25));
      expect(kept.last.performedAt, DateTime(2026, 8, 16));
    });

    test('caps each test separately rather than the list as a whole', () {
      final results = <TestResult>[
        ...series(TestType.tremor, 15, 0.3),
        ...series(TestType.tap, 15, 0.4),
      ];

      final kept = TestSeriesAnalysis.recentPerType(results);

      expect(kept.where((r) => r.type == TestType.tremor), hasLength(10));
      expect(kept.where((r) => r.type == TestType.tap), hasLength(10));
    });

    test('a test with fewer attempts keeps all of them', () {
      final results = series(TestType.drawing, 3, 0.2);
      expect(TestSeriesAnalysis.recentPerType(results), hasLength(3));
    });

    test('comes back newest first', () {
      final kept = TestSeriesAnalysis.recentPerType(series(TestType.tap, 5, 0.2));
      for (var i = 1; i < kept.length; i++) {
        expect(
          kept[i - 1].performedAt.isAfter(kept[i].performedAt),
          isTrue,
        );
      }
    });
  });

  group('summarise', () {
    test('counts every attempt, including ones that will not be sent', () {
      // The whole point of computing this before truncating: the doctor cannot
      // recover an all-time count from the ten results they receive.
      final all = series(TestType.tremor, 30, 0.3);

      final summary = summaryFor(all, TestType.tremor);
      expect(summary.count, 30);
      expect(
        TestSeriesAnalysis.recentPerType(all).length,
        lessThan(summary.count),
      );
    });

    test('records the span the series covers', () {
      final summary = summaryFor(series(TestType.tap, 5, 0.4), TestType.tap);

      expect(summary.firstAt, DateTime(2026, 8, 1));
      expect(summary.lastAt, DateTime(2026, 8, 5));
    });

    test('one summary per test type present', () {
      final results = <TestResult>[
        ...series(TestType.tremor, 4, 0.3),
        ...series(TestType.tap, 2, 0.6),
      ];

      final summaries = TestSeriesAnalysis.summarise(results);
      expect(summaries.map((s) => s.type),
          containsAll([TestType.tremor, TestType.tap]));
      expect(summaries, hasLength(2));
    });

    test('nothing in, nothing out', () {
      expect(TestSeriesAnalysis.summarise(const []), isEmpty);
    });

    test('reads a legacy row through concernScore, not the raw score', () {
      // A schema-1 FAB row stores a *performance* score, where high is good.
      // Summarising the raw value would report a strong result as alarming.
      final legacy = TestResult(
        id: 'legacy',
        patientId: 'p',
        type: TestType.fab,
        performedAt: DateTime(2026, 8, 1),
        score: 0.9,
        scoreSchema: 1,
      );

      final summary = summaryFor([legacy], TestType.fab);
      expect(summary.typicalConcern, legacy.concernScore);
      expect(summary.typicalConcern, closeTo(0.1, 1e-9));
    });

    test('order does not depend on the order results arrive in', () {
      final ascending = series(TestType.tremor, 4, 0.3);
      final shuffled = [...ascending.reversed];

      expect(
        summaryFor(shuffled, TestType.tremor).firstAt,
        summaryFor(ascending, TestType.tremor).firstAt,
      );
    });
  });

  group('which tests are asked once', () {
    test('the questionnaire and both batteries', () {
      expect(TestSeriesAnalysis.isBaseline(TestType.questionnaire), isTrue);
      expect(TestSeriesAnalysis.isBaseline(TestType.neuro), isTrue);
      expect(TestSeriesAnalysis.isBaseline(TestType.fab), isTrue);
    });

    test('the sensor tests are not', () {
      for (final type in [
        TestType.tremor,
        TestType.tap,
        TestType.drawing,
        TestType.cameraDetection,
        TestType.posture,
      ]) {
        expect(TestSeriesAnalysis.isBaseline(type), isFalse, reason: '$type');
      }
    });
  });

  group('what a report carries', () {
    test('summaries survive a round trip', () {
      final report = PatientReport(
        id: 'r1',
        patientId: 'p',
        doctorId: 'd',
        results: const [],
        sentAt: DateTime(2026, 8, 5),
        summaries: TestSeriesAnalysis.summarise(series(TestType.tremor, 6, 0.3)),
      );

      final restored = PatientReport.fromJson(report.toJson(), 'r1');
      expect(restored.summaries, hasLength(1));
      expect(restored.summaries.first.type, TestType.tremor);
      expect(restored.summaries.first.count, 6);
      expect(restored.summaries.first.typicalConcern, closeTo(0.3, 1e-9));
    });

    test('a report written before summaries existed still parses', () {
      final legacy = PatientReport.fromJson(<String, dynamic>{
        'patientId': 'p',
        'doctorId': 'd',
        'results': <dynamic>[],
      }, 'old');

      expect(legacy.summaries, isEmpty);
    });

    test('an old report summarises the results it does carry', () {
      // Reports written before this change carry every result rather than the
      // last ten, so summarising them gives the same all-time answer the
      // patient's device would have computed. They read better, not worse.
      final old = PatientReport(
        id: 'old',
        patientId: 'p',
        doctorId: 'd',
        results: series(TestType.tremor, 6, 0.3),
        sentAt: DateTime(2026, 8, 5),
      );

      expect(old.summaries, isEmpty);
      expect(old.seriesSummaries, hasLength(1));
      expect(old.seriesSummaries.first.count, 6);
    });

    test('a new report prefers the summaries it was sent', () {
      final report = PatientReport(
        id: 'new',
        patientId: 'p',
        doctorId: 'd',
        // Truncated, as a real one would be.
        results: series(TestType.tremor, 10, 0.3),
        sentAt: DateTime(2026, 8, 5),
        summaries: TestSeriesAnalysis.summarise(series(TestType.tremor, 40, 0.3)),
      );

      // The all-time count, not the ten results in front of it.
      expect(report.seriesSummaries.first.count, 40);
    });
  });
}
