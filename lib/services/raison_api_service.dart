import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/raison_result.dart';
import 'raison_plus_inputs.dart';

/// The key's query quota is used up (HTTP 429 with `quota_exhausted`).
class RaisonQuotaExhausted implements Exception {
  const RaisonQuotaExhausted();
  @override
  String toString() => 'rAIson+ query quota exhausted';
}

/// Handles communication with the rAIson+ reasoning agent.
///
/// The agent is `AI_diagnosis_of_PD_visit_rules_rAIson_no_dilemma`. Its inputs
/// have readable names (`tremor`, `datscan`, ...); [RaisonPlusInputs] builds
/// them from the questionnaire answers. Every caller — the questionnaire, the
/// Insights tab and the doctor's report — goes through [submit].
class RaisonApiService {
  /// Base URL of the rAIson+ agents API.
  static const String baseUrl = 'https://api-agents.raison-ai.com/v1';

  /// The agent this app reasons with.
  static const String agentId = '1cf91fc368ae';

  /// API key, supplied at build time and never committed:
  ///
  ///     flutter run   --dart-define-from-file=raison.local.json
  ///     flutter build --dart-define-from-file=raison.local.json
  ///
  /// `raison.local.json` is gitignored. An earlier key was a literal here,
  /// which published it the moment the repo went public — and git history
  /// survives in clones and forks, so that one had to be revoked rather than
  /// merely replaced.
  ///
  /// This keeps the key out of the *repository*, not out of the built app: a
  /// value compiled into a mobile binary can still be extracted from it. Only
  /// proxying rAIson+ through a server of our own would fix that.
  static const String _buildKey = String.fromEnvironment('RAISON_API_KEY');

  final http.Client _client;
  final String _key;

  RaisonApiService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _key = apiKey ?? _buildKey;

  /// Sends the questionnaire [responses] to the agent and returns its
  /// decisions. Throws [RaisonQuotaExhausted] when the key's quota is used up.
  Future<List<RaisonResult>> submit(Map<String, dynamic> responses) async {
    // Say which build flag is missing, rather than letting the request come
    // back as an opaque 401/403 that looks like an outage.
    if (_key.isEmpty) {
      throw StateError(
        'RAISON_API_KEY was not set at build time. Pass '
        '--dart-define-from-file=raison.local.json (see README).',
      );
    }

    final requestBody = jsonEncode({
      'facts': <String>[],
      'assumptions': <String>[],
      'data': RaisonPlusInputs.dataFrom(responses),
    });

    final response = await _client.post(
      Uri.parse('$baseUrl/agents/$agentId/reason'),
      headers: {
        'x-api-key': _key,
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    debugPrint('🔍 [rAIson+] REASON POST → ${response.statusCode}\n'
        'Request:  $requestBody\n'
        'Response: ${response.body}');

    if (response.statusCode == 429) throw const RaisonQuotaExhausted();
    if (response.statusCode != 200) {
      throw Exception('rAIson+ request failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('rAIson+ response is not a JSON object');
    }
    return RaisonResult.listFromReason(decoded);
  }
}
