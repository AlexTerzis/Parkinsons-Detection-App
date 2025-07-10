import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import 'package:tflite_flutter/tflite_flutter.dart';

/// Simple data holder for prediction results.
class DrawingPrediction {
  final String label;
  final double confidence;
  const DrawingPrediction(this.label, this.confidence);
}

/// Handles loading the TFLite model and running inference on images
/// from either a file or a canvas. The heavy lifting (resizing,
/// grayscaling and normalization) happens in [_runModel].
class DrawingPredictor {
  late final Interpreter _interpreter;
  bool _modelLoaded = false;

  static const _labels = [
    'Healthy Spiral',
    'Healthy Wave',
    'Parkinson Spiral',
    'Parkinson Wave',
  ];

  /// Loads the drawing classifier from assets. Must be called before
  /// prediction. The model is tiny so we keep it in memory after loading.
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/drawing_classifier.tflite');

    _modelLoaded = true;
  }

  /// Runs prediction on an image file captured from camera or gallery.
  Future<DrawingPrediction> predictFile(File file) async {
    if (!_modelLoaded) await loadModel();
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Unable to decode image');
    }
    return _runModel(image);
  }

  /// Runs prediction on a [ui.Image] created from the drawing canvas.
  Future<DrawingPrediction> predictCanvas(ui.Image image) async {
    if (!_modelLoaded) await loadModel();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Unable to extract bytes from canvas');
    }
    final bytes = byteData.buffer.asUint8List();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unable to decode canvas image');
    }
    return _runModel(decoded);
  }

  /// Shared preprocessing and inference step. The model expects a
  /// flattened 128x128 grayscale float tensor in the range [0,1].
  DrawingPrediction _runModel(img.Image image) {
    const inputSize = 128;
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    final grayImage = img.grayscale(resized);
    final List<double> inputList = [];

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = grayImage.getPixel(x, y);
        final gray = pixel.r / 255.0; // normalize grayscale to [0,1]
        inputList.add(gray);
      }
    }

    final input = Float32List.fromList(inputList).reshape([1, inputSize * inputSize]);
    final output = List.filled(4, 0.0).reshape([1, 4]);

    _interpreter.run(input, output);

    final scores = List<double>.from(output[0]);
    int bestIdx = 0;
    double bestScore = scores[0];
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIdx = i;
      }
    }

    return DrawingPrediction(_labels[bestIdx], bestScore);
  }
}
