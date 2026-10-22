import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'support_api.g.dart';

/// Contact us and account deletion requests (native `ApiServices`).
@RestApi()
abstract class SupportApi {
  factory SupportApi(Dio dio, {String? baseUrl}) = _SupportApi;

  /// `{user_feedback: {...}}`.
  @POST('current_session/user_feedbacks')
  Future<void> sendFeedback(@Body() Map<String, dynamic> body);
}
