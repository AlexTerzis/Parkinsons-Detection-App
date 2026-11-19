import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/patient_report.dart';
import 'package:parkinsondetetion/models/test_result.dart';
import 'package:parkinsondetetion/models/test_type.dart';
import 'package:parkinsondetetion/services/report_analysis.dart';

TestResult resultOf(
  TestType type, {
  double score = 0.2,
  Map<String, dynamic> data = const {},
  DateTime? performedAt,
}) {
  return TestResult(
    id: 'r-${type.name}',
    patientId: 'patient-1',
    type: type,
    performedAt: performedAt ?? DateTime(2026, 8, 4, 10),
    score: score,
    data: data,
  );
}

PatientReport reportOf(List<TestResult> results) {
  return PatientReport(
    id: 'report-1',
    patientId: 'patient-1',
    doctorId: 'doctor-1',
    results: results,
    sentAt: DateTime(2026, 8, 4, 12),
  );
}

/// A camera result that measured everything it set out to.
TestResult goodCamera() => resultOf(
      TestType.cameraDetection,
      data: const {
        'completed_tasks': 4,
        'total_tasks': 4,
        'overall_confidence': 0.9,
      },
    );

/// A posture result with every item recorded.
TestResult goodPosture() => resultOf(
      TestType.posture,
      data: const {
        'items': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        'unrecorded_items': <String>[],
        'recording_quality': 0.9,
      },
    );

/// Every expected test, all of them clean.
List<TestResult> completeAssessment() => [
      for (final type in ReportAnalysis.expectedTests)
        if (type == TestType.cameraDetection)
          goodCamera()
        else if (type == TestType.posture)
          goodPosture()
        else
          resultOf(type),
    ];

AssessmentGap gapFor(List<AssessmentGap> gaps, TestType type) =>
    gaps.firstWhere((g) => g.type == type);

