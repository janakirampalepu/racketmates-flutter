import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/sign_up/create_account.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';

import '../../support/fakes.dart';

const _phone = PhoneNumberParts(
  nationalNumber: '5551234567',
  countryCode: '1',
  regionCode: 'US',
);

void main() {
  SignUpDraft draft({bool resume = false}) => SignUpDraft(
    phone: _phone,
    verificationCode: 'vc',
    resume: resume,
    userId: resume ? 7 : null,
    firstName: 'Sam',
    lastName: 'Lee',
    roles: const {RoleKeys.player},
    playerSports: const {SportKey.tennis},
  );

  test(
    'new account: POST users then password grant with the stored code',
    () async {
      final pre = FakeUserRepository();
      final authed = FakeUserRepository();
      final phone = FakePhoneVerificationRepository();
      final result = await CreateAccountUseCase(
        preLoginUsers: pre,
        users: authed,
        phone: phone,
      )(draft());
      expect(pre.created, hasLength(1));
      expect(authed.updated, isEmpty);
      expect(phone.signInCodes, ['vc']);
      expect(result.token?.accessToken, 'signed-in');
      expect(result.user?.id, 7);
    },
  );

  test(
    'resume: PUT users/{id} with the existing session, no new token',
    () async {
      final pre = FakeUserRepository();
      final authed = FakeUserRepository();
      final phone = FakePhoneVerificationRepository();
      final result = await CreateAccountUseCase(
        preLoginUsers: pre,
        users: authed,
        phone: phone,
      )(draft(resume: true));
      expect(pre.created, isEmpty);
      expect(authed.updated.single.$1, 7);
      expect(phone.signInCodes, isEmpty);
      expect(result.token, isNull);
    },
  );
}
