import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/screens/sign_up_details/sign_up_details_state.dart';
import 'package:racketmates/screens/sign_up_details/sign_up_details_view_model.dart';
import 'package:racketmates/screens/sign_up_details/usecases/validate_sign_up_details.dart';

import '../../support/fakes.dart';

const _phone = PhoneNumberParts(
  nationalNumber: '5551234567',
  countryCode: '1',
  regionCode: 'US',
);

ProviderContainer _container(
  FakeUserRepository pre,
  FakeUserRepository authed, {
  bool resume = false,
}) {
  final c = ProviderContainer(
    overrides: [
      preLoginUserRepositoryProvider.overrideWithValue(pre),
      userRepositoryProvider.overrideWithValue(authed),
    ],
  );
  addTearDown(c.dispose);
  c
      .read(signUpFlowProvider.notifier)
      .start(
        phone: _phone,
        verificationCode: 'vc',
        resume: resume,
        userId: resume ? 7 : null,
      );
  return c;
}

void main() {
  group('validateSignUpDetails', () {
    test('names are required, email optional', () {
      final v = validateSignUpDetails(firstName: ' ', lastName: '', email: '');
      expect(v.firstNameMissing, isTrue);
      expect(v.lastNameMissing, isTrue);
      expect(v.emailError, isNull);
      expect(
        validateSignUpDetails(firstName: 'a', lastName: 'b', email: '').isValid,
        isTrue,
      );
    });

    test('email must look valid when present', () {
      for (final bad in ['x', 'x@', 'x@y', '@y.com', 'a b@c.com']) {
        expect(
          validateSignUpDetails(
            firstName: 'a',
            lastName: 'b',
            email: bad,
          ).emailError,
          EmailError.invalid,
          reason: bad,
        );
      }
      expect(isValidEmail('sam.lee+tag@example.co.uk'), isTrue);
    });
  });

  test('without an email no duplicate check runs', () async {
    final pre = FakeUserRepository();
    final c = _container(pre, FakeUserRepository());
    final ok = await c
        .read(signUpDetailsViewModelProvider.notifier)
        .submit(firstName: 'Sam', lastName: 'Lee', email: '');
    expect(ok, isTrue);
    expect(pre.duplicateChecks, isEmpty);
    expect(c.read(signUpFlowProvider)!.firstName, 'Sam');
  });

  test('email is checked with the display name and lower-cased', () async {
    final pre = FakeUserRepository();
    final c = _container(pre, FakeUserRepository());
    await c
        .read(signUpDetailsViewModelProvider.notifier)
        .submit(firstName: 'Sam', lastName: 'Lee Jr', email: 'Sam@Example.com');
    expect(pre.duplicateChecks.single, (
      email: 'sam@example.com',
      displayName: 'SLeeJr',
      userId: null,
    ));
  });

  test('a taken email blocks continuing', () async {
    final c = _container(
      FakeUserRepository(emailTaken: true),
      FakeUserRepository(),
    );
    final ok = await c
        .read(signUpDetailsViewModelProvider.notifier)
        .submit(firstName: 'Sam', lastName: 'Lee', email: 'sam@example.com');
    expect(ok, isFalse);
    expect(c.read(signUpDetailsViewModelProvider).emailError, EmailError.taken);
  });

  test(
    'resume uses the authenticated repository and passes the user id',
    () async {
      final pre = FakeUserRepository();
      final authed = FakeUserRepository();
      final c = _container(pre, authed, resume: true);
      await c
          .read(signUpDetailsViewModelProvider.notifier)
          .submit(firstName: 'Sam', lastName: 'Lee', email: 'sam@example.com');
      expect(pre.duplicateChecks, isEmpty);
      expect(authed.duplicateChecks.single.userId, 7);
    },
  );

  test('resume pre-fills names, roles and sports from the profile', () async {
    final authed = FakeUserRepository(
      profile: const UserDetails(
        user: AppUser(
          id: 7,
          firstName: 'Sam',
          lastName: 'Lee',
          email: 's@x.com',
          userRoles: [
            UserRole(
              id: 11,
              role: RoleKeys.player,
              userRoleSports: [UserRoleSport(id: 21, sportType: 'st_tennis')],
            ),
          ],
        ),
      ),
    );
    final c = _container(FakeUserRepository(), authed, resume: true);
    await c.read(signUpDetailsViewModelProvider.notifier).loadResumeProfile();
    final draft = c.read(signUpFlowProvider)!;
    expect(draft.firstName, 'Sam');
    expect(draft.roles, {RoleKeys.player});
    expect(draft.roleIds[RoleKeys.player], 11);
    expect(draft.sportIds[RoleKeys.player]!.values, [21]);
  });
}
