import 'package:dio/dio.dart';
import 'package:racketmates/common/create_event/create_event_api.dart'
    show UserSearchResponse;
import 'package:racketmates/common/teams/team_models.dart';
import 'package:retrofit/retrofit.dart';

part 'teams_api.g.dart';

/// Existing `teams` endpoints (native `ApiServices`).
@RestApi()
abstract class TeamsApi {
  factory TeamsApi(Dio dio, {String? baseUrl}) = _TeamsApi;

  @GET('teams')
  Future<TeamsListResponse> list({
    @Query('archived') bool? archived,
    @Query('query_type') String? queryType,
    @Query('page') int? page,
    @Query('per_page') int? perPage,
    @Query('search_query') String? searchQuery,
    @Query('exclude_team_id') int? excludeTeamId,
    @Query('user_ids[]') List<String>? userIds,
    @Query('captain_teams') bool? captainTeams,
    @Query('sport_types[]') List<String>? sportTypes,
  });

  @GET('teams/{id}')
  Future<TeamResponse> details(@Path('id') int id);

  @GET('teams/{id}/team_players')
  Future<TeamMembersResponse> members(
    @Path('id') int id, {
    @Query('page') int? page,
    @Query('per_page') int? perPage,
    @Query('sport_types[]') List<String>? sportTypes,
    @Query('roles[]') List<String>? roles,
    @Query('include_inactive_members') bool? includeInactiveMembers,
    @Query('search') String? search,
  });

  @POST('teams')
  Future<TeamResponse> create(@Body() Map<String, dynamic> body);

  /// Members with their rank, wins, losses and points for a sport and period.
  @GET('teams/{id}/team_players/member_rankings')
  Future<TeamMembersResponse> memberRankings(
    @Path('id') int id, {
    @Query('page') int? page,
    @Query('per_page') int? perPage,
    @Query('sport_type') String? sportType,
    @Query('search') String? search,
    @Query('ranking_period') String? rankingPeriod,
    @Query('match_type') String? matchType,
  });

  @POST('teams/{id}/team_players/{playerId}/inactivate')
  Future<void> inactivate(@Path('id') int id, @Path('playerId') int playerId);

  @POST('teams/{id}/team_players/{playerId}/reactivate')
  Future<void> reactivate(@Path('id') int id, @Path('playerId') int playerId);

  /// `{team_player: {is_captain, is_coach, is_player}}`.
  @PUT('teams/{id}/team_players/{playerId}')
  Future<void> updateRoles(
    @Path('id') int id,
    @Path('playerId') int playerId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('teams/{id}/team_players/{playerId}')
  Future<void> removeMember(@Path('id') int id, @Path('playerId') int playerId);

  /// `{team: {team_players_attributes: [...]}}`: adds people to the team.
  @PUT('teams/{id}')
  Future<void> addMembers(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  /// People who are not in the team yet.
  @GET('users')
  Future<UserSearchResponse> searchNonMembers({
    @Query('search') String? search,
    @Query('exclude_team_id') int? excludeTeamId,
    @Query('is_signed_up') bool? isSignedUp,
    @Query('sport_types[]') List<String>? sportTypes,
  });

  /// `{team: {id, name, team_type, team_sports_attributes, enable_player_ranking}}`.
  @PUT('teams/{id}')
  Future<void> updateTeam(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @POST('teams/{id}/archive')
  Future<void> archive(@Path('id') int id);

  @POST('teams/{id}/unarchive')
  Future<void> unarchive(@Path('id') int id);

  @DELETE('teams/{id}')
  Future<void> deleteTeam(@Path('id') int id);
}
