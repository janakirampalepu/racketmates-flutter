import 'package:dio/dio.dart';
import 'package:racketmates/common/auth/models/phone_verification.dart';
import 'package:retrofit/retrofit.dart';

part 'phone_verification_api.g.dart';

/// Pre-login phone verification endpoints (existing backend contract). Uses the
/// Dio WITHOUT the auth interceptor.
@RestApi()
abstract class PhoneVerificationApi {
  factory PhoneVerificationApi(Dio dio, {String? baseUrl}) =
      _PhoneVerificationApi;

  @POST('validations/verify_mobile_number')
  Future<MobileNumberStatus> verifyMobileNumber(
    @Body() Map<String, dynamic> body,
  );

  /// The native Android app sends `UserAgent: Android` on this call.
  @POST('verifications/send_sms_code')
  Future<SmsCodePayload> sendSmsCode(
    @Body() SmsCodePayload body,
    @Header('UserAgent') String userAgent,
  );

  @POST('verifications/verify_sms_code')
  Future<SmsCodePayload> verifySmsCode(@Body() SmsCodePayload body);
}