void main() {
  group('which tests a complete assessment is expected to contain', () {
    test('voice is not one of them', () {
      // Voice is a research prototype that `isEligibleForClinicalSummary`
      // already keeps out of clinical summaries. Reporting its absence would
      // send a doctor chasing something that is not meant to be there.
      expect(ReportAnalysis.expectedTests, isNot(contains(TestType.voice)));
    });

    test('every other test type is', () {
      // Derived from TestType.values rather than listed, so a test added later
      // is accounted for without anyone remembering to come back here.
      for (final type in TestType.values) {
        if (type == TestType.voice) continue;
        expect(
          ReportAnalysis.expectedTests,
          contains(type),
          reason: '$type should be expected in a complete assessment',
        );
      }
    });
  });

  group('a complete, clean report', () {
    test('has no gaps at all', () {
      expect(ReportAnalysis.gapsIn(reportOf(completeAssessment())), isEmpty);
    });
  });

  group('tests that were never taken', () {
    test('are reported as not taken', () {
      final report = reportOf([goodCamera()]);
      final gaps = ReportAnalysis.gapsIn(report);

      expect(gapFor(gaps, TestType.tremor).reason, GapReason.notTaken);
      expect(gapFor(gaps, TestType.fab).reason, GapReason.notTaken);
      // The one test that *was* taken, cleanly, is not among them.
      expect(gaps.any((g) => g.type == TestType.cameraDetection), isFalse);
    });

    test('an empty report flags everything except voice', () {
      final gaps = ReportAnalysis.gapsIn(reportOf(const []));

      expect(gaps, hasLength(ReportAnalysis.expectedTests.length));
      expect(gaps.every((g) => g.reason == GapReason.notTaken), isTrue);
      expect(gaps.any((g) => g.type == TestType.voice), isFalse);
    });
  });

  group('camera runs', () {
    test('a partial run says how much is missing', () {
      final report = reportOf([
        ...completeAssessment()
            .where((r) => r.type != TestType.cameraDetection),
        resultOf(TestType.cameraDetection, data: const {
          'completed_tasks': 1,
          'total_tasks': 4,
          'overall_confidence': 0.8,
        }),
      ]);

      final gap = gapFor(ReportAnalysis.gapsIn(report), TestType.cameraDetection);
      expect(gap.reason, GapReason.partlyRecorded);
      expect(gap.missingParts, 3);
      expect(gap.totalParts, 4);
    });

    test('a run that completed nothing is not merely partial', () {
      // The distinction matters: "3 of 4 tasks" still supports a reading,
      // "none of them" supports none at all.
      final report = reportOf([
        resultOf(TestType.cameraDetection, data: const {
          'completed_tasks': 0,
          'total_tasks': 4,
          'overall_confidence': 0.8,
        }),
      ]);

      expect(
        gapFor(ReportAnalysis.gapsIn(report), TestType.cameraDetection).reason,
        GapReason.nothingMeasured,
      );
    });

    test('a complete but low-confidence run is flagged on quality', () {
      final report = reportOf([
        resultOf(TestType.cameraDetection, data: const {
          'completed_tasks': 4,
          'total_tasks': 4,
          'overall_confidence': 0.3,
        }),
      ]);

      final gap =
          gapFor(ReportAnalysis.gapsIn(report), TestType.cameraDetection);
      expect(gap.reason, GapReason.lowQuality);
      expect(gap.quality, 0.3);
    });

    test('a result missing its task counts is not invented into a gap', () {
      // Documents written before these keys existed must not be reported as
      // failures — nothing is known about them either way.
      final report = reportOf([
        resultOf(TestType.cameraDetection, data: const {}),
      ]);

      expect(
        ReportAnalysis.gapsIn(report)
            .any((g) => g.type == TestType.cameraDetection),
        isFalse,
      );
    });
  });

  group('posture runs', () {
    test('unrecorded items are counted against the total', () {
      final report = reportOf([
        resultOf(TestType.posture, data: const {
          'items': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          'unrecorded_items': ['a', 'b', 'c'],
          'recording_quality': 0.8,
        }),
      ]);

      final gap = gapFor(ReportAnalysis.gapsIn(report), TestType.posture);
      expect(gap.reason, GapReason.partlyRecorded);
      expect(gap.missingParts, 3);
      expect(gap.totalParts, 10);
    });

    test('every item unrecorded means nothing was measured', () {
      final report = reportOf([
        resultOf(TestType.posture, data: const {
          'items': [1, 2, 3],
          'unrecorded_items': ['a', 'b', 'c'],
          'recording_quality': 0.8,
        }),
      ]);

      expect(
        gapFor(ReportAnalysis.gapsIn(report), TestType.posture).reason,
        GapReason.nothingMeasured,
      );
    });

    test('poor quality is flagged even when every item was recorded', () {
      final report = reportOf([
        resultOf(TestType.posture, data: const {
          'items': [1, 2, 3],
          'unrecorded_items': <String>[],
          'recording_quality': 0.2,
        }),
      ]);

      final gap = gapFor(ReportAnalysis.gapsIn(report), TestType.posture);
      expect(gap.reason, GapReason.lowQuality);
      expect(gap.quality, 0.2);
    });
  });

  group('retaken tests', () {
    test('a good retake clears the gap left by a bad first attempt', () {
      // A patient who noticed a bad recording and did it again should not
      // still be shown as having a bad one.
      final report = reportOf([
        resultOf(TestType.cameraDetection, data: const {
          'completed_tasks': 0,
          'total_tasks': 4,
        }),
        goodCamera(),
      ]);

      expect(
        ReportAnalysis.gapsIn(report)
            .any((g) => g.type == TestType.cameraDetection),
        isFalse,
      );
    });

    test('two bad attempts still report the milder of the two', () {
      final report = reportOf([
        resultOf(TestType.cameraDetection, data: const {
          'completed_tasks': 0,
          'total_tasks': 4,
        }),
        resultOf(TestType.cameraDetection, data: const {
          'completed_tasks': 3,
          'total_tasks': 4,
        }),
      ]);

      final gap =
          gapFor(ReportAnalysis.gapsIn(report), TestType.cameraDetection);
      expect(gap.reason, GapReason.partlyRecorded);
      expect(gap.missingParts, 1);
    });
  });

  group('reported symptoms', () {
    test('are the answers marked true, sorted', () {
      final questionnaire = resultOf(TestType.questionnaire, data: const {
        'tremor': true,
        'stiffness': false,
        'balance': true,
        'sleep': null,
      });

      expect(
        ReportAnalysis.reportedSymptoms(questionnaire),
        <String>['balance', 'tremor'],
      );
    });

    test('a questionnaire with nothing marked returns nothing', () {
      final questionnaire = resultOf(TestType.questionnaire,
          data: const {'tremor': false, 'stiffness': false});

      expect(ReportAnalysis.reportedSymptoms(questionnaire), isEmpty);
    });
  });

  group('concern by type', () {
    test('takes the most recent attempt of each test', () {
      final report = reportOf([
        resultOf(TestType.tremor,
            score: 0.9, performedAt: DateTime(2026, 8, 1)),
        resultOf(TestType.tremor,
            score: 0.1, performedAt: DateTime(2026, 8, 4)),
      ]);

      expect(ReportAnalysis.concernByType(report)[TestType.tremor],
          closeTo(0.1, 1e-9));
    });

    test('reads through concernScore, so legacy rows are converted', () {
      // A schema-1 FAB row stores a *performance* score, where high is good.
      // Charting it raw would put a strong result next to a weak one and call
      // them the same.
      final legacy = TestResult(
        id: 'legacy',
        patientId: 'patient-1',
        type: TestType.fab,
        performedAt: DateTime(2026, 8, 4),
        score: 0.9,
        scoreSchema: 1,
      );

      final concern = ReportAnalysis.concernByType(reportOf([legacy]));
      expect(concern[TestType.fab], legacy.concernScore);
    });
  });
}
