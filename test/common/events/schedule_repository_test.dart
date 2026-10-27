import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/schedule_api.dart';
import 'package:racketmates/common/events/schedule_repository.dart';

import '../../support/fixtures.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.responses);

  final Map<String, Object> responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = responses[options.path] ?? <String, dynamic>{};
    final status = options.path == 'events/404' ? 404 : 200;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Adapter adapter;
  late ScheduleRepositoryImpl repo;

  setUp(() {
    adapter = _Adapter({
      'schedule/scheduled_events': apiFixture('schedule_scheduled_events'),
      'current_session/pending_actions': apiFixture(
        'current_session_pending_actions',
      ),
      'current_session/stats_summary': apiFixture(
        'current_session_stats_summary',
      ),
      'current_session/player_cards': apiFixture(
        'current_session_player_cards',
      ),
      'events/101': apiFixture('events_show'),
      'events/404': {'error_message': 'not found'},
    });
    repo = ScheduleRepositoryImpl(
      ScheduleApi(
        Dio(BaseOptions(baseUrl: 'https://api.example.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  test('home upcoming request matches the native query contract', () async {
    final items = await repo.homeUpcoming(userIds: ['7', '8'], hourFormat: 24);
    expect(items, hasLength(2));
    final q = adapter.requests.single.uri.queryParametersAll;
    expect(adapter.requests.single.path, 'schedule/scheduled_events');
    expect(q['per_page'], ['3']);
    expect(q['page'], ['1']);
    expect(q['events_for'], ['home_page_upcoming']);
    expect(q['user_ids[]'], ['7', '8']);
    expect(q['event_roles[]'], ['managing', 'participant']);
    expect(q['hour_format'], ['24']);
    expect(q.containsKey('time_period'), isFalse);
    expect(q.containsKey('team_id'), isFalse);
  });

  test('home past uses events_for=past and time_period=past', () async {
    await repo.homePast(userIds: ['7'], hourFormat: 12);
    final q = adapter.requests.single.uri.queryParametersAll;
    expect(q['events_for'], ['past']);
    expect(q['time_period'], ['past']);
    expect(q['per_page'], ['3']);
  });

  test(
    'schedule pages: upcoming = upcoming/future, past = past/past, 10 per page',
    () async {
      await repo.schedulePage(
        tab: ScheduleTab.upcoming,
        page: 2,
        userIds: ['7'],
        hourFormat: 12,
      );
      await repo.schedulePage(
        tab: ScheduleTab.past,
        page: 1,
        userIds: ['7'],
        hourFormat: 12,
      );
      final up = adapter.requests[0].uri.queryParametersAll;
      expect(up['events_for'], ['upcoming']);
      expect(up['time_period'], ['future']);
      expect(up['per_page'], ['10']);
      expect(up['page'], ['2']);
      final past = adapter.requests[1].uri.queryParametersAll;
      expect(past['events_for'], ['past']);
      expect(past['time_period'], ['past']);
    },
  );

  test(
    'pending actions, stats and cards use the current_session endpoints',
    () async {
      expect(await repo.pendingActions(userIds: ['7']), hasLength(1));
      expect(await repo.activitySummary(userIds: ['7']), hasLength(1));
      expect(await repo.latestUpdates(userIds: ['7']), hasLength(1));
      final cards = adapter.requests[2].uri.queryParametersAll;
      expect(cards['card_types[]'], ['pct_player_event_result_update']);
      expect(cards['user_ids[]'], ['7']);
      expect(adapter.requests.map((r) => r.path), [
        'current_session/pending_actions',
        'current_session/stats_summary',
        'current_session/player_cards',
      ]);
    },
  );

  test('event details: participant view with hour format', () async {
    final event = await repo.eventDetails(101, hourFormat: 12);
    expect(event.id, 101);
    final q = adapter.requests.single.uri.queryParametersAll;
    expect(q['view_type'], ['participant']);
    expect(q['hour_format'], ['12']);
  });

  test('HTTP errors become AppFailures with the server message', () async {
    await expectLater(
      repo.eventDetails(404, hourFormat: 12),
      throwsA(
        isA<ServerFailure>().having((f) => f.message, 'message', 'not found'),
      ),
    );
  });

  test('a response-shape mismatch becomes a ParseFailure carrying the real cast error', () async {
    adapter.responses['schedule/scheduled_events'] = {
      'schedule_items': [
        {'event_id': 'not-an-int'},
      ],
    };
    await expectLater(
      repo.homeUpcoming(userIds: const ['7'], hourFormat: 12),
      throwsA(
        isA<ParseFailure>().having((f) => f.message, 'message', isNotEmpty),
      ),
    );
  });
}
