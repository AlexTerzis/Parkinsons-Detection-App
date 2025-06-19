import 'package:cloud_firestore/cloud_firestore.dart';

import 'test_type.dart';

class TestResult {
  const TestResult({
    required this.id,
    required this.patientId,
    required this.type,
    required this.performedAt,
    required this.score,
    this.data = const {},
  });

  final String id;
  final String patientId;
  final TestType type;
  final DateTime performedAt;
  final double score; // 0.0 - 1.0 normalized score
  final Map<String, dynamic> data; // raw details per test

  factory TestResult.fromJson(Map<String, dynamic> json, String documentId) {
    return TestResult(
      id: documentId,
      patientId: json['patientId'] as String? ?? '',
      type: _typeFromString(json['type'] as String? ?? 'cameraDetection'),
      performedAt:
          (json['performedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'patientId': patientId,
      'type': type.name,
      'performedAt': Timestamp.fromDate(performedAt),
      'score': score,
      'data': data,
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
      default:
        return TestType.cameraDetection;
        
    }
  }
}
