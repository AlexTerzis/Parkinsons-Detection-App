import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/raison_result.dart';

/// Handles communication with the Raison reasoning API.
class RaisonApiService {
  /// Base URL of the API.
  static const String _baseUrl = 'https://api.ai-raison.com';

  /// API key, supplied at build time and never committed:
  ///
  ///     flutter run   --dart-define-from-file=raison.local.json
  ///     flutter build --dart-define-from-file=raison.local.json
  ///
  /// `raison.local.json` is gitignored. The key used to be a literal here,
  /// which published it the moment the repo went public — and git history
  /// survives in clones and forks, so that one had to be revoked rather than
  /// merely replaced.
  ///
  /// This keeps the key out of the *repository*, not out of the built app: a
  /// value compiled into a mobile binary can still be extracted from it. Only
  /// proxying rAIson through a server of our own would fix that.
  static const String _key = String.fromEnvironment('RAISON_API_KEY');

  /// App and version identifiers used by the API.
  static const String _app = 'PRJ27475';
  static const String _ver = 'latest';

  final http.Client _client;

  /// When created we immediately kick off a schema fetch so later calls
  /// to [submit] don't block on this network request.
  RaisonApiService({http.Client? client}) : _client = client ?? http.Client() {
    // `ignore()` because nothing is awaiting this yet: at launch there may be
    // no network, and a failure here must not surface as an unhandled async
    // error. [_schema] retries on first real use.
    _schemaFuture = _fetchSchema()..ignore();
  }

  /// Holds the ongoing or successful schema request so it can be reused.
  /// Cleared on failure — see [_schema].
  Future<Map<String, dynamic>>? _schemaFuture;

  /// The schema, reusing an in-flight or successful fetch and retrying after a
  /// failure.
  ///
  /// [submit] used to do `_schemaFuture ??= _fetchSchema()`, and `??=` only
  /// fills a *null* slot. A fetch that failed stayed cached as a permanently
  /// rejected future, so every later submission re-awaited the same failure:
  /// one bad connection — most likely the one started in the constructor at
  /// launch — disabled reasoning until the app was restarted.
  Future<Map<String, dynamic>> _schema() async {
    final cached = _schemaFuture;
    if (cached != null) {
      try {
        return await cached;
      } catch (_) {
        // A cached failure is not a permanent answer. Drop it and try once
        // more below, so the retry happens on this call rather than the next.
        if (_schemaFuture == cached) _schemaFuture = null;
      }
    }

    final attempt = _fetchSchema();
    _schemaFuture = attempt;
    try {
      return await attempt;
    } catch (_) {
      if (_schemaFuture == attempt) _schemaFuture = null;
      rethrow;
    }
  }

  /// Retrieves the element/option mapping from the Raison API.
  Future<Map<String, dynamic>> _fetchSchema() async {
    // Say which build flag is missing, rather than letting the request come
    // back as an opaque 403 that looks like an outage.
    if (_key.isEmpty) {
      throw StateError(
        'RAISON_API_KEY was not set at build time. Pass '
        '--dart-define-from-file=raison.local.json (see README).',
      );
    }

    final uri = Uri.parse('$_baseUrl/executions/$_app/$_ver');
    final res = await _client.get(
      uri,
      headers: {
        'x-api-key': _key,
        'Content-Type': 'application/json',
      },
    );
    debugPrint('🔍 [Raison API] SCHEMA GET → ${res.statusCode}\n'
          'Response: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception('Failed to load schema: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Sends [responses] to the API and returns the list of results.
  Future<List<RaisonResult>> submit(Map<String, dynamic> responses) async {
    // 1️⃣ Use the cached schema; fetch or re-fetch as needed.
    final schema = await _schema();

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
    debugPrint('🔍 [Raison API] EXECUTE POST → ${response.statusCode}\n'
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

}
