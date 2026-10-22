import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/phone_verification_api.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';

import '../support/fakes.dart';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body, {this.status = 200});

  final String body;
  final int status;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _phone = PhoneNumberParts(
  nationalNumber: '5551234567',
  countryCode: '1',
  regionCode: 'US',
);

PhoneVerificationRepositoryImpl _repo(
  Dio dio,
  FakeAuthApi authApi, {
  TargetPlatform platform = TargetPlatform.android,
}) => PhoneVerificationRepositoryImpl(
  api: PhoneVerificationApi(dio),
  authApi: authApi,
  config: testConfig,
  platform: platform,
);

void main() {
  Dio dio(_RecordingAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;

  test('verify_mobile_number request/response contract', () async {
    final adapter = _RecordingAdapter(
      '{"user_exist":true,"is_signed_up":false}',
    );
    final status = await _repo(
      dio(adapter),
      FakeAuthApi(),
    ).validateMobileNumber(_phone);
    expect(adapter.last!.path, 'validations/verify_mobile_number');
    expect(adapter.last!.data, {
      'mobile_number': '5551234567',
      'region_code': 'US',
      'client_id': 'client-id',
      'client_secret': 'client-secret',
    });
    expect(status.userExist, isTrue);
    expect(status.isRegistered, isFalse);
  });

  test('send_sms_code body and platform user agent header', () async {
    final adapter = _RecordingAdapter('{}');
    await _repo(
      dio(adapter),
      FakeAuthApi(),
      platform: TargetPlatform.iOS,
    ).sendSmsCode(_phone);
    expect(adapter.last!.path, 'verifications/send_sms_code');
    expect(adapter.last!.data, {
      'mobile_number': '5551234567',
      'country_code': '1',
      'region_code': 'US',
    });
    expect(adapter.last!.headers['UserAgent'], 'iOS');
  });

  test('verify_sms_code body and response parsing', () async {
    final adapter = _RecordingAdapter(
      '{"valid":true,"player_exist":true,"is_signed_up":true,"verification_code":"abc"}',
    );
    final result = await _repo(
      dio(adapter),
      FakeAuthApi(),
    ).verifySmsCode(_phone, '123456');
    expect(adapter.last!.path, 'verifications/verify_sms_code');
    expect((adapter.last!.data as Map)['code'], '123456');
    expect(result.valid, isTrue);
    expect(result.verificationCode, 'abc');
  });

  test('sign in uses the password grant with the verification code', () async {
    final authApi = FakeAuthApi(tokenResults: [token()]);
    await _repo(dio(_RecordingAdapter('{}')), authApi).signIn(_phone, 'vc');
    expect(authApi.tokenBodies.single, {
      'client_id': 'client-id',
      'client_secret': 'client-secret',
      'grant_type': 'password',
      'username': '5551234567',
      'verification_code': 'vc',
    });
  });

  test('HTTP errors become AppFailures with the server message', () async {
    final adapter = _RecordingAdapter('{"error_message":"nope"}', status: 422);
    await expectLater(
      _repo(dio(adapter), FakeAuthApi()).sendSmsCode(_phone),
      throwsA(isA<ServerFailure>().having((f) => f.message, 'message', 'nope')),
    );
  });
}
