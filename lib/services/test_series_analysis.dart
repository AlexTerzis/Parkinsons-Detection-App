import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/test_result.dart';
import '../models/test_type.dart';

/// Which way a repeated test has been moving.
enum SeriesDirection {
  /// Concern is lower in the recent half than the earlier half.
  improving,

  /// No meaningful movement either way.
  stable,

  /// Concern is higher in the recent half.
  worsening,

  /// Not enough sittings to claim a direction.
  tooFewToSay,
}

/// What every attempt at one test adds up to.
///
/// Computed on the patient's device over their **whole** history and written
/// onto the report, because the report itself only carries the most recent
/// attempts — the doctor has no way to work out an all-time figure from a
/// truncated list.
class TestSeriesSummary {
  const TestSeriesSummary({
    required this.type,
    required this.count,
    required this.firstAt,
    required this.lastAt,
    required this.typicalConcern,
    required this.spread,
    required this.direction,
  });

  final TestType type;

  /// How many times this test has been taken, all time.
  final int count;

  final DateTime firstAt;
  final DateTime lastAt;

  /// The level this test usually comes out at, 0-1, higher being more
  /// concerning. A median — see [TestSeriesAnalysis.median].
  final double typicalConcern;

  /// How much the readings vary, as an interquartile range. Worth showing in
  /// its own right: a tremor that swings between reassuring and notable is a
  /// different picture from one that sits steadily in the middle, and the two
  /// have the same median.
  final double spread;

  final SeriesDirection direction;

  /// Whether there is enough here to say anything about movement over time.
  bool get hasDirection => direction != SeriesDirection.tooFewToSay;

