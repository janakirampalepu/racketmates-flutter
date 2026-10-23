import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/event_actions_api.dart';
import 'package:racketmates/common/events/event_actions_repository.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object body = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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
  late EventActionsRepositoryImpl repo;

  setUp(() {
    adapter = _Adapter();
    repo = EventActionsRepositoryImpl(
      EventActionsApi(
        Dio(BaseOptions(baseUrl: 'https://api.example.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  test('rounds are generated with an empty body, or the fixed pairs', () async {
    await repo.generateRounds(7);
    expect(adapter.requests.last.method, 'POST');
    expect(adapter.requests.last.path, 'events/7/generate_event_rounds');
    expect(adapter.requests.last.data, <String, dynamic>{});

    await repo.generateRounds(
      7,
      partnerPairs: [
        [1, 2],
        [3, 4],
      ],
    );
    expect(adapter.requests.last.data, {
      'event_partner_pairs': [
        [1, 2],
        [3, 4],
      ],
    });
  });

  test('a 422 that carries a result is an answer, not a failure', () async {
    adapter
      ..status = 422
      ..body = {
        'result': 'egr_insufficient_confirmed_players',
        'event': {'id': 7},
      };
    final response = await repo.generateRounds(7);
    expect(response.result, 'egr_insufficient_confirmed_players');
    expect(response.event?.id, 7);
  });

  test('a 422 without a result is still a failure', () async {
    adapter
      ..status = 422
      ..body = {'message': 'Nope'};
    await expectLater(
      repo.generateRounds(7),
      throwsA(isA<ServerFailure>().having((f) => f.message, 'message', 'Nope')),
    );
  });

  test('rounds and matches use their own paths', () async {
    adapter.body = {
      'event': {'id': 7},
    };
    await repo.addRound(7);
    expect(
      (adapter.requests.last.method, adapter.requests.last.path),
      ('POST', 'events/7/event_rounds'),
    );
    await repo.removeRound(7, 70);
    expect(
      (adapter.requests.last.method, adapter.requests.last.path),
      ('DELETE', 'events/7/event_rounds/70'),
    );
    await repo.removeMatch(7, 500);
    expect(
      (adapter.requests.last.method, adapter.requests.last.path),
      ('DELETE', 'events/7/event_matches/500'),
    );
    await repo.rescheduleMatches(7, {
      'event': {'event_matches_attributes': <Object>[]},
    });
    expect(
      (adapter.requests.last.method, adapter.requests.last.path),
      ('PUT', 'events/7/reschedule_matches'),
    );
    await repo.updateMatches(7, {
      'event': {'event_matches_attributes': <Object>[]},
    });
    expect(
      (adapter.requests.last.method, adapter.requests.last.path),
      ('PUT', 'events/7/update_matches'),
    );
  });

  test('scores are accepted at event level', () async {
    adapter.body = {
      'event': {'id': 7},
    };
    final response = await repo.acceptScores(7);
    expect(
      (adapter.requests.last.method, adapter.requests.last.path),
      ('POST', 'events/7/accept_scores'),
    );
    expect(response.event?.id, 7);
  });

  test(
    'participants are asked for with the confirmed player filters',
    () async {
      adapter.body = {
        'event_participant_groups': [
          {
            'key': 'pairs',
            'event_participant_pairs': [
              [
                {'id': 1, 'user_id': 1},
                {'id': 2, 'user_id': 2},
              ],
            ],
          },
        ],
      };
      final groups = await repo.participants(
        7,
        groupBy: 'pairs',
        include: [1],
        exclude: [2, 3],
        search: 'zo',
        preferredMatchType: 'mt_doubles',
        excludeWithPartner: true,
      );
      final q = adapter.requests.last.uri;
      expect(adapter.requests.last.path, 'events/7/event_participants');
      expect(q.queryParametersAll['roles[]'], ['ur_player']);
      expect(q.queryParametersAll['participant_statuses[]'], ['eus_confirmed']);
      expect(q.queryParametersAll['group_by'], ['pairs']);
      expect(q.queryParametersAll['include_user_ids[]'], ['1']);
      expect(q.queryParametersAll['exclude_user_ids[]'], ['2', '3']);
      expect(q.queryParametersAll['search'], ['zo']);
      expect(q.queryParametersAll['preferred_match_type'], ['mt_doubles']);
      expect(q.queryParametersAll['exclude_participants_with_partner'], [
        'true',
      ]);
      expect(groups.single.eventParticipantPairs!.single, hasLength(2));
    },
  );

  test('empty filters are left out of the query', () async {
    adapter.body = {'event_participants': <Object>[]};
    await repo.participants(7, search: '');
    final q = adapter.requests.last.uri.queryParametersAll;
    expect(q.containsKey('include_user_ids[]'), isFalse);
    expect(q.containsKey('exclude_user_ids[]'), isFalse);
    expect(q.containsKey('search'), isFalse);
    expect(q.containsKey('group_by'), isFalse);
  });

  test('players are assigned with a PUT of the whole round', () async {
    await repo.assignPlayers(7, [
      {'user_id': 1, 'event_match_side_id': 10, 'position': 'epp_center'},
    ]);
    expect(
      (adapter.requests.last.method, adapter.requests.last.path),
      ('PUT', 'events/7/assign_players'),
    );
    expect(adapter.requests.last.data, {
      'event_participants': [
        {'user_id': 1, 'event_match_side_id': 10, 'position': 'epp_center'},
      ],
    });
  });
}
