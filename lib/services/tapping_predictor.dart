import 'package:tflite_flutter/tflite_flutter.dart';

class TappingPredictor {
  late final Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('tapping_model.tflite');
  }

  Future<double> predict(List<double> features) async {
    // Model expects input of shape [1, 7]
    var input = [features];
    var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    _interpreter.run(input, output);

    return output[0][0]; // Return probability (0.0 - 1.0)
  }
}
