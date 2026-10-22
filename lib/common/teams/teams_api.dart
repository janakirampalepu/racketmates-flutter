import 'package:dio/dio.dart';
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
}
