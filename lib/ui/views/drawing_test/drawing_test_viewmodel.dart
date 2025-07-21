import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';
import '../../../services/authentication_service.dart';
import '../../../services/drawing_predictor.dart';
import '../../../services/test_service.dart';

/// Handles drawing classification and uploading the canvas image to storage.
class DrawingTestViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  final DrawingPredictor _predictor = DrawingPredictor();

  /// Called with the canvas image after the user submits their drawing.
  Future<void> handleCanvas(ui.Image image) async {
    final bytes =
        (await image.toByteData(format: ui.ImageByteFormat.png))?.buffer.asUint8List();
    if (bytes == null) return;
    final pred = await _predictor.predictCanvas(image);
    await _persist(pred.confidence, bytes, {'label': pred.label});
  }

  /// Handles an image picked from camera or gallery.
  Future<void> handleFile(File file) async {
    final bytes = await file.readAsBytes();
    final pred = await _predictor.predictFile(file);
    await _persist(pred.confidence, bytes, {'label': pred.label});
    try {
      await file.delete();
    } catch (_) {}
  }

  Future<void> _persist(
    double score,
    Uint8List pngBytes,
    Map<String, dynamic> data,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.drawing,
      performedAt: DateTime.now(),
      score: score.clamp(0, 1),
      data: data,
    );
    await _tests.addResult(result: result, drawingPng: pngBytes);
  }
}