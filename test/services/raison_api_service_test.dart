import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkinsondetetion/models/raison_result.dart';
import 'package:parkinsondetetion/services/raison_api_service.dart';

void main() {
  group('RaisonApiService.submit', () {
    test('posts the mapped inputs to the agent with the key', () async {
      late http.Request sent;
      final service = RaisonApiService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({
              'decision': 'visit_neurologist',
              'explanation': ['Tremor reported', 'Rigidity reported'],
            }),
            200,
          );
        }),
      );

      final results = await service.submit({'A1': true, 'A3': true});

      expect(sent.method, 'POST');
      expect(
        sent.url.toString(),
        'https://api-agents.raison-ai.com/v1/agents/1cf91fc368ae/reason',
      );
      expect(sent.headers['x-api-key'], 'test-key');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['facts'], isEmpty);
      expect(body['assumptions'], isEmpty);
      expect(body['data'], {
        'tremor': 'yes',
        'rigidity': 'yes',
        'rigidity_with_tremor_or_bradykinesia': 'yes',
      });

      expect(results, hasLength(1));
      expect(results.single.isSolution, isTrue);
      expect(results.single.label, 'Visit neurologist');
      expect(results.single.explanation,
          ['Tremor reported', 'Rigidity reported']);
    });

    test('a used-up quota throws RaisonQuotaExhausted', () async {
      final service = RaisonApiService(
        apiKey: 'test-key',
        client: MockClient((_) async =>
            http.Response(jsonEncode({'quota_exhausted': true}), 429)),
      );
      await expectLater(
        service.submit({}),
        throwsA(isA<RaisonQuotaExhausted>()),
      );
    });

    test('another error status throws', () async {
      final service = RaisonApiService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('nope', 500)),
      );
      await expectLater(service.submit({}), throwsException);
    });

    test('a missing key fails before any request', () async {
      var called = false;
      final service = RaisonApiService(
        apiKey: '',
        client: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(service.submit({}), throwsStateError);
      expect(called, isFalse);
    });
  });

  group('RaisonResult.listFromReason', () {
    test('a list of decisions and the possible options', () {
      final results = RaisonResult.listFromReason({
        'decision': ['visit_neurologist'],
        'possible': ['visit_neurologist', 'no_visit'],
        'explanation': 'Tremor reported\nRigidity reported',
      });
      expect(results.map((r) => r.label),
          ['Visit neurologist', 'No visit']);
      expect(results.map((r) => r.isSolution), [true, false]);
      expect(results.first.explanation,
          ['Tremor reported', 'Rigidity reported']);
    });

    test('decisions given as objects and explanation keyed by decision', () {
      final results = RaisonResult.listFromReason({
        'decision': [
          {'label': 'datscan'},
        ],
        'explanation': {
          'datscan': ['Rigidity with tremor'],
        },
      });
      expect(results.single.label, 'datscan');
      expect(results.single.explanation, ['Rigidity with tremor']);
    });

    test('no decision gives one non-solution, never an empty list', () {
      final results = RaisonResult.listFromReason({'verdict': 'no_decision'});
      expect(results, hasLength(1));
      expect(results.single.isSolution, isFalse);
      expect(results.single.label, 'No decision');
    });
  });
}
