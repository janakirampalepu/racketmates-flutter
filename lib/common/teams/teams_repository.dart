import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_api.dart';

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
  }) async {
    final response = await _guard(
      () => api.members(
        teamId,
        page: 1,
        perPage: teamsPageSize,
        sportTypes: sportKey == null ? null : [sportKey],
        roles: role == null ? null : [role],
        includeInactiveMembers: false,
        search: query.trim(),
      ),
    );
    return response.teamPlayers?.whereType<TeamPlayer>().toList() ?? const [];
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
