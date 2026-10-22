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
import 'package:racketmates/common/media/image_picker_service.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/screens/congratulations/congratulations_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/kid_form/kid_form_test_ids.dart';
import 'package:racketmates/screens/kids_list/kids_list_test_ids.dart';
import 'package:racketmates/screens/otp/otp_test_ids.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_test_ids.dart';
import 'package:racketmates/screens/profile_picture/profile_picture_test_ids.dart';
import 'package:racketmates/screens/role_selection/role_selection_test_ids.dart';
import 'package:racketmates/screens/sign_up_details/sign_up_details_test_ids.dart';
import 'package:racketmates/screens/splash/repositories/startup_repository.dart';
import 'package:racketmates/screens/sports_selection/sports_selection_test_ids.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);
Finder _field(String id) =>
    find.descendant(of: _id(id), matching: find.byType(TextField));

class _Harness {
  _Harness({FakeUserRepository? users, FakePhotoPicker? picker})
    : users = users ?? FakeUserRepository(),
      picker = picker ?? FakePhotoPicker(),
      phone = FakePhoneVerificationRepository(
        status: const MobileNumberStatus(userExist: false, isSignedUp: false),
        verifyResult: const SmsCodePayload(
          valid: true,
          playerExist: false,
          verificationCode: 'vc',
        ),
      ),
      store = InMemoryTokenStore();

  final FakeUserRepository users;
  final FakePhotoPicker picker;
  final FakePhoneVerificationRepository phone;
  final InMemoryTokenStore store;
  late final ProviderContainer container;

  Widget app() => ProviderScope(
    overrides: [
      environmentConfigProvider.overrideWithValue(testConfig),
      appVersionProvider.overrideWithValue('1.0.0'),
      tokenStoreProvider.overrideWithValue(store),
      authApiProvider.overrideWithValue(FakeAuthApi()),
      scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository()),
      startupRepositoryProvider.overrideWithValue(FakeStartupRepository()),
      phoneVerificationRepositoryProvider.overrideWithValue(phone),
      preLoginUserRepositoryProvider.overrideWithValue(users),
      userRepositoryProvider.overrideWithValue(users),
      photoPickerProvider.overrideWithValue(picker),
      deviceTimezoneProvider.overrideWith((ref) async => 'America/New_York'),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return const RacketmatesApp();
      },
    ),
  );
}

Future<void> _toDetails(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(WelcomeTestIds.signUpButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '5551234567');
  await tester.pump();
  await tester.tap(_id(PhoneEntryTestIds.continueButton));
  await tester.pumpAndSettle();
  expect(_id(OtpTestIds.root), findsOneWidget);
  await tester.enterText(find.byType(TextField), '123456');
  await tester.pumpAndSettle();
  expect(_id(SignUpDetailsTestIds.root), findsOneWidget);
}

