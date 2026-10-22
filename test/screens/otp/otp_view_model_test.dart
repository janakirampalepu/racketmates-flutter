import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/phone_verification.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/screens/otp/otp_args.dart';
import 'package:racketmates/screens/otp/otp_view_model.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_args.dart';

import '../../support/fakes.dart';

const _args = OtpArgs(
  phone: PhoneNumberParts(
    nationalNumber: '5551234567',
    countryCode: '1',
    regionCode: 'US',
  ),
  country: Country(
    name: 'United States',
    flag: '🇺🇸',
    regionCode: 'US',
    dialCode: '+1',
    pattern: '(###) ### - ####',
  ),
  mode: PhoneEntryMode.signIn,
);

ProviderContainer _container(
  FakePhoneVerificationRepository repo,
  InMemoryTokenStore store,
) {
  final c = ProviderContainer(
    overrides: [
      phoneVerificationRepositoryProvider.overrideWithValue(repo),
      tokenStoreProvider.overrideWithValue(store),
      authApiProvider.overrideWithValue(FakeAuthApi()),
      environmentConfigProvider.overrideWithValue(testConfig),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('entering 6 digits verifies and signs the session in', () async {
    final repo = FakePhoneVerificationRepository();
    final store = InMemoryTokenStore();
    final c = _container(repo, store);
    final sub = c.listen(otpViewModelProvider(_args), (_, _) {});
    addTearDown(sub.close);

    c.read(otpViewModelProvider(_args).notifier).setCode('123456');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(repo.verifiedCodes, ['123456']);
    expect(c.read(sessionControllerProvider), isA<SignedIn>());
    expect((await store.read())!.accessToken, 'signed-in');
  });

  test('fewer than 6 digits does not call the server', () async {
    final repo = FakePhoneVerificationRepository();
    final c = _container(repo, InMemoryTokenStore());
    final sub = c.listen(otpViewModelProvider(_args), (_, _) {});
    addTearDown(sub.close);
    c.read(otpViewModelProvider(_args).notifier).setCode('12345');
    await Future<void>.delayed(Duration.zero);
    expect(repo.verifiedCodes, isEmpty);
  });

  test('invalid code shows the error and clears the field', () async {
    final repo = FakePhoneVerificationRepository(
      verifyResult: const SmsCodePayload(valid: false),
    );
    final c = _container(repo, InMemoryTokenStore());
    final sub = c.listen(otpViewModelProvider(_args), (_, _) {});
    addTearDown(sub.close);
    c.read(otpViewModelProvider(_args).notifier).setCode('000000');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final state = c.read(otpViewModelProvider(_args));
    expect(state.invalidCode, isTrue);
    expect(state.code, isEmpty);
    expect(c.read(sessionControllerProvider), isNot(isA<SignedIn>()));
  });

  test('network failure surfaces as a failure, not an invalid code', () async {
    final repo = FakePhoneVerificationRepository(
      failure: const OfflineFailure(),
    );
    final c = _container(repo, InMemoryTokenStore());
    final sub = c.listen(otpViewModelProvider(_args), (_, _) {});
    addTearDown(sub.close);
    c.read(otpViewModelProvider(_args).notifier).setCode('123456');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final state = c.read(otpViewModelProvider(_args));
    expect(state.failure, isA<OfflineFailure>());
    expect(state.invalidCode, isFalse);
  });

  test('resend cool-down counts down 60 s then allows resend once', () {
    fakeAsync((async) {
      final repo = FakePhoneVerificationRepository();
      final c = _container(repo, InMemoryTokenStore());
      final sub = c.listen(otpViewModelProvider(_args), (_, _) {});
      final vm = c.read(otpViewModelProvider(_args).notifier);

      expect(c.read(otpViewModelProvider(_args)).secondsLeft, otpResendSeconds);
      vm.resend(); // ignored: still cooling down
      async.flushMicrotasks();
      expect(repo.sent, isEmpty);

      async.elapse(const Duration(seconds: otpResendSeconds));
      expect(c.read(otpViewModelProvider(_args)).canResend, isTrue);

      vm.resend();
      async.flushMicrotasks();
      expect(repo.sent, hasLength(1));
      expect(c.read(otpViewModelProvider(_args)).secondsLeft, otpResendSeconds);
      sub.close();
    });
  });
}