  factory TestSeriesSummary.fromJson(Map<String, dynamic> json) {
    return TestSeriesSummary(
      type: TestResult.typeFromString(json['type'] as String? ?? ''),
      count: (json['count'] as num?)?.toInt() ?? 0,
      firstAt: (json['firstAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastAt: (json['lastAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      typicalConcern: (json['typicalConcern'] as num?)?.toDouble() ?? 0,
      spread: (json['spread'] as num?)?.toDouble() ?? 0,
      direction: _directionFromString(json['direction'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'count': count,
        'firstAt': Timestamp.fromDate(firstAt),
        'lastAt': Timestamp.fromDate(lastAt),
        'typicalConcern': typicalConcern,
        'spread': spread,
        'direction': direction.name,
      };

  static SeriesDirection _directionFromString(String value) {
    for (final direction in SeriesDirection.values) {
      if (direction.name == value) return direction;
    }
    return SeriesDirection.tooFewToSay;
  }
}

/// Turns many attempts at the same test into one readable statement.
///
/// A doctor reading fourteen separate tremor scores learns less than one line
/// saying where they typically land and which way they have been going. This
/// works that out.
///
/// Pure and static: no Firestore, no widgets, no localization. Every figure is
/// derived from [TestResult.concernScore] rather than the raw stored score,
/// because schema-1 documents hold the batteries the opposite way round and
/// averaging the two conventions together produces a number that means nothing.
abstract final class TestSeriesAnalysis {
  /// How many recent attempts of each test travel with a report.
  ///
  /// Bounds the document. A report used to carry every result the patient had
  /// ever recorded, and camera results carry nested per-hand task data, so a
  /// long-running account would eventually cross Firestore's 1 MiB ceiling and
  /// sending would begin to fail outright.
  static const int recentWindow = 10;

  /// Fewer attempts than this and no direction is claimed.
  ///
  /// Two per half is the least that makes a comparison of halves mean anything.
  /// Below it the answer is [SeriesDirection.tooFewToSay] rather than a guess —
  /// "things are improving" off two sittings is not something to put in front
  /// of a clinician.
  static const int minimumForDirection = 4;

  /// How much the two halves must differ before it counts as movement.
  ///
  /// Deliberately well above sensor noise. Below this the honest answer is
  /// "stable", not a direction arrow pointing at a rounding difference.
  static const double directionThreshold = 0.05;

  /// The assessments asked once and read directly, rather than tracked.
  ///
  /// Repeating the same MoCA or FAB form inflates the score — the word list,
  /// the animals, the Luria sequences are all remembered — which is why the
  /// published instruments ship alternate forms for serial testing. The
  /// questionnaire is a symptom history that does not change week to week.
  /// Averaging any of the three over time would be averaging a practice curve.
  static const List<TestType> baselineTests = <TestType>[
    TestType.questionnaire,
    TestType.neuro,
    TestType.fab,
  ];

  static bool isBaseline(TestType type) => baselineTests.contains(type);

  /// The most recent [recentWindow] attempts of each test, newest first.
  ///
  /// Types with fewer than that keep everything they have.
  static List<TestResult> recentPerType(
    List<TestResult> all, {
    int limit = recentWindow,
  }) {
    final byType = <TestType, List<TestResult>>{};
    for (final result in all) {
      byType.putIfAbsent(result.type, () => <TestResult>[]).add(result);
    }

    final kept = <TestResult>[];
    for (final results in byType.values) {
      results.sort((a, b) => b.performedAt.compareTo(a.performedAt));
      kept.addAll(results.take(limit));
    }

    kept.sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return kept;
  }

  /// One summary per test present in [all].
  static List<TestSeriesSummary> summarise(List<TestResult> all) {
    final byType = <TestType, List<TestResult>>{};
    for (final result in all) {
      byType.putIfAbsent(result.type, () => <TestResult>[]).add(result);
    }

    final summaries = <TestSeriesSummary>[];
    for (final entry in byType.entries) {
      final results = entry.value
        ..sort((a, b) => a.performedAt.compareTo(b.performedAt));
      final concerns =
          results.map((r) => r.concernScore).toList(growable: false);

      summaries.add(
        TestSeriesSummary(
          type: entry.key,
          count: results.length,
          firstAt: results.first.performedAt,
          lastAt: results.last.performedAt,
          typicalConcern: median(concerns),
          spread: interquartileRange(concerns),
          direction: directionOf(concerns),
        ),
      );
    }

    // Ordered so the same test sits in the same place on every report.
    summaries.sort(
      (a, b) => TestType.values
          .indexOf(a.type)
          .compareTo(TestType.values.indexOf(b.type)),
    );
    return summaries;
  }

  /// The middle value, averaging the two middles on an even count.
  ///
  /// A median rather than a mean throughout. These are noisy repeated sensor
  /// measurements, and one bad recording — a hand that left frame, a phone set
  /// down mid-reading — should not drag the single number a doctor reads.
  static double median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  /// The spread of the middle half, which ignores the extremes at both ends.
  static double interquartileRange(List<double> values) {
    if (values.length < 4) return 0;
    final sorted = [...values]..sort();
    final half = sorted.length ~/ 2;
    final lower = sorted.sublist(0, half);
    // On an odd count the middle value belongs to neither half.
    final upper = sorted.sublist(sorted.length.isOdd ? half + 1 : half);
    return median(upper) - median(lower);
  }

  /// Which way a chronologically-ordered series has moved.
  ///
  /// Compares the median of the earlier half against the median of the recent
  /// half, rather than fitting a line. Two reasons: a median is unmoved by the
  /// single bad recording that would tilt a regression, and "the recent half is
  /// worse than the earlier half" is something that can be explained to a
  /// patient, which a gradient cannot.
  ///
  /// [concerns] must be oldest-first.
  static SeriesDirection directionOf(List<double> concerns) {
    if (concerns.length < minimumForDirection) {
      return SeriesDirection.tooFewToSay;
    }

    final half = concerns.length ~/ 2;
    final earlier = median(concerns.sublist(0, half));
    // On an odd count the middle reading is left out rather than counted in
    // both halves, which would drag them towards each other.
    final recent =
        median(concerns.sublist(concerns.length.isOdd ? half + 1 : half));

    final delta = recent - earlier;
    if (delta.abs() < directionThreshold) return SeriesDirection.stable;
    // Concern going down is the patient getting better.
    return delta < 0 ? SeriesDirection.improving : SeriesDirection.worsening;
  }
}