Future<void> _fillDetails(
  WidgetTester tester, {
  String email = 'sam@example.com',
}) async {
  await tester.enterText(_field(SignUpDetailsTestIds.firstName), 'Sam');
  await tester.enterText(_field(SignUpDetailsTestIds.lastName), 'Lee');
  await tester.enterText(_field(SignUpDetailsTestIds.email), email);
  await tester.pump();
  await tester.tap(_id(SignUpDetailsTestIds.next));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'new parent + player: details > roles > sports > kid > kids list > create > photo > congratulations > home',
    (tester) async {
      final handle = tester.ensureSemantics();
      final h = _Harness();
      await tester.pumpWidget(h.app());
      await _toDetails(tester);

      // Details validation
      await tester.tap(_id(SignUpDetailsTestIds.next));
      await tester.pumpAndSettle();
      expect(_id(SignUpDetailsTestIds.root), findsOneWidget);
      expect(find.text('Enter your first name.'), findsOneWidget);
      await _fillDetails(tester);
      expect(h.users.duplicateChecks.single.email, 'sam@example.com');

      // Roles: none selected is an error; player + parent continue.
      expect(_id(RoleSelectionTestIds.root), findsOneWidget);
      await tester.tap(_id(RoleSelectionTestIds.next));
      await tester.pumpAndSettle();
      expect(_id(RoleSelectionTestIds.error), findsOneWidget);
      await tester.tap(_id(RoleSelectionTestIds.role('ur_player')));
      await tester.tap(_id(RoleSelectionTestIds.role('ur_parent')));
      await tester.pumpAndSettle();
      await tester.tap(_id(RoleSelectionTestIds.next));
      await tester.pumpAndSettle();

      // Player sports: at least one.
      expect(_id(SportsSelectionTestIds.root), findsOneWidget);
      await tester.tap(_id(SportsSelectionTestIds.next));
      await tester.pumpAndSettle();
      expect(_id(SportsSelectionTestIds.error), findsOneWidget);
      await tester.tap(_id(SportsSelectionTestIds.sport('st_tennis')));
      await tester.pumpAndSettle();
      await tester.tap(_id(SportsSelectionTestIds.next));
      await tester.pumpAndSettle();

      // Parent: first kid form (no kids yet), requires a sport.
      expect(_id(KidFormTestIds.root), findsOneWidget);
      await tester.enterText(_field(KidFormTestIds.firstName), 'Kid');
      await tester.enterText(_field(KidFormTestIds.lastName), 'Lee');
      await tester.tap(_id(KidFormTestIds.save));
      await tester.pumpAndSettle();
      expect(_id(KidFormTestIds.sportError), findsOneWidget);
      await tester.tap(_id(KidFormTestIds.sport('st_padel')));
      await tester.pumpAndSettle();
      await tester.tap(_id(KidFormTestIds.save));
      await tester.pumpAndSettle();

      // Kids list -> Next creates the account.
      expect(_id(KidsListTestIds.root), findsOneWidget);
      expect(_id(KidsListTestIds.kid(0)), findsOneWidget);
      await tester.tap(_id(KidsListTestIds.next));
      await tester.pumpAndSettle();

      expect(h.users.created, hasLength(1));
      expect(h.phone.signInCodes, ['vc']);
      expect((await h.store.read())!.accessToken, 'signed-in');
      expect(_id(ProfilePictureTestIds.root), findsOneWidget);

      // Skip the photo; congratulations greets by name from the profile fetch.
      await tester.tap(_id(ProfilePictureTestIds.doLaterButton));
      await tester.pumpAndSettle();
      expect(_id(CongratulationsTestIds.root), findsOneWidget);

      await tester.tap(_id(CongratulationsTestIds.goHome));
      await tester.pumpAndSettle();
      expect(_id(HomeTestIds.root), findsOneWidget);
      expect(h.container.read(signUpFlowProvider), isNull);
      handle.dispose();
    },
  );

  testWidgets('player only: sports Next creates the account straight away', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _toDetails(tester);
    await _fillDetails(tester, email: '');
    expect(h.users.duplicateChecks, isEmpty);

    await tester.tap(_id(RoleSelectionTestIds.role('ur_player')));
    await tester.pumpAndSettle();
    await tester.tap(_id(RoleSelectionTestIds.next));
    await tester.pumpAndSettle();
    await tester.tap(_id(SportsSelectionTestIds.sport('st_badminton')));
    await tester.pumpAndSettle();
    await tester.tap(_id(SportsSelectionTestIds.next));
    await tester.pumpAndSettle();

    expect(h.users.created, hasLength(1));
    expect(_id(ProfilePictureTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a taken email stays on details with an error', (tester) async {
    final handle = tester.ensureSemantics();
    final h = _Harness(users: FakeUserRepository(emailTaken: true));
    await tester.pumpWidget(h.app());
    await _toDetails(tester);
    await _fillDetails(tester);
    expect(_id(SignUpDetailsTestIds.root), findsOneWidget);
    expect(find.text('This email is already in use.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('profile picture: pick, upload, then congratulations', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = _Harness(picker: FakePhotoPicker('/tmp/photo.jpg'));
    await tester.pumpWidget(h.app());
    await _toDetails(tester);
    await _fillDetails(tester, email: '');
    await tester.tap(_id(RoleSelectionTestIds.role('ur_player')));
    await tester.pumpAndSettle();
    await tester.tap(_id(RoleSelectionTestIds.next));
    await tester.pumpAndSettle();
    await tester.tap(_id(SportsSelectionTestIds.sport('st_tennis')));
    await tester.pumpAndSettle();
    await tester.tap(_id(SportsSelectionTestIds.next));
    await tester.pumpAndSettle();

    await tester.tap(_id(ProfilePictureTestIds.chooseGallery));
    await tester.pumpAndSettle();
    expect(h.picker.requests, [PhotoSource.gallery]);
    expect(_id(ProfilePictureTestIds.uploadedImage), findsOneWidget);
    await tester.tap(_id(ProfilePictureTestIds.upload));
    await tester.pumpAndSettle();
    expect(h.users.avatars.single, (7, '/tmp/photo.jpg'));
    expect(_id(CongratulationsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('account creation failure shows an error and allows retry', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await _toDetails(tester);
    await _fillDetails(tester, email: '');
    await tester.tap(_id(RoleSelectionTestIds.role('ur_player')));
    await tester.pumpAndSettle();
    await tester.tap(_id(RoleSelectionTestIds.next));
    await tester.pumpAndSettle();
    await tester.tap(_id(SportsSelectionTestIds.sport('st_tennis')));
    await tester.pumpAndSettle();

    h.users.failure = const OfflineFailure();
    await tester.tap(_id(SportsSelectionTestIds.next));
    await tester.pumpAndSettle();
    expect(_id(SportsSelectionTestIds.error), findsOneWidget);
    expect(_id(SportsSelectionTestIds.root), findsOneWidget);

    h.users.failure = null;
    await tester.tap(_id(SportsSelectionTestIds.next));
    await tester.pumpAndSettle();
    expect(_id(ProfilePictureTestIds.root), findsOneWidget);
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'sign-up screens meet contrast and tap-target guidelines ($mode)',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue =
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final h = _Harness();
        await tester.pumpWidget(h.app());
        await _toDetails(tester);

        Future<void> check() async {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        }

        await check(); // details
        await _fillDetails(tester, email: '');
        await check(); // roles
        await tester.tap(_id(RoleSelectionTestIds.role('ur_player')));
        await tester.tap(_id(RoleSelectionTestIds.role('ur_parent')));
        await tester.pumpAndSettle();
        await tester.tap(_id(RoleSelectionTestIds.next));
        await tester.pumpAndSettle();
        await check(); // player sports
        await tester.tap(_id(SportsSelectionTestIds.sport('st_tennis')));
        await tester.pumpAndSettle();
        await tester.tap(_id(SportsSelectionTestIds.next));
        await tester.pumpAndSettle();
        await check(); // kid form
        handle.dispose();
      },
    );
  }
}
