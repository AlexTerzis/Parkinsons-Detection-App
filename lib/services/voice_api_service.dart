import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Talks to the Python model hosted on Render.
/// This service handles sending the WAV file and parsing
/// the Parkinson's probability from the JSON response.
class VoiceApiService {
  /// Base URL of the deployed backend.
  /// Replace with your render.com URL.
  static const String _baseUrl = 'https://pd-voice-detector.onrender.com';

  /// Uploads [wav] to the server and returns the probability that
  /// the voice indicates Parkinson's disease.
  Future<double> predict(File wav) async {
    // Endpoint expects multipart/form-data with the file under "file"
    final uri = Uri.parse('$_baseUrl/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', wav.path));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Prediction failed: ${response.statusCode}');
    }

    // Read the JSON body from the response stream
    final String body = await response.stream.bytesToString();
    final Map<String, dynamic> data = jsonDecode(body) as Map<String, dynamic>;

    // The API should return { "probability": 0.7 }
    final num? value = data['probability_PD'] as num?;
    if (value == null) {
      throw Exception('Invalid response: $data');
    }
    return value.toDouble();
  }
}