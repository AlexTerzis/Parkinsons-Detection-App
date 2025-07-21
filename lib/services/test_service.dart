import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/test_result.dart';
import '../models/test_type.dart';

class TestService {
  final FirebaseFirestore _firestore;

  TestService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns the collection for a specific test type under a user's responses
  /// substructure. The new layout stores each category under
  /// `/users/{uid}/<category>`.
  CollectionReference<Map<String, dynamic>> _categoryCol(
          String uid, TestType type) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection(_typeToPath(type));

  /// Loads all results for the given patient ordered by date. Each document is
  /// converted to a [TestResult] model.
  Future<List<TestResult>> fetchResultsForPatient(String patientId) async {
    final List<TestResult> results = [];
    for (final type in TestType.values) {
      final snap = await _categoryCol(patientId, type)
          .orderBy('performedAt', descending: true)
          .get();
      results.addAll(
          snap.docs.map((d) => TestResult.fromJson(d.data(), d.id)).toList());
    }
    results.sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return results;
  }

  /// Watches the patient's response collection for live updates.
  Stream<List<TestResult>> watchResultsForPatient(String patientId) {
    final controller = StreamController<List<TestResult>>();
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emit() async {
      final list = await fetchResultsForPatient(patientId);
      if (!controller.isClosed) controller.add(list);
    }

    for (final type in TestType.values) {
      final sub = _categoryCol(patientId, type)
          .orderBy('performedAt', descending: true)
          .snapshots()
          .listen((_) => emit());
      subs.add(sub);
    }

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };

    emit();
    return controller.stream;
  }

  /// Saves a new [TestResult] document under the current user's collection.
  Future<void> addResult(TestResult result) {
    return _categoryCol(result.patientId, result.type).add(result.toJson());
  }
  /// Creates or updates the questionnaire result for a patient.
  ///
  /// Each user only keeps a single questionnaire document identified by the
  /// fixed id `questionnaire`. When a questionnaire is submitted again the
  /// previous data is overwritten instead of creating another document. This
  /// allows the UI to simply render the most recent answers without cluttering
  /// the collection with historical entries.
  Future<void> setQuestionnaireResult(TestResult result) {
    return _categoryCol(result.patientId, result.type)
        .doc('questionnaire')
        .set(result.toJson());
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

  String _typeToPath(TestType type) {
    switch (type) {
      case TestType.drawing:
        return 'drawing';
      case TestType.questionnaire:
        return 'questionnaire';
      case TestType.tremor:
        return 'tremor';
      case TestType.tap:
        return 'tapping';
      case TestType.voice:
        return 'voice';
      case TestType.cameraDetection:
        return 'camera';
    }
  }
}
