import 'package:dio/dio.dart';
import 'package:racketmates/common/auth/models/app_metadata.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

/// Existing backend contract (see native `UserApiServices`): `oauth/token`
/// takes a JSON body, `resources/metadata` takes the OAuth client in the query.
/// Used with a Dio that has NO auth interceptor.
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String? baseUrl}) = _AuthApi;

  @POST('oauth/token')
  Future<SessionToken> token(@Body() Map<String, dynamic> body);

  @POST('oauth/revoke')
  Future<void> revokeToken(@Body() Map<String, dynamic> body);

  /// Status filters of the participant lists (`filter_options[]{key,label}`).
  @GET('resources/event_participants_status_filter_options')
  Future<dynamic> participantStatusFilterOptions(
    @Query('client_id') String clientId,
    @Query('client_secret') String clientSecret,
  );

  @GET('resources/metadata')
  Future<AppMetadata> metadata(
    @Query('client_id') String clientId,
    @Query('client_secret') String clientSecret,
    @Query('app_type') String appType,
    @Query('app_version') String appVersion,
  );
}
