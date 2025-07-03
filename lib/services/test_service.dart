import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/test_result.dart';
import '../models/test_type.dart';

class TestService {
  final FirebaseFirestore _firestore;

  TestService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns a reference to the questionnaire responses collection for a
  /// specific user. The path is `/users/{uid}/responses` so that security rules
  /// can restrict access on a per-user basis.
  CollectionReference<Map<String, dynamic>> _responsesCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('responses');

  /// Loads all results for the given patient ordered by date. Each document is
  /// converted to a [TestResult] model.
  Future<List<TestResult>> fetchResultsForPatient(String patientId) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _responsesCol(patientId)
        .orderBy('performedAt', descending: true)
        .get();

    return snap.docs
        .map((doc) => TestResult.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Watches the patient's response collection for live updates.
  Stream<List<TestResult>> watchResultsForPatient(String patientId) {
    return _responsesCol(patientId)
        .orderBy('performedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TestResult.fromJson(d.data(), d.id)).toList());
  }

  /// Saves a new [TestResult] document under the current user's collection.
  Future<void> addResult(TestResult result) {
    return _responsesCol(result.patientId).add(result.toJson());
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
      case TestType.voice:
        return 'Voice';
      case TestType.cameraDetection:
        return 'Camera';
    }
  }
}
