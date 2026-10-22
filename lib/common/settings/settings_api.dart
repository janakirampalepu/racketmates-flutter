import 'package:dio/dio.dart';
import 'package:racketmates/common/settings/settings_models.dart';
import 'package:retrofit/retrofit.dart';

part 'settings_api.g.dart';

/// Reminder, text-consent and device-token endpoints (native `ApiServices`).
@RestApi()
abstract class SettingsApi {
  factory SettingsApi(Dio dio, {String? baseUrl}) = _SettingsApi;

  @GET('users/{userId}/user_reminder_preferences')
  Future<RemindersResponse> reminders(@Path('userId') int userId);

  @POST('users/{userId}/user_reminder_preferences')
  Future<void> createReminder(
    @Path('userId') int userId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('users/{userId}/user_reminder_preferences/{reminderId}')
  Future<void> deleteReminder(
    @Path('userId') int userId,
    @Path('reminderId') int reminderId,
  );

  @PUT('current_session/update_text_consent')
  Future<void> updateTextConsent(@Query('text_consent') bool consent);

  /// Android registers its FCM token form-encoded.
  @POST('current_session/register_device_token')
  @FormUrlEncoded()
  Future<void> registerDeviceTokenForm(
    @Field('device_token') String token,
    @Field('platform') String platform,
    @Field('preferred_language') String language,
  );

  /// iOS registers its APNs token as JSON.
  @POST('current_session/register_device_token')
  Future<void> registerDeviceTokenJson(@Body() Map<String, dynamic> body);

  @POST('current_session/revoke_device_token')
  Future<void> revokeDeviceToken(@Body() Map<String, dynamic> body);
}
