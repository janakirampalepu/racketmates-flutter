import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_api.dart';
import 'package:racketmates/common/users/models/app_user.dart';

/// Native `AppConstants.USER_TEAMS`.
const userTeamsQueryType = 'user_teams';

/// Native `AppConstants.NON_LEAGUE_TEAMS`: every team outside a league.
const nonLeagueTeamsQueryType = 'non_league_teams';

/// Teams are loaded in one page (native `VALUE_HUNDRED`).
const teamsPageSize = 100;

abstract class TeamsRepository {
  /// Active teams of [userIds].
  Future<List<Team>> myTeams({required List<String> userIds});

  /// Teams the user captains, for creating a team event: limited to teams
  /// playing [sportKey] when given, matching [query].
  Future<List<Team>> captainTeams({
    required List<String> userIds,
    String? sportKey,
    String query = '',
  });

  /// Teams a team can play against: every non-league team except
  /// [excludeTeamId], playing [sportKey] when given, matching [query].
  Future<List<Team>> opponentTeams({
    required int excludeTeamId,
    String? sportKey,
    String query = '',
  });

  Future<Team> details(int id);

  /// Active members of a team, filtered by [role] (`ur_player`, `ur_coach`),
  /// [sportKey] and the [query] text.
  Future<List<TeamPlayer>> members(
    int teamId, {
    String query = '',
    String? role,
    String? sportKey,
    bool includeInactive = false,
  });

  /// Members ranked for [sportKey] over [period] (`rpd_*`) and [matchType]
  /// (`mt_singles`, `mt_doubles`, null = all).
  Future<List<TeamPlayer>> rankings(
    int teamId, {
    required String sportKey,
    String? period,
    String? matchType,
  });

  Future<void> setMemberActive(
    int teamId,
    int teamPlayerId, {
    required bool active,
  });

  Future<void> updateMemberRoles(
    int teamId,
    int teamPlayerId, {
    required bool captain,
    required bool coach,
    required bool player,
  });

  Future<void> removeMember(int teamId, int teamPlayerId);

  /// Adds people with their roles: `{user_id, is_captain, is_coach, is_player}`.
  Future<void> addMembers(int teamId, List<Map<String, dynamic>> members);

  /// People outside the team matching [query] (and playing one of
  /// [sportKeys]).
  Future<List<AppUser>> searchNonMembers(
    int teamId, {
    String query = '',
    List<String> sportKeys = const [],
  });

  /// `POST teams`; returns the created team.
  Future<Team> create(Map<String, dynamic> body);
}

class TeamsRepositoryImpl implements TeamsRepository {
  const TeamsRepositoryImpl(this.api);

  final TeamsApi api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioException(e);
    } on TypeError {
      throw const ParseFailure();
    }
  }

  @override
  Future<List<Team>> myTeams({required List<String> userIds}) async {
    final response = await _guard(
      () => api.list(
        queryType: userTeamsQueryType,
        page: 1,
        perPage: teamsPageSize,
        userIds: userIds,
        captainTeams: false,
      ),
    );
    return response.teams?.whereType<Team>().toList() ?? const [];
  }

  @override
  Future<List<Team>> captainTeams({
    required List<String> userIds,
    String? sportKey,
    String query = '',
  }) async {
    final response = await _guard(
      () => api.list(
        archived: false,
        queryType: userTeamsQueryType,
        page: 1,
        perPage: teamsPageSize,
        searchQuery: query.trim(),
        userIds: userIds,
        captainTeams: true,
        sportTypes: sportKey == null ? null : [sportKey],
      ),
    );
    return response.teams?.whereType<Team>().toList() ?? const [];
  }

  @override
  Future<List<Team>> opponentTeams({
    required int excludeTeamId,
    String? sportKey,
    String query = '',
  }) async {
    final response = await _guard(
      () => api.list(
        archived: false,
        queryType: nonLeagueTeamsQueryType,
        page: 1,
        perPage: teamsPageSize,
        searchQuery: query.trim(),
        excludeTeamId: excludeTeamId,
        captainTeams: false,
        sportTypes: sportKey == null ? null : [sportKey],
      ),
    );
    return response.teams?.whereType<Team>().toList() ?? const [];
  }

  @override
  Future<Team> details(int id) async {
    final team = (await _guard(() => api.details(id))).team;
    if (team == null) throw const ParseFailure('team missing');
    return team;
  }

  @override
  Future<List<TeamPlayer>> members(
    int teamId, {
    String query = '',
    String? role,
    String? sportKey,
    bool includeInactive = false,
  }) async {
    final response = await _guard(
      () => api.members(
        teamId,
        page: 1,
        perPage: teamsPageSize,
        sportTypes: sportKey == null ? null : [sportKey],
        roles: role == null ? null : [role],
        includeInactiveMembers: includeInactive,
        search: query.trim(),
      ),
    );
    return response.teamPlayers?.whereType<TeamPlayer>().toList() ?? const [];
  }

  @override
  Future<List<TeamPlayer>> rankings(
    int teamId, {
    required String sportKey,
    String? period,
    String? matchType,
  }) async {
    final response = await _guard(
      () => api.memberRankings(
        teamId,
        page: 1,
        perPage: teamsPageSize,
        sportType: sportKey,
        search: '',
        rankingPeriod: period,
        matchType: matchType,
      ),
    );
    return response.teamPlayers?.whereType<TeamPlayer>().toList() ?? const [];
  }

  @override
  Future<void> setMemberActive(
    int teamId,
    int teamPlayerId, {
    required bool active,
  }) => _guard(
    () => active
        ? api.reactivate(teamId, teamPlayerId)
        : api.inactivate(teamId, teamPlayerId),
  );

  @override
  Future<void> updateMemberRoles(
    int teamId,
    int teamPlayerId, {
    required bool captain,
    required bool coach,
    required bool player,
  }) => _guard(
    () => api.updateRoles(teamId, teamPlayerId, {
      'team_player': {
        'is_captain': captain,
        'is_coach': coach,
        'is_player': player,
      },
    }),
  );

  @override
  Future<void> removeMember(int teamId, int teamPlayerId) =>
      _guard(() => api.removeMember(teamId, teamPlayerId));

  @override
  Future<void> addMembers(int teamId, List<Map<String, dynamic>> members) =>
      _guard(
        () => api.addMembers(teamId, {
          'team': {'team_players_attributes': members},
        }),
      );

  @override
  Future<List<AppUser>> searchNonMembers(
    int teamId, {
    String query = '',
    List<String> sportKeys = const [],
  }) async {
    final response = await _guard(
      () => api.searchNonMembers(
        search: query.trim(),
        excludeTeamId: teamId,
        isSignedUp: true,
        sportTypes: sportKeys.isEmpty ? null : sportKeys,
      ),
    );
    return response.users ?? const [];
  }

  @override
  Future<Team> create(Map<String, dynamic> body) async {
    final team = (await _guard(() => api.create(body))).team;
    if (team == null) throw const ParseFailure('team missing');
    return team;
  }
}

final teamsRepositoryProvider = Provider<TeamsRepository>(
  (ref) => TeamsRepositoryImpl(TeamsApi(ref.watch(apiDioProvider))),
);
