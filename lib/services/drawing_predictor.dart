import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DrawingPredictor {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('models/keras_logistic_model.tflite');
  }

  Future<String> predict(File imageFile) async {
    const int inputSize = 128;
    final classNames = [
      'Healthy Spiral',
      'Healthy Wave',
      'Parkinson Spiral',
      'Parkinson Wave'
    ];

    // Decode & preprocess
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception("Image could not be loaded.");

    img.Image resized = img.copyResize(image, width: inputSize, height: inputSize);
    img.Image grayscale = img.grayscale(resized);

    // Normalize + flatten
    List<double> inputList = grayscale
        .getBytes()
        .map((e) => e / 255.0) // Normalize
        .toList()
        .cast<double>();

    var input = Float32List.fromList(inputList).reshape([1, inputSize * inputSize]);
    var output = List.filled(4, 0.0).reshape([1, 4]);

    _interpreter.run(input, output);

    final prediction = output[0];
    final predictedIndex = prediction.indexOf(prediction.reduce((a, b) => a > b ? a : b));
    final confidence = prediction[predictedIndex];

    return '${classNames[predictedIndex]} (Confidence: ${(confidence * 100).toStringAsFixed(2)}%)';
  }
}
