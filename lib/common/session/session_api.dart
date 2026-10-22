import 'package:dio/dio.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:retrofit/retrofit.dart';

part 'session_api.g.dart';

/// `current_session` endpoints (same paths on Android and iOS).
@RestApi()
abstract class SessionApi {
  factory SessionApi(Dio dio, {String? baseUrl}) = _SessionApi;

  @GET('current_session/session_info')
  Future<SessionInfoResponse> sessionInfo({
    @Query('app_type') required String appType,
    @Query('version') required String version,
  });

  @PUT('current_session/update_time_zone')
  Future<void> updateTimeZone(@Body() Map<String, dynamic> body);
}
