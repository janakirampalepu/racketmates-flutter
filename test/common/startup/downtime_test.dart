import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/startup/downtime.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.responses);

  final Map<String, Object> responses;
  final List<RequestOptions> requests = [];
  int? status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(responses[options.path] ?? <Object>[]),
      status ?? 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object> _incident(
  String name,
  List<String> components, {
  String body = 'We are on it.',
  String? until,
}) => {
  'name': name,
  'status': 'investigating',
  'components': [
    for (final c in components) {'name': c, 'status': 'major_outage'},
  ],
  'incident_updates': [
    {'status': 'investigating', 'body': body},
    {'status': 'identified', 'body': 'older update'},
  ],
  'scheduled_until': ?until,
};

StatusPageDowntimeRepository _repo(
  _Adapter adapter, {
  String page = 'p1',
  String key = 'k1',
}) => StatusPageDowntimeRepository(
  dio: Dio(BaseOptions(baseUrl: 'https://status.example.test/v1/'))
    ..httpClientAdapter = adapter,
  pageId: page,
  apiKey: key,
  component: 'Racketmates API',
);

void main() {
  group('Incident', () {
    test(
      'reads the name, latest update, end of maintenance and components',
      () {
        final i = Incident.fromJson(
          _incident('Planned maintenance', [
            'Racketmates API',
            'Chat Messaging',
          ], until: '2030-01-02T10:30:00.000Z'),
        );
        expect(i.name, 'Planned maintenance');
        expect(i.message, 'We are on it.');
        expect(i.scheduledUntil, DateTime.utc(2030, 1, 2, 10, 30));
        expect(i.components, ['Racketmates API', 'Chat Messaging']);
        expect(i.affects('Racketmates API'), isTrue);
        expect(i.affects('Other'), isFalse);
      },
    );

    test('tolerates missing and odd fields', () {
      final i = Incident.fromJson({
        'incident_updates': <Object>[],
        'components': [
          1,
          null,
          {'name': 5},
        ],
        'scheduled_until': 'soon',
      });
      expect(i.name, isEmpty);
      expect(i.message, isEmpty);
      expect(i.scheduledUntil, isNull);
      expect(i.components, isEmpty);
    });

    test('the first incident that affects the component is chosen', () {
      final a = Incident.fromJson(_incident('chat down', ['Chat Messaging']));
      final b = Incident.fromJson(_incident('api down', ['Racketmates API']));
      expect(firstAffecting([a, b], 'Racketmates API')?.name, 'api down');
      expect(firstAffecting([a], 'Racketmates API'), isNull);
    });
  });

  group('StatusPageDowntimeRepository', () {
    test(
      'an unresolved incident on the API component is the downtime',
      () async {
        final adapter = _Adapter({
          'pages/p1/incidents/unresolved': [
            _incident('chat only', ['Chat Messaging']),
            _incident('API outage', ['Racketmates API']),
          ],
        });
        final incident = await _repo(adapter).currentIncident();
        expect(incident?.name, 'API outage');
        // The key travels as a query parameter, like the native app.
        expect(adapter.requests.first.uri.queryParameters, {'api_key': 'k1'});
        expect(adapter.requests.first.method, 'GET');
        expect(adapter.requests.single.path, 'pages/p1/incidents/unresolved');
      },
    );

    test(
      'an active maintenance window is scheduled maintenance, not a block',
      () async {
        final adapter = _Adapter({
          'pages/p1/incidents/active_maintenance': [
            _incident('Maintenance', [
              'Racketmates API',
            ], until: '2030-01-02T10:30:00Z'),
          ],
        });
        final repo = _repo(adapter);
        expect(await repo.currentIncident(), isNull);
        final incident = await repo.scheduledMaintenance();
        expect(incident?.name, 'Maintenance');
        expect(incident?.scheduledUntil, isNotNull);
        expect(adapter.requests.map((r) => r.path), [
          'pages/p1/incidents/unresolved',
          'pages/p1/incidents/active_maintenance',
        ]);
      },
    );

    test('incidents on other components do not take the app down', () async {
      final adapter = _Adapter({
        'pages/p1/incidents/unresolved': [
          _incident('chat', ['Chat Messaging']),
        ],
        'pages/p1/incidents/active_maintenance': [
          _incident('web', ['Website']),
        ],
      });
      final repo = _repo(adapter);
      expect(await repo.currentIncident(), isNull);
      expect(await repo.scheduledMaintenance(), isNull);
    });

    test(
      'an unreachable or failing status page never blocks the app',
      () async {
        final adapter = _Adapter({})..status = 500;
        final repo = _repo(adapter);
        expect(await repo.currentIncident(), isNull);
        expect(await repo.scheduledMaintenance(), isNull);
      },
    );

    test('an unexpected answer is ignored', () async {
      final adapter = _Adapter({
        'pages/p1/incidents/unresolved': {'oops': 1},
        'pages/p1/incidents/active_maintenance': {'oops': 1},
      });
      final repo = _repo(adapter);
      expect(await repo.currentIncident(), isNull);
      expect(await repo.scheduledMaintenance(), isNull);
    });

    test('without a page id and key nothing is requested', () async {
      final adapter = _Adapter({});
      expect(await _repo(adapter, page: '').currentIncident(), isNull);
      expect(await _repo(adapter, key: '').currentIncident(), isNull);
      expect(await _repo(adapter, page: '').scheduledMaintenance(), isNull);
      expect(await _repo(adapter, key: '').scheduledMaintenance(), isNull);
      expect(adapter.requests, isEmpty);
    });
  });
}
