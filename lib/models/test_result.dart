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
      type: _typeFromString(json['type'] as String? ?? 'cameraDetection'),
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

  static TestType _typeFromString(String value) {
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
      default:
        return TestType.cameraDetection;
    }
  }
}
