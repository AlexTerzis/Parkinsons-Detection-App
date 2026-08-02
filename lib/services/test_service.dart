import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/test_result.dart';
import '../models/test_type.dart';
import 'storage_service.dart';

class TestService {
  final FirebaseFirestore _firestore;
  final StorageService _storage;
  final FirebaseAuth _auth;

  TestService({
    FirebaseFirestore? firestore,
    StorageService? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Serializes a result, tagging it with whether it came from a guest.
  ///
  /// Applied here rather than at the ten call sites so no test flow can forget
  /// it, and stored top-level rather than inside `data`, which each test
  /// replaces wholesale.
  Map<String, dynamic> _toJsonWithGuestFlag(TestResult result) {
    return <String, dynamic>{
      ...result.toJson(),
      'isGuest': _auth.currentUser?.isAnonymous ?? false,
    };
  }

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
      try {
        final snap = await _categoryCol(patientId, type)
            .orderBy('performedAt', descending: true)
            .get();
        results.addAll(
            snap.docs.map((d) => TestResult.fromJson(d.data(), d.id)).toList());
      } catch (_) {
        // Ignore permission errors or missing collections
      }
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
      try {
        final sub = _categoryCol(patientId, type)
            .orderBy('performedAt', descending: true)
            .snapshots()
            .listen((_) => emit(), onError: (_) {});
        subs.add(sub);
      } catch (_) {
        // Ignore permission errors
      }
    }

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };

    emit();
    return controller.stream;
  }

  /// Saves a new [TestResult] document along with optional raw data assets.
  ///
  /// [taskSegments] carries per-task recordings for tests that are made of
  /// several timed steps (currently the camera test's MDS-UPDRS task
  /// sequence). Each entry is uploaded as its own file, keyed by task id, so
  /// the tasks stay separable after upload. Optional, so every other test flow
  /// is unaffected.
  /// The result document is written **before** any raw asset is uploaded, and
  /// upload failures never propagate.
  ///
  /// The previous order was the other way round, to avoid documents pointing at
  /// assets that were never stored. That traded the wrong way: a single Storage
  /// error — denied rules, no network, the app being killed mid-upload — meant
  /// the whole test silently vanished, because the write was never reached. A
  /// result without its raw blob is still a usable result; a blob with no
  /// document is invisible to the app entirely.
  ///
  /// When an upload does fail the document is marked with `rawDataUploaded:
  /// false` and the error, so a reviewer can tell "no raw data" from "raw data
  /// not yet fetched". Absence of the field means there was nothing to upload,
  /// or it uploaded cleanly.
  Future<void> addResult({
    required TestResult result,
    Uint8List? drawingPng,
    File? audioWav,
    Map<String, dynamic>? sensorData,
    Map<String, Map<String, dynamic>>? taskSegments,
  }) async {
    final colRef = _categoryCol(result.patientId, result.type);
    final docRef = colRef.doc();
    final testId = docRef.id;

    // Firestore first: this is the part the app actually reads back. A failure
    // here still throws, because then there genuinely is no result.
    await docRef.set(_toJsonWithGuestFlag(result));

    try {
      await _uploadRawData(
        result: result,
        testId: testId,
        drawingPng: drawingPng,
        audioWav: audioWav,
        sensorData: sensorData,
        taskSegments: taskSegments,
      );
    } catch (e) {
      // Best effort: the result is already saved and the patient keeps it.
      try {
        await docRef.set(
          <String, dynamic>{
            'rawDataUploaded': false,
            'rawDataError': e.toString(),
          },
          SetOptions(merge: true),
        );
      } catch (_) {
        // Even the marker is optional; never let bookkeeping lose a result.
      }
    }
  }

  /// Uploads whichever raw asset this test type produces. May throw; the caller
  /// treats that as non-fatal.
  Future<void> _uploadRawData({
    required TestResult result,
    required String testId,
    Uint8List? drawingPng,
    File? audioWav,
    Map<String, dynamic>? sensorData,
    Map<String, Map<String, dynamic>>? taskSegments,
  }) async {
    switch (result.type) {
      case TestType.drawing:
        if (drawingPng != null) {
          await _storage.uploadDrawing(drawingPng, result.patientId, testId);
        }
        break;
      case TestType.voice:
        if (audioWav != null) {
          await _storage.uploadAudio(audioWav, result.patientId, testId);
          try {
            await audioWav.delete();
          } catch (_) {}
        }
        break;
      case TestType.tremor:
      case TestType.tap:
        if (sensorData != null) {
          await _storage.uploadCompressedJson(
            sensorData,
            result.patientId,
            result.type.name,
            testId,
          );
        }
        break;
      case TestType.cameraDetection:
        // One file per protocol task, plus the legacy merged blob when the
        // caller still supplies one.
        if (taskSegments != null) {
          for (final entry in taskSegments.entries) {
            await _storage.uploadCompressedJsonNamed(
              entry.value,
              result.patientId,
              result.type.name,
              testId,
              entry.key,
            );
          }
        }
        if (sensorData != null) {
          await _storage.uploadCompressedJson(
            sensorData,
            result.patientId,
            result.type.name,
            testId,
          );
        }
        break;
      case TestType.questionnaire:
      case TestType.neuro:
      case TestType.fab:
        break;
    }
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
        .set(_toJsonWithGuestFlag(result));
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
      case TestType.neuro:
        return 'neuropsychological'; 
      case TestType.fab:
        return 'FAB';   
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
      case TestType.neuro:
        return 'neuropsychological'; 
      case TestType.fab:
        return 'FAB';    
    }
  }
}
