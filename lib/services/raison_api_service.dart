import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/raison_result.dart';

/// Handles communication with the Raison reasoning API.
class RaisonApiService {
  /// Base URL of the API.
  static const String _baseUrl = 'https://api.ai-raison.com';

  /// API key header value. Replace with the real key in production.
  static const String _key = 'EjlvnSfdDa3eftd9eux0h7D1LKRPsPEW5jbUq8rw';

  /// App and version identifiers used by the API.
  static const String _app = 'PRJ27475';
  static const String _ver = 'latest';

  final http.Client _client;

  RaisonApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Retrieves the element/option mapping from the Raison API.
  Future<Map<String, dynamic>> _fetchSchema() async {
    final uri = Uri.parse('$_baseUrl/executions/$_app/$_ver');
    final res = await _client.get(
      uri,
      headers: {
        'x-api-key': _key,            // ← add your key here
        'Content-Type': 'application/json',
      },
    );
    print('🔍 [Raison API] SCHEMA GET → ${res.statusCode}\n'
          'Response: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception('Failed to load schema: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Sends [responses] to the API and returns the list of results.
  Future<List<RaisonResult>> submit(Map<String, dynamic> responses) async {
    // 1️⃣ Fetch the schema
    final schema = await _fetchSchema();

    final elementsRaw = schema['elements'] as List<dynamic>? ?? [];
    final optionsRaw  = schema['options']  as List<dynamic>? ?? [];

    // 2️⃣ Build the element payload
    final List<Map<String, dynamic>> elementPayload = [];
    for (final e in elementsRaw) {
      final label = e['label'] as String?;
      if (label != null && responses[label] == true) {
        elementPayload.add({
          'id': e['id'],
          'parameters': (e['parameters'] as List<dynamic>?)?.cast<String>() ?? [],

        });
      }
    }

    // 3️⃣ Build the option payload
    final List<Map<String, String>> optionPayload = [
      for (final o in optionsRaw) {'id': o['id'] as String}
    ];

    // 4️⃣ Prepare & send the POST
    final uri = Uri.parse('$_baseUrl/executions/$_app/$_ver');
    final requestBody = jsonEncode({
      'elements': elementPayload,
      'options' : optionPayload,
    });

    final response = await _client.post(
      uri,
      headers: {
        'x-api-key'     : _key,
        'Content-Type'  : 'application/json',
      },
      body: requestBody,
    );

    // ▶️ Log the real request + the response
    print('🔍 [Raison API] EXECUTE POST → ${response.statusCode}\n'
          'Request:  $requestBody\n'
          'Response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Execution failed: ${response.statusCode}');
    }

    // 5️⃣ Parse into your model
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => RaisonResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  
  /// Closes the HTTP client.
  void close() {
    _client.close();
  }

}
