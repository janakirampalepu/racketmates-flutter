import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/teams/create_team_flow.dart';
import 'package:racketmates/common/teams/team_edit.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_api.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _team = Team(
  id: 31,
  name: 'Smashers',
  teamType: TeamTypes.competitive,
  enablePlayerRanking: true,
  teamSports: [
    TeamSport(id: 1, sportType: 'st_tennis'),
    TeamSport(id: 2, sportType: 'st_padel'),
  ],
);

void main() {
  group('edit rules', () {
    test('a team starts as it is', () {
      final edit = TeamEdit.of(_team);
      expect(edit.name, 'Smashers');
      expect(edit.sports, [SportKey.tennis, SportKey.padel]);
      expect(edit.enablePlayerRanking, isTrue);
      expect(teamEditChanged(_team, edit), isFalse);
    });

    test('a name, a type and a sport are required', () {
      final edit = TeamEdit.of(_team)
          .copyWith(name: '  ', teamType: () => null, sports: const []);
      expect(validateTeamEdit(edit), [
        TeamDetailsError.nameRequired,
        TeamDetailsError.typeRequired,
        TeamDetailsError.sportRequired,
      ]);
      expect(() => buildUpdateTeamBody(_team, edit), throwsStateError);
    });

    test('changes are noticed', () {
      final base = TeamEdit.of(_team);
      expect(teamEditChanged(_team, base.copyWith(name: 'Other')), isTrue);
      expect(
        teamEditChanged(_team, base.copyWith(name: ' Smashers ')),
        isFalse,
      );
      expect(
        teamEditChanged(_team, base.copyWith(enablePlayerRanking: false)),
        isTrue,
      );
      expect(
        teamEditChanged(_team, base.copyWith(sports: [SportKey.tennis])),
        isTrue,
      );
      expect(
        teamEditChanged(
          _team,
          base.copyWith(sports: [SportKey.padel, SportKey.tennis]),
        ),
        isFalse,
      );
    });

    test('the update keeps, removes and adds sports', () {
      final edit = TeamEdit.of(_team).copyWith(
        name: ' Net Ninjas ',
        teamType: () => TeamTypes.casual,
        enablePlayerRanking: false,
        sports: [SportKey.tennis, SportKey.pickleball],
      );
      expect(buildUpdateTeamBody(_team, edit), {
        'team': {
          'id': 31,
          'name': 'Net Ninjas',
          'team_type': 'tt_casual',
          'enable_player_ranking': false,
          'team_sports_attributes': [
            {'id': 1, 'sport_type': 'st_tennis'},
            {'id': 2, 'sport_type': 'st_padel', '_destroy': true},
            {'sport_type': 'st_pickleball'},
          ],
        },
      });
    });
  });

  group('team calls', () {
    late _Adapter adapter;
    late TeamsRepositoryImpl repo;

    setUp(() {
      adapter = _Adapter();
      repo = TeamsRepositoryImpl(
        TeamsApi(
          Dio(BaseOptions(baseUrl: 'https://api.example.test'))
            ..httpClientAdapter = adapter,
        ),
      );
    });

    test('update is a PUT of the team', () async {
      await repo.updateTeam(31, {
        'team': {'name': 'X'},
      });
      final r = adapter.requests.single;
      expect(r.method, 'PUT');
      expect(r.path, 'teams/31');
      expect(r.data, {
        'team': {'name': 'X'},
      });
    });

    test('archive, unarchive and delete', () async {
      await repo.archive(31);
      await repo.unarchive(31);
      await repo.deleteTeam(31);
      expect(
        [for (final r in adapter.requests) '${r.method} ${r.path}'],
        ['POST teams/31/archive', 'POST teams/31/unarchive', 'DELETE teams/31'],
      );
    });

    test('server errors become failures', () async {
      adapter.status = 422;
      await expectLater(repo.archive(31), throwsA(isA<AppFailure>()));
    });
  });

  group('create event from a team', () {
    ProviderContainer container() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('the team is fixed and the team steps are skipped', () {
      final c = container();
      final flow = c.read(createEventFlowProvider.notifier)
        ..startForTeam(_team);
      final draft = c.read(createEventFlowProvider)!;
      expect(draft.forTeam, isTrue);
      expect(draft.team?.id, 31);
      expect(draft.teamLocked, isTrue);
      flow.setEventType('et_practice_drill');
      expect(flow.next(CreateEventStep.sport), CreateEventStep.settings);
    });

    test('changing type or sport keeps the team', () {
      final c = container();
      final flow = c.read(createEventFlowProvider.notifier)
        ..startForTeam(_team)
        ..setEventType('et_casual')
        ..setSport(SportKey.tennis)
        ..setEventType('et_competitive');
      expect(c.read(createEventFlowProvider)!.team?.id, 31);
      expect(c.read(createEventFlowProvider)!.forTeam, isTrue);
      expect(
        flow.next(CreateEventStep.sport),
        isNot(CreateEventStep.teamChoice),
      );
    });

    test('a normal start still asks about teams', () {
      final c = container();
      final flow = c.read(createEventFlowProvider.notifier)
        ..start()
        ..setEventType('et_practice_drill');
      expect(flow.next(CreateEventStep.sport), CreateEventStep.teamChoice);
      expect(c.read(createEventFlowProvider)!.teamLocked, isFalse);
    });

    test('games still ask who the team plays when started from a team', () {
      expect(
        createEventStepsFor(
          'et_competitive',
          forTeam: true,
          teamLocked: true,
          opponent: OpponentKind.selectTeam,
        ),
        containsAllInOrder([
          CreateEventStep.sport,
          CreateEventStep.teamDynamics,
          CreateEventStep.opponentSelect,
          CreateEventStep.homeAway,
        ]),
      );
      expect(
        createEventStepsFor('et_competitive', forTeam: true, teamLocked: true),
        isNot(contains(CreateEventStep.teamSelect)),
      );
    });
  });
}
