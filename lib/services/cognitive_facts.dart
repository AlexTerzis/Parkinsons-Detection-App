import '../models/test_result.dart';
import '../models/test_type.dart';

/// Facts for the reasoning service that come from the cognitive tests the
/// patient takes in the app.
///
/// The questionnaire spreadsheet names the MoCA score `Δ1π1` and the FAB score
/// `Δ1π2`, and its decision tables use two categories of them:
///
///  * `Δ1π11Ι` — MoCA below 24;
///  * `Δ1π21ΙΙ` — FAB below 12.
///
/// The app's tests are adaptations of the paper instruments, so these facts
/// say what the *app* test produced. The FAB limit in particular was written
/// for the full 18-point battery, while the app's FAB has five subtests and a
/// 15-point total; the limit is kept as specified until it is decided
/// otherwise, and is in one place here so that it is easy to change.
///
/// Everything here is a pure function of its arguments, so it can be tested
/// without Firebase.
class CognitiveFacts {
  CognitiveFacts._();

  /// A MoCA total strictly below this sets [mocaKey].
  static const num mocaBelow = 24;

  /// A FAB total strictly below this sets [fabKey]. Provisional — see above.
  static const num fabBelow = 12;

  /// Key of the fact "MoCA below 24" (`Δ1π11Ι`).
  static const String mocaKey = 'D1p11I';

  /// Key of the fact "FAB below 12" (`Δ1π21ΙΙ`).
  static const String fabKey = 'D1p21II';

  /// Key under which the scores and dates the facts were derived from are
  /// kept with the questionnaire, so that a stored questionnaire shows what
  /// its facts rest on.
  static const String metaKey = 'cognitiveInputs';

  /// The most recent result of [type] in [results], or null if there is none.
  static TestResult? latest(Iterable<TestResult> results, TestType type) {
    TestResult? best;
    for (final r in results) {
      if (r.type != type) continue;
      if (best == null || r.performedAt.isAfter(best.performedAt)) best = r;
    }
    return best;
  }

  /// The MoCA-based total of [result], or null when it carries none.
  static num? mocaScore(TestResult? result) => _number(result?.data['mocaScore']);

  /// The FAB total of [result], or null when it carries none.
  static num? fabScore(TestResult? result) => _number(result?.data['fabScore']);

  static num? _number(dynamic value) => value is num ? value : null;

  /// The cognitive tests that have no usable result in [results].
  static List<TestType> missing(Iterable<TestResult> results) => [
        if (mocaScore(latest(results, TestType.neuro)) == null) TestType.neuro,
        if (fabScore(latest(results, TestType.fab)) == null) TestType.fab,
      ];

  /// The facts that [results] support.
  ///
  /// A test that was never taken contributes nothing: no key is written for
  /// it, so a rule that needs the fact simply does not apply. Writing `false`
  /// would claim a normal result that nobody measured.
  static Map<String, dynamic> factsFrom(Iterable<TestResult> results) {
    final facts = <String, dynamic>{};
    final meta = <String, dynamic>{};

    final moca = latest(results, TestType.neuro);
    final mocaTotal = mocaScore(moca);
    if (moca != null && mocaTotal != null) {
      facts[mocaKey] = mocaTotal < mocaBelow;
      meta['mocaScore'] = mocaTotal;
      meta['mocaAt'] = moca.performedAt.toIso8601String();
    }

    final fab = latest(results, TestType.fab);
    final fabTotal = fabScore(fab);
    if (fab != null && fabTotal != null) {
      facts[fabKey] = fabTotal < fabBelow;
      meta['fabScore'] = fabTotal;
      meta['fabAt'] = fab.performedAt.toIso8601String();
    }

    if (meta.isNotEmpty) facts[metaKey] = meta;
    return facts;
  }

  /// [answers] together with the facts from [results].
  ///
  /// [answers] is not modified. Facts already present in it are kept when
  /// [results] has nothing newer to say, so a stored questionnaire keeps the
  /// facts it was submitted with.
  static Map<String, dynamic> merge(
    Map<String, dynamic> answers,
    Iterable<TestResult> results,
  ) {
    final derived = factsFrom(results);
    final merged = Map<String, dynamic>.of(answers)..addAll(derived);
    final earlier = answers[metaKey];
    final now = derived[metaKey];
    if (earlier is Map && now is Map) {
      merged[metaKey] = {...earlier, ...now};
    }
    return merged;
  }
}
