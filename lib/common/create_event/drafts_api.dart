import 'package:dio/dio.dart';
import 'package:racketmates/common/create_event/drafts_models.dart';
import 'package:retrofit/retrofit.dart';

part 'drafts_api.g.dart';

/// Saved event drafts (native `ApiServices`).
@RestApi()
abstract class DraftsApi {
  factory DraftsApi(Dio dio, {String? baseUrl}) = _DraftsApi;

  @GET('schedule/drafts')
  Future<DraftsResponse> drafts({
    @Query('user_ids[]') List<String>? userIds,
    @Query('status') String? status,
    @Query('team_id') int? teamId,
    @Query('sport_types[]') List<String>? sportTypes,
  });

  /// A draft comes back in the shape it was saved in (the create request).
  @GET('events/{id}')
  Future<dynamic> draft(
    @Path('id') int id, {
    @Query('hour_format') int? hourFormat,
    @Query('view_type') String? viewType,
  });

  @DELETE('events/{id}')
  Future<void> delete(@Path('id') int id);
}
