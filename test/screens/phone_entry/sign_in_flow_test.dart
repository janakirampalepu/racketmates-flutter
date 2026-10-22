import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/app.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/phone_verification.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/screens/country_picker/country_picker_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/otp/otp_test_ids.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_test_ids.dart';
import 'package:racketmates/screens/sign_up_details/sign_up_details_test_ids.dart';
import 'package:racketmates/screens/splash/repositories/startup_repository.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

import '../../support/fakes.dart';

Widget _app(FakePhoneVerificationRepository repo, InMemoryTokenStore store) =>
    ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(testConfig),
        appVersionProvider.overrideWithValue('1.0.0'),
        tokenStoreProvider.overrideWithValue(store),
        authApiProvider.overrideWithValue(FakeAuthApi()),
        ...contentOverrides(),
        scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository()),
        startupRepositoryProvider.overrideWithValue(FakeStartupRepository()),
        phoneVerificationRepositoryProvider.overrideWithValue(repo),
        deviceTimezoneProvider.overrideWith((ref) async => 'UTC'),
      ],
      child: const RacketmatesApp(),
    );

Finder _id(String id) => find.bySemanticsIdentifier(id);

Future<void> _enterNumber(WidgetTester tester, String digits) async {
  await tester.enterText(find.byType(TextField), digits);
  await tester.pump();
}

void main() {
  testWidgets('welcome > sign in > number > OTP > home', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = FakePhoneVerificationRepository();
    final store = InMemoryTokenStore();
    await tester.pumpWidget(_app(repo, store));
    await tester.pumpAndSettle();

    await tester.tap(_id(WelcomeTestIds.signInButton));
    await tester.pumpAndSettle();
    expect(_id(PhoneEntryTestIds.root), findsOneWidget);

    // Continue is disabled until the number is complete.
    FilledButton continueButton() => tester.widget<FilledButton>(
      find.descendant(
        of: _id(PhoneEntryTestIds.continueButton),
        matching: find.byType(FilledButton),
      ),
    );
    expect(continueButton().onPressed, isNull);
    await _enterNumber(tester, '555123');
    expect(continueButton().onPressed, isNull);
    await _enterNumber(tester, '5551234567');
    expect(continueButton().onPressed, isNotNull);

    await tester.tap(_id(PhoneEntryTestIds.continueButton));
    await tester.pumpAndSettle();

    expect(repo.validated.single.nationalNumber, '5551234567');
    expect(repo.sent, hasLength(1));
    expect(_id(OtpTestIds.root), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    expect(repo.verifiedCodes, ['123456']);
    expect(_id(HomeTestIds.root), findsOneWidget);
    expect((await store.read())!.accessToken, 'signed-in');
    handle.dispose();
  });

  testWidgets('sign in with an unregistered number offers sign up', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakePhoneVerificationRepository(
      status: const MobileNumberStatus(userExist: false, isSignedUp: false),
    );
    await tester.pumpWidget(_app(repo, InMemoryTokenStore()));
    await tester.pumpAndSettle();
    await tester.tap(_id(WelcomeTestIds.signInButton));
    await tester.pumpAndSettle();
    await _enterNumber(tester, '5551234567');
    await tester.tap(_id(PhoneEntryTestIds.continueButton));
    await tester.pumpAndSettle();

    expect(_id(PhoneEntryTestIds.dialogTitle), findsOneWidget);
    expect(repo.sent, isEmpty);

    // Closing keeps the user on the entry screen without sending a code.
    await tester.tap(_id(PhoneEntryTestIds.dialogClose));
    await tester.pumpAndSettle();
    expect(repo.sent, isEmpty);
    expect(_id(PhoneEntryTestIds.root), findsOneWidget);

    // Accepting sends the code in sign-up mode.
    await tester.tap(_id(PhoneEntryTestIds.continueButton));
    await tester.pumpAndSettle();
    await tester.tap(_id(PhoneEntryTestIds.dialogContinue));
    await tester.pumpAndSettle();
    expect(repo.sent, hasLength(1));
    expect(_id(OtpTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('new number after OTP lands on sign-up details', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = FakePhoneVerificationRepository(
      status: const MobileNumberStatus(userExist: false, isSignedUp: false),
      verifyResult: const SmsCodePayload(valid: true, playerExist: false),
    );
    await tester.pumpWidget(_app(repo, InMemoryTokenStore()));
    await tester.pumpAndSettle();
    await tester.tap(_id(WelcomeTestIds.signUpButton));
    await tester.pumpAndSettle();
    await _enterNumber(tester, '5551234567');
    await tester.tap(_id(PhoneEntryTestIds.continueButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(_id(SignUpDetailsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'wrong code shows the error; network failure shows the network message',
    (tester) async {
      final handle = tester.ensureSemantics();
      final repo = FakePhoneVerificationRepository(
        verifyResult: const SmsCodePayload(valid: false),
      );
      await tester.pumpWidget(_app(repo, InMemoryTokenStore()));
      await tester.pumpAndSettle();
      await tester.tap(_id(WelcomeTestIds.signInButton));
      await tester.pumpAndSettle();
      await _enterNumber(tester, '5551234567');
      await tester.tap(_id(PhoneEntryTestIds.continueButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '999999');
      await tester.pumpAndSettle();
      expect(_id(OtpTestIds.errorMessage), findsOneWidget);
      expect(find.text('That code is not valid. Try again.'), findsOneWidget);

      repo.failure = const OfflineFailure();
      await tester.enterText(find.byType(TextField), '111111');
      await tester.pumpAndSettle();
      expect(find.text('Check your connection and try again.'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('country picker selects a country and the dial code follows', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakePhoneVerificationRepository();
    await tester.pumpWidget(_app(repo, InMemoryTokenStore()));
    await tester.pumpAndSettle();
    await tester.tap(_id(WelcomeTestIds.signInButton));
    await tester.pumpAndSettle();

    await tester.tap(_id(PhoneEntryTestIds.countryButton));
    await tester.pumpAndSettle();
    expect(_id(CountryPickerTestIds.root), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'india');
    await tester.pumpAndSettle();
    await tester.tap(_id(CountryPickerTestIds.item('IN')));
    await tester.pumpAndSettle();

    await _enterNumber(tester, '9876543210');
    await tester.tap(_id(PhoneEntryTestIds.continueButton));
    await tester.pumpAndSettle();
    expect(repo.validated.single.countryCode, '91');
    expect(repo.validated.single.regionCode, 'IN');
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'welcome and phone entry meet contrast and tap-target guidelines ($mode)',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue =
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(
          _app(FakePhoneVerificationRepository(), InMemoryTokenStore()),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await tester.tap(_id(WelcomeTestIds.signInButton));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      },
    );
  }
}
