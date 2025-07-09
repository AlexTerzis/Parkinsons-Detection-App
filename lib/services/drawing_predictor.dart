import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DrawingPredictor {
  late Interpreter _interpreter;
  final List<String> _classNames = const [
    'Healthy Spiral',
    'Healthy Wave',
    'Parkinson Spiral',
    'Parkinson Wave'
  ];

  Future<void> loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/models/drawing_classifier.tflite');
  }

  Map<String, dynamic> _runModel(img.Image image) {
    const int inputSize = 128;

    final img.Image resized =
        img.copyResize(image, width: inputSize, height: inputSize);
    final img.Image grayscale = img.grayscale(resized);

    final List<double> inputList = grayscale
        .getBytes()
        .map((e) => e / 255.0)
        .toList()
        .cast<double>();

    final input =
        Float32List.fromList(inputList).reshape([1, inputSize * inputSize]);
    final output = List.filled(4, 0.0).reshape([1, 4]);

    _interpreter.run(input, output);

    final prediction = output[0];
    int idx = 0;
    double maxVal = prediction[0];
    for (int i = 1; i < prediction.length; i++) {
      if (prediction[i] > maxVal) {
        maxVal = prediction[i];
        idx = i;
      }
    }

    return {'index': idx, 'confidence': maxVal};
  }

  Future<Map<String, dynamic>> predictFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Image could not be loaded');
    final result = _runModel(image);
    return {
      'label': _classNames[result['index'] as int],
      'confidence': result['confidence'] as double,
    };
  }

  Future<Map<String, dynamic>> predictCanvas(ui.Image canvasImage) async {
    final byteData =
        await canvasImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to convert image');
    final img.Image? image =
        img.decodeImage(byteData.buffer.asUint8List());
    if (image == null) throw Exception('Image decode error');
    final result = _runModel(image);
    return {
      'label': _classNames[result['index'] as int],
      'confidence': result['confidence'] as double,
    };
  }

  void dispose() {
    _interpreter.close();
  }
}
