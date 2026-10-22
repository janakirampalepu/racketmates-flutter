import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/config/environment_config.dart';
import 'package:racketmates/common/auth/auth_api.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/phone_verification.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/phone_verification_api.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';

/// A phone number split the way the backend expects it.
class PhoneNumberParts {
  const PhoneNumberParts({
    required this.nationalNumber,
    required this.countryCode,
    required this.regionCode,
  });

  /// National significant digits only, e.g. `5551234567`.
  final String nationalNumber;

  /// Dial code digits only, e.g. `1`.
  final String countryCode;

  /// ISO region, e.g. `US`.
  final String regionCode;
}

abstract class PhoneVerificationRepository {
  Future<MobileNumberStatus> validateMobileNumber(PhoneNumberParts phone);
  Future<void> sendSmsCode(PhoneNumberParts phone);
  Future<SmsCodePayload> verifySmsCode(PhoneNumberParts phone, String code);

  /// OAuth password grant with the verification code returned by
  /// `verify_sms_code`.
  Future<SessionToken> signIn(PhoneNumberParts phone, String verificationCode);
}

class PhoneVerificationRepositoryImpl implements PhoneVerificationRepository {
  PhoneVerificationRepositoryImpl({
    required this.api,
    required this.authApi,
    required this.config,
    required this.platform,
  });

  static const passwordGrantType = 'password';

  final PhoneVerificationApi api;
  final AuthApi authApi;
  final EnvironmentConfig config;
  final TargetPlatform platform;

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
  Future<MobileNumberStatus> validateMobileNumber(PhoneNumberParts phone) =>
      _guard(
        () => api.verifyMobileNumber({
          'mobile_number': phone.nationalNumber,
          'region_code': phone.regionCode,
          'client_id': config.oauthClientId,
          'client_secret': config.oauthClientSecret,
        }),
      );

  @override
  Future<void> sendSmsCode(PhoneNumberParts phone) => _guard(
    () => api.sendSmsCode(
      SmsCodePayload(
        mobileNumber: phone.nationalNumber,
        countryCode: phone.countryCode,
        regionCode: phone.regionCode,
      ),
      platform == TargetPlatform.iOS ? 'iOS' : 'Android',
    ),
  );

  @override
  Future<SmsCodePayload> verifySmsCode(PhoneNumberParts phone, String code) =>
      _guard(
        () => api.verifySmsCode(
          SmsCodePayload(
            mobileNumber: phone.nationalNumber,
            countryCode: phone.countryCode,
            regionCode: phone.regionCode,
            code: code,
          ),
        ),
      );

  @override
  Future<SessionToken> signIn(
    PhoneNumberParts phone,
    String verificationCode,
  ) => _guard(
    () => authApi.token({
      'client_id': config.oauthClientId,
      'client_secret': config.oauthClientSecret,
      'grant_type': passwordGrantType,
      'username': phone.nationalNumber,
      'verification_code': verificationCode,
    }),
  );
}

final phoneVerificationApiProvider = Provider<PhoneVerificationApi>(
  (ref) => PhoneVerificationApi(ref.watch(authDioProvider)),
);

final phoneVerificationRepositoryProvider =
    Provider<PhoneVerificationRepository>(
      (ref) => PhoneVerificationRepositoryImpl(
        api: ref.watch(phoneVerificationApiProvider),
        authApi: ref.watch(authApiProvider),
        config: ref.watch(environmentConfigProvider),
        platform: defaultTargetPlatform,
      ),
    );
