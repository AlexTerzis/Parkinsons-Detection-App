import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Handles uploading of raw test data to Firebase Storage. Each asset is stored
/// under `<category>/<userId>/<testId>/` so backend ML jobs can ingest them.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads a drawing as PNG bytes.
  Future<void> uploadDrawing(
      Uint8List pngBytes, String userId, String testId) async {
    final ref = _storage.ref().child('drawing/$userId/$testId/drawing.png');
    await ref.putData(
      pngBytes,
      SettableMetadata(contentType: 'image/png'),
    );
  }

  /// Uploads a WAV audio recording.
  Future<void> uploadAudio(
      File wavFile, String userId, String testId) async {
    final ref = _storage.ref().child('voice/$userId/$testId/audio.wav');
    await ref.putFile(
      wavFile,
      SettableMetadata(contentType: 'audio/wav'),
    );
  }

  /// Compresses [rawData] to JSON.gz and uploads it.
  Future<void> uploadCompressedJson(
    Map<String, dynamic> rawData,
    String userId,
    String testType,
    String testId,
  ) {
    return uploadCompressedJsonNamed(
      rawData,
      userId,
      testType,
      testId,
      'raw',
    );
  }

  /// Compresses [rawData] to `<name>.json.gz` under the usual
  /// `<category>/<userId>/<testId>/` prefix.
  ///
  /// Exists so a single test can upload several files side by side — the camera
  /// test writes one per protocol task instead of a single merged recording, so
  /// an analysis job can fetch just the task it cares about.
  Future<void> uploadCompressedJsonNamed(
    Map<String, dynamic> rawData,
    String userId,
    String testType,
    String testId,
    String name,
  ) async {
    final jsonStr = jsonEncode(rawData);
    final bytes = gzip.encode(utf8.encode(jsonStr));
    final ref =
        _storage.ref().child('$testType/$userId/$testId/$name.json.gz');
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'application/gzip'),
    );
  }
}