import 'package:cloud_firestore/cloud_firestore.dart';

import 'test_score_interpretation.dart';
import 'test_type.dart';

class TestResult {
  const TestResult({
    required this.id,
    required this.patientId,
    required this.type,
    required this.performedAt,
    required this.score,
    this.data = const {},
    this.scoreSchema = currentScoreSchema,
  });

  /// Schema 2: [score] always runs the same way for every test — 0 is the best
  /// possible outcome, 1 the most concerning.
  ///
  /// Schema 1 documents, written before this was unified, are the reason this
  /// number exists. They stored a Parkinson's likelihood for the sensor tests
  /// but a *performance* score for the MoCA and FAB batteries, so a high value
  /// meant "bad" for some rows and "good" for others. Anything that compared,
  /// averaged or charted them together was combining opposite quantities.
  ///
  /// Old documents are not rewritten. [concernScore] converts them on read,
  /// which is why every consumer should use that rather than [score].
  static const int currentScoreSchema = 2;

  final String id;
  final String patientId;
  final TestType type;
  final DateTime performedAt;

  /// The stored score, in whatever convention [scoreSchema] describes.
  ///
  /// Prefer [concernScore] unless you specifically need the raw stored value.
  final double score;

  final Map<String, dynamic> data;

  /// Which convention [score] follows. 1 for documents written before the
  /// directions were unified.
  final int scoreSchema;

  /// Whether this result may be loaded into a patient-facing screen.
  ///
  /// Historical voice scores were produced before the research model's
  /// validation flag was enforced. Keeping the documents preserves an audit
  /// trail, but only new records explicitly tagged as prototype demonstrations
  /// may reappear, and those remain separate from clinical summaries.
  bool get isValidatedForPatientUse =>
      type != TestType.voice ||
      data['validatedForClinicalUse'] == true ||
      data['displayAsExperimentalPrototype'] == true;

  bool get isEligibleForClinicalSummary =>
      type != TestType.voice || data['validatedForClinicalUse'] == true;

  bool get isExperimentalVoicePrototype =>
      type == TestType.voice &&
      data['displayAsExperimentalPrototype'] == true &&
      data['validatedForClinicalUse'] != true;

  /// 0-1 where higher always means more concerning, whatever the vintage.
  ///
  /// This is the number to chart, average, compare and colour. Using [score]
  /// directly silently mixes the two conventions.
  double get concernScore {
    final double s = score.clamp(0.0, 1.0);
    if (scoreSchema >= 2) return s;

    // Legacy row: flip the batteries, where a high score meant a good result.
    return TestScoreInterpretation.directionOf(type) ==
            ScoreDirection.higherIsBetter
        ? 1 - s
        : s;
  }

  factory TestResult.fromJson(Map<String, dynamic> json, String documentId) {
    return TestResult(
      id: documentId,
      patientId: json['patientId'] as String? ?? '',
      type: typeFromString(json['type'] as String? ?? 'cameraDetection'),
      performedAt:
          (json['performedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      data: json['data'] as Map<String, dynamic>? ?? {},
      // Absent means the document predates the unification.
      scoreSchema: (json['scoreSchema'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'patientId': patientId,
      'type': type.name,
      'performedAt': Timestamp.fromDate(performedAt),
      'score': score,
      'data': data,
      'scoreSchema': scoreSchema,
    };
  }

  /// Maps a stored `type` string back to its [TestType].
  ///
  /// Public because it is the single place that decision is made, and a second
  /// copy elsewhere would be a second place to forget a case. See the default
  /// branch for why forgetting one is worse than it looks.
  static TestType typeFromString(String value) {
    switch (value) {
      case 'drawing':
        return TestType.drawing;
      case 'questionnaire':
        return TestType.questionnaire;
      case 'tremor':
        return TestType.tremor;
      case 'tap':
        return TestType.tap;
      case 'voice':
        return TestType.voice;
      case 'camera':
      case 'cameraDetection':
        return TestType.cameraDetection;
      case 'neuropsychological':
      case 'neuro':
        return TestType.neuro;
      case 'fab':
        return TestType.fab;
      case 'posture':
        return TestType.posture;
      default:
        // Anything unrecognised. Kept as the camera test because that is what
        // the oldest documents are, but note that a *known* type missing from
        // this switch reads back as the wrong test entirely rather than
        // failing — which is how posture results came to be labelled as camera
        // ones on both the patient's list and the doctor's report.
        return TestType.cameraDetection;
    }
  }
}
