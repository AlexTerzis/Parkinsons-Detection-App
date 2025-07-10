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
/// from either a file or a canvas.
class DrawingPredictor {
  late final Interpreter _interpreter;
  bool _modelLoaded = false;

  static const _labels = ['Healthy', 'Parkinson'];
  static const int inputSize = 256;

  /// Loads the drawing classifier model from assets.
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/drawing_binary_classifier2.tflite');
    _modelLoaded = true;
  }

  /// Predict from image file (e.g. gallery or camera).
  Future<DrawingPrediction> predictFile(File file) async {
    if (!_modelLoaded) await loadModel();
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Unable to decode image');
    return _runModel(image);
  }

  /// Predict from canvas image (ui.Image).
  Future<DrawingPrediction> predictCanvas(ui.Image canvasImage) async {
    if (!_modelLoaded) await loadModel();
    final byteData = await canvasImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Unable to extract bytes from canvas');
    final bytes = byteData.buffer.asUint8List();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Unable to decode canvas image');
    return _runModel(image);
  }

  /// Preprocessing and model inference.
  DrawingPrediction _runModel(img.Image image) {
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    final gray = img.grayscale(resized);

    final List<double> inputList = [];
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = gray.getPixel(x, y);
        inputList.add(pixel.r / 255.0); // normalized grayscale
      }
    }

    final input = Float32List.fromList(inputList).reshape([1, inputSize * inputSize]);
    final output = List.filled(1, 0.0).reshape([1, 1]);

    _interpreter.run(input, output);

    final probability = output[0][0];
    final label = probability > 0.5 ? _labels[1] : _labels[0]; // 0=Healthy, 1=Parkinson
    return DrawingPrediction(label, probability);
  }
}
