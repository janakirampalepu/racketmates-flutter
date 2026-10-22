import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/models/phone_verification.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/screens/otp/usecases/verify_otp.dart';

import '../../support/fakes.dart';

const _phone = PhoneNumberParts(
  nationalNumber: '5551234567',
  countryCode: '1',
  regionCode: 'US',
);

void main() {
  test('valid code, existing signed-up player: password grant with the returned verification code', () async {
    final repo = FakePhoneVerificationRepository();
    final outcome = await VerifyOtpUseCase(repo)(_phone, '123456');
    expect(outcome, isA<OtpSignedIn>());
    expect(repo.verifiedCodes, ['123456']);
    expect(repo.signInCodes, ['vcode']);
  });

  test('invalid code', () async {
    final repo = FakePhoneVerificationRepository(
      verifyResult: const SmsCodePayload(valid: false),
    );
    expect(
      await VerifyOtpUseCase(repo)(_phone, '000000'),
      isA<OtpInvalidCode>(),
    );
    expect(repo.signInCodes, isEmpty);
  });

  test('valid code for a new number requires sign-up', () async {
    final repo = FakePhoneVerificationRepository(
      verifyResult: const SmsCodePayload(
        valid: true,
        playerExist: false,
        verificationCode: 'new',
      ),
    );
    final outcome = await VerifyOtpUseCase(repo)(_phone, '123456');
    final required = outcome as OtpSignUpRequired;
    expect(required.resume, isFalse);
    expect(required.token, isNull);
    expect(repo.signInCodes, isEmpty);
  });

  test(
    'existing player who never finished sign-up resumes it with a fresh token',
    () async {
      final repo = FakePhoneVerificationRepository(
        verifyResult: const SmsCodePayload(
          valid: true,
          playerExist: true,
          isSignedUp: false,
          verificationCode: 'v',
        ),
      );
      final outcome = await VerifyOtpUseCase(repo)(_phone, '123456');
      final required = outcome as OtpSignUpRequired;
      expect(required.resume, isTrue);
      expect(required.verificationCode, 'v');
      expect(required.token?.accessToken, 'signed-in');
      expect(repo.signInCodes, ['v']);
    },
  );
}
