import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/test_result.dart';
import '../models/test_type.dart';

class TestService {
  final FirebaseFirestore _firestore;

  TestService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _resultsCol =>
      _firestore.collection('test_results');

  Future<List<TestResult>> fetchResultsForPatient(String patientId) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _resultsCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('performedAt', descending: true)
        .get();

    return snap.docs
        .map((doc) => TestResult.fromJson(doc.data(), doc.id))
        .toList();
  }

  Stream<List<TestResult>> watchResultsForPatient(String patientId) {
    return _resultsCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('performedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TestResult.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> addResult(TestResult result) {
    return _resultsCol.add(result.toJson());
  }

  Map<String, double> computeSummary(List<TestResult> results) {
    if (results.isEmpty) return {};

    final Map<TestType, List<TestResult>> grouped = {};
    for (var r in results) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }

    final Map<String, double> summary = {};
    grouped.forEach((type, list) {
      final double avg =
          list.map((e) => e.score).reduce((a, b) => a + b) / list.length;
      summary[_typeToLabel(type)] = avg;
    });
    return summary;
  }

  String _typeToLabel(TestType type) {
    switch (type) {
      case TestType.drawing:
        return 'Drawing';
      case TestType.questionnaire:
        return 'Questionnaire';
      case TestType.tremor:
        return 'Tremor';
      case TestType.tap:
        return 'Tap';
      case TestType.cameraDetection:
        return 'Camera';
    }
  }
}
