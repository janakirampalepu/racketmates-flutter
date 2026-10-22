import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/models/phone_verification.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_args.dart';
import 'package:racketmates/screens/phone_entry/usecases/submit_phone_number.dart';

import '../../support/fakes.dart';

const _phone = PhoneNumberParts(
  nationalNumber: '5551234567',
  countryCode: '1',
  regionCode: 'US',
);

void main() {
  Future<SubmitPhoneResult> run(
    PhoneEntryMode mode, {
    required bool userExist,
    required bool isSignedUp,
    FakePhoneVerificationRepository? repo,
  }) {
    repo ??= FakePhoneVerificationRepository();
    repo.status = MobileNumberStatus(
      userExist: userExist,
      isSignedUp: isSignedUp,
    );
    return SubmitPhoneNumberUseCase(repo)(_phone, mode);
  }

  test('sign in with a registered number sends the code', () async {
    final repo = FakePhoneVerificationRepository();
    final result = await run(
      PhoneEntryMode.signIn,
      userExist: true,
      isSignedUp: true,
      repo: repo,
    );
    expect(result, isA<CodeSent>());
    expect(repo.sent.single.nationalNumber, '5551234567');
  });

  test('sign up with a new number sends the code', () async {
    final result = await run(
      PhoneEntryMode.signUp,
      userExist: false,
      isSignedUp: false,
    );
    expect((result as CodeSent).mode, PhoneEntryMode.signUp);
  });

  test('sign up with a registered number asks to switch to sign in', () async {
    final repo = FakePhoneVerificationRepository();
    final result = await run(
      PhoneEntryMode.signUp,
      userExist: true,
      isSignedUp: true,
      repo: repo,
    );
    expect((result as ModeMismatch).suggestedMode, PhoneEntryMode.signIn);
    expect(repo.sent, isEmpty);
  });

  test(
    'sign in with an unregistered number asks to switch to sign up',
    () async {
      for (final status in [(false, false), (true, false), (false, true)]) {
        final repo = FakePhoneVerificationRepository();
        final result = await run(
          PhoneEntryMode.signIn,
          userExist: status.$1,
          isSignedUp: status.$2,
          repo: repo,
        );
        expect((result as ModeMismatch).suggestedMode, PhoneEntryMode.signUp);
        expect(repo.sent, isEmpty);
      }
    },
  );

  test('sendCode after the user accepted the switch', () async {
    final repo = FakePhoneVerificationRepository();
    final result = await SubmitPhoneNumberUseCase(repo)
        .sendCode(_phone, PhoneEntryMode.signIn);
    expect((result as CodeSent).mode, PhoneEntryMode.signIn);
    expect(repo.sent, hasLength(1));
  });
}
