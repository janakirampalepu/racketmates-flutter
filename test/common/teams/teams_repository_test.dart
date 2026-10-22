import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/teams/teams_api.dart';
import 'package:racketmates/common/teams/teams_repository.dart';

import '../../support/fixtures.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.responses);

  final Map<String, Object> responses;
  final List<RequestOptions> requests = [];
  Object? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    lastBody = options.data;
    final missing = !responses.containsKey(options.path);
    return ResponseBody.fromString(
      jsonEncode(missing ? {'error_message': 'nope'} : responses[options.path]),
      missing ? 404 : 200,
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
  late TeamsRepositoryImpl repo;

  setUp(() {
    adapter = _Adapter({
      'teams': apiFixture('teams_index'),
      'teams/31': apiFixture('teams_show'),
      'teams/31/team_players': apiFixture('teams_team_players'),
    });
    repo = TeamsRepositoryImpl(
      TeamsApi(
        Dio(BaseOptions(baseUrl: 'https://api.example.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  test('my teams request and parsing', () async {
    final teams = await repo.myTeams(userIds: ['7']);
    final q = adapter.requests.single.uri.queryParametersAll;
    expect(adapter.requests.single.method, 'GET');
    expect(q['query_type'], ['user_teams']);
    expect(q['page'], ['1']);
    expect(q['per_page'], ['100']);
    expect(q['user_ids[]'], ['7']);
    expect(q['captain_teams'], ['false']);

    // The null entry is dropped; unknown keys are ignored.
    expect(teams.map((t) => t.id), [31, 32]);
    expect(teams.first.name, 'Sunday Smashers');
    expect(teams.first.sportKeys, ['st_tennis', 'st_padel']);
    expect(teams.first.members, 12);
    expect(teams.last.members, 1);
    expect(teams.first.enablePlayerRanking, isTrue);
  });

  test('captain teams ask for captained teams of the sport', () async {
    await repo.captainTeams(
      userIds: ['7'],
      sportKey: 'st_padel',
      query: ' sun ',
    );
    final q = adapter.requests.single.uri.queryParametersAll;
    expect(q['captain_teams'], ['true']);
    expect(q['archived'], ['false']);
    expect(q['sport_types[]'], ['st_padel']);
    expect(q['search_query'], ['sun']);
  });

  test('captain teams for a sport-less event send no sport filter', () async {
    await repo.captainTeams(userIds: ['7']);
    expect(
      adapter.requests.single.uri.queryParametersAll.containsKey(
        'sport_types[]',
      ),
      isFalse,
    );
  });

  test('details', () async {
    final team = await repo.details(31);
    expect(adapter.requests.single.path, 'teams/31');
    expect(team.name, 'Sunday Smashers');
  });

  test('members request and parsing', () async {
    final members = await repo.members(
      31,
      query: 'al',
      role: 'ur_player',
      sportKey: 'st_tennis',
    );
    final q = adapter.requests.single.uri.queryParametersAll;
    expect(q['roles[]'], ['ur_player']);
    expect(q['sport_types[]'], ['st_tennis']);
    expect(q['include_inactive_members'], ['false']);
    expect(q['search'], ['al']);
    expect(members.map((m) => m.user?.displayName), ['Alex Kim', 'Pat Lee']);
    expect(members.first.isCaptain, isTrue);
    expect(members.last.isCoach, isTrue);
  });

  test('create posts the body as given and returns the team', () async {
    adapter.responses['teams'] = apiFixture('teams_show');
    final team = await repo.create({
      'team': {'name': 'X'},
    });
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.lastBody, {
      'team': {'name': 'X'},
    });
    expect(team.id, 31);
  });

  test('failures map to app failures', () async {
    await expectLater(repo.details(99), throwsA(isA<AppFailure>()));
  });
}
