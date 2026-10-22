import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_api.dart';
import 'package:racketmates/common/teams/teams_repository.dart';

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

TeamPlayer _m(
  int id, {
  bool captain = false,
  bool player = true,
  bool inactive = false,
}) => TeamPlayer(
  id: id,
  isCaptain: captain,
  isPlayer: player,
  inactivatedAt: inactive ? '2026-01-01' : null,
);

void main() {
  group('team API contracts', () {
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

    test('members can include the deactivated ones', () async {
      adapter.body = {'team_players': <Object>[]};
      await repo.members(31, includeInactive: true);
      final q = adapter.requests.single.uri.queryParametersAll;
      expect(adapter.requests.single.path, 'teams/31/team_players');
      expect(q['include_inactive_members'], ['true']);
    });

    test('rankings: sport, period and match type', () async {
      adapter.body = {
        'team_players': [
          {
            'id': 5,
            'current_rank': 1,
            'previous_rank': 3,
            'wins': 4,
            'losses': 1,
            'total_points': 120,
            'user': {'id': 9, 'first_name': 'Ann'},
          },
        ],
      };
      final list = await repo.rankings(
        31,
        sportKey: 'st_tennis',
        period: 'rpd_all_time',
        matchType: 'mt_singles',
      );
      final r = adapter.requests.single;
      expect(r.path, 'teams/31/team_players/member_rankings');
      final q = r.uri.queryParametersAll;
      expect(q['sport_type'], ['st_tennis']);
      expect(q['ranking_period'], ['rpd_all_time']);
      expect(q['match_type'], ['mt_singles']);
      expect(list.single.currentRank, 1);
      expect(list.single.totalPoints, 120);
      expect(rankChange(list.single), 2);
    });

    test('deactivate and reactivate are POSTs', () async {
      await repo.setMemberActive(31, 5, active: false);
      await repo.setMemberActive(31, 5, active: true);
      expect(adapter.requests[0].method, 'POST');
      expect(adapter.requests[0].path, 'teams/31/team_players/5/inactivate');
      expect(adapter.requests[1].path, 'teams/31/team_players/5/reactivate');
    });

    test('roles are a PUT with the three flags', () async {
      await repo.updateMemberRoles(
        31,
        5,
        captain: true,
        coach: false,
        player: true,
      );
      final r = adapter.requests.single;
      expect(r.method, 'PUT');
      expect(r.path, 'teams/31/team_players/5');
      expect(r.data, {
        'team_player': {
          'is_captain': true,
          'is_coach': false,
          'is_player': true,
        },
      });
    });

    test('removing a member is a DELETE', () async {
      await repo.removeMember(31, 5);
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, 'teams/31/team_players/5');
    });

    test(
      'adding members is a PUT of the team with player attributes',
      () async {
        await repo.addMembers(31, [
          {
            'user_id': 9,
            'is_captain': false,
            'is_player': true,
            'is_coach': false,
          },
        ]);
        final r = adapter.requests.single;
        expect(r.method, 'PUT');
        expect(r.path, 'teams/31');
        expect(r.data, {
          'team': {
            'team_players_attributes': [
              {
                'user_id': 9,
                'is_captain': false,
                'is_player': true,
                'is_coach': false,
              },
            ],
          },
        });
      },
    );

    test(
      'people outside the team are searched with the team excluded',
      () async {
        adapter.body = {
          'users': [
            {'id': 3, 'first_name': 'Bo'},
          ],
        };
        final users = await repo.searchNonMembers(
          31,
          query: ' bo ',
          sportKeys: ['st_tennis'],
        );
        final q = adapter.requests.single.uri.queryParametersAll;
        expect(adapter.requests.single.path, 'users');
        expect(q['exclude_team_id'], ['31']);
        expect(q['search'], ['bo']);
        expect(q['is_signed_up'], ['true']);
        expect(q['sport_types[]'], ['st_tennis']);
        expect(users.single.id, 3);
      },
    );

    test('server errors become failures', () async {
      adapter
        ..status = 403
        ..body = {'error_message': 'no'};
      await expectLater(repo.removeMember(31, 5), throwsA(isA<AppFailure>()));
    });

    test('a team carries its permissions', () async {
      final team = Team.fromJson({
        'id': 31,
        'user_permissions': {
          'team.team_players.update': {'access': 'up_enabled'},
          'team.team_players.destroy': {
            'access': 'up_disabled',
            'message': 'Not now',
          },
        },
      });
      expect(team.permission('team.team_players.update')?.enabled, isTrue);
      expect(team.permission('team.team_players.destroy')?.message, 'Not now');
      expect(team.permission('nothing'), isNull);
    });
  });

  group('member rules', () {
    test('only the sole active captain is protected', () {
      final all = [
        _m(1, captain: true),
        _m(2),
        _m(3, captain: true, inactive: true),
      ];
      expect(isOnlyCaptain(all, all[0]), isTrue);
      expect(isOnlyCaptain(all, all[1]), isFalse);
      final two = [_m(1, captain: true), _m(2, captain: true)];
      expect(isOnlyCaptain(two, two[0]), isFalse);
    });

    test('roles: at least one, and the only captain stays captain', () {
      final all = [_m(1, captain: true), _m(2)];
      expect(
        rolesAllowed(all, all[1], captain: false, coach: false, player: false),
        isFalse,
      );
      expect(
        rolesAllowed(all, all[1], captain: true, coach: false, player: true),
        isTrue,
      );
      expect(
        rolesAllowed(all, all[0], captain: false, coach: false, player: true),
        isFalse,
      );
      expect(
        rolesAllowed(all, all[0], captain: true, coach: true, player: false),
        isTrue,
      );
    });

    test('member actions follow the permission', () {
      const team = Team(
        userPermissions: {
          'team.team_players.update': AccessInfo(access: 'up_enabled'),
          'team.team_players.destroy': AccessInfo(
            access: 'up_requires_subscription',
          ),
          'team.team_players.inactivate': AccessInfo(access: 'up_disabled'),
          'team.team_players.create': AccessInfo(access: 'up_not_available'),
        },
      );
      expect(
        memberAccess(team, TeamPermissions.updateMember, subscribed: true),
        AccessDecision.allowed,
      );
      expect(
        memberAccess(team, TeamPermissions.removeMember, subscribed: false),
        AccessDecision.needsSubscription,
      );
      expect(
        memberAccess(team, TeamPermissions.deactivateMember, subscribed: true),
        AccessDecision.blocked,
      );
      expect(
        memberAccess(team, TeamPermissions.addMembers, subscribed: true),
        AccessDecision.hidden,
      );
    });

    test('an action without a permission is not offered', () {
      expect(
        memberAccess(
          const Team(),
          TeamPermissions.updateMember,
          subscribed: true,
        ),
        AccessDecision.hidden,
      );
    });

    test('rank movement', () {
      expect(rankChange(const TeamPlayer(currentRank: 2, previousRank: 5)), 3);
      expect(rankChange(const TeamPlayer(currentRank: 5, previousRank: 2)), -3);
      expect(rankChange(const TeamPlayer(currentRank: 2)), isNull);
    });
  });
}
