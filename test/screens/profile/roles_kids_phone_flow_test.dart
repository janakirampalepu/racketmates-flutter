import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/models/phone_verification.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';
import 'package:racketmates/screens/settings/settings_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);
Finder _field(String id) =>
    find.descendant(of: _id(id), matching: find.byType(TextField));

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(HomeTestIds.settingsButton));
  await tester.pumpAndSettle();
}

const _kai = AppUser(
  id: 21,
  firstName: 'Kai',
  lastName: 'Lee',
  userRoles: [
    UserRole(
      id: 51,
      role: 'ur_player',
      userRoleSports: [UserRoleSport(id: 61, sportType: 'st_tennis')],
    ),
  ],
);
const _mia = AppUser(
  id: 22,
  firstName: 'Mia',
  lastName: 'Lee',
  userRoles: [
    UserRole(
      id: 52,
      role: 'ur_player',
      userRoleSports: [UserRoleSport(id: 62, sportType: 'st_padel')],
    ),
  ],
);

AppUser _parent({List<AppUser> kids = const [], bool coach = false}) => AppUser(
  id: 7,
  firstName: 'Sam',
  lastName: 'Lee',
  mobileNumber: '5551234567',
  roles: const ['ur_player'],
  country: const UserCountry(code: '1', regionCode: 'US'),
  userRoles: [
    const UserRole(
      id: 3,
      role: 'ur_player',
      userRoleSports: [
        UserRoleSport(id: 9, sportType: 'st_tennis'),
        UserRoleSport(id: 10, sportType: 'st_padel'),
      ],
    ),
    if (coach)
      const UserRole(
        id: 4,
        role: 'ur_coach',
        userRoleSports: [UserRoleSport(id: 11, sportType: 'st_tennis')],
      ),
  ],
  children: kids,
);

FakeUserRepository _users(AppUser user) =>
    FakeUserRepository(profile: UserDetails(user: user));

// Player/Coach/Parent are now inline rows on the Settings screen itself
// (native `profileHeaderCard`), not a separate "Roles and sports" screen.
Future<void> _openRoles(WidgetTester tester) => _openSettings(tester);

void main() {
  group('roles and sports', () {
    testWidgets('shows each role and its sports', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(
        signedInApp(users: _users(_parent(kids: [_kai], coach: true))),
      );
      await _openRoles(tester);
      expect(find.text('Padel, Tennis'), findsOneWidget); // player
      expect(find.text('Tennis'), findsOneWidget); // coach
      expect(find.text('1 kid'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a role the user lacks says so', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp(users: _users(_parent())));
      await _openRoles(tester);
      expect(find.text('Not active. Tap to add.'), findsNWidgets(2));
      handle.dispose();
    });

    testWidgets('changing player sports keeps, adds and destroys', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent());
      await tester.pumpWidget(signedInApp(users: users));
      await _openRoles(tester);
      await _tap(tester, RolesTestIds.player);
      await _tap(tester, RolesTestIds.sport('st_padel')); // off
      await _tap(tester, RolesTestIds.sport('st_pickleball')); // on
      await _tap(tester, RolesTestIds.sportsSave);
      expect(users.userCalls, ['role:7:3']);
      expect(users.roleBodies.single, {
        'user_role': {
          'role': 'ur_player',
          'user_role_sports_attributes': [
            {'id': 10, 'sport_type': 'st_padel', '_destroy': true},
            {'sport_type': 'st_pickleball'},
            {'id': 9, 'sport_type': 'st_tennis'},
          ],
        },
      });
      expect(find.text('Sports updated.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a role needs a sport', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent());
      await tester.pumpWidget(signedInApp(users: users));
      await _openRoles(tester);
      await _tap(tester, RolesTestIds.player);
      await _tap(tester, RolesTestIds.sport('st_padel'));
      await _tap(tester, RolesTestIds.sport('st_tennis'));
      await _tap(tester, RolesTestIds.sportsSave);
      expect(_id(RolesTestIds.sportsError), findsOneWidget);
      expect(users.userCalls, isEmpty);
      await _tap(tester, RolesTestIds.sport('st_tennis'));
      expect(_id(RolesTestIds.sportsError), findsNothing);
      handle.dispose();
    });

    testWidgets('a role the user lacks is added', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent());
      await tester.pumpWidget(signedInApp(users: users));
      await _openRoles(tester);
      await _tap(tester, RolesTestIds.coach);
      await _tap(tester, RolesTestIds.sport('st_tennis'));
      await _tap(tester, RolesTestIds.sportsSave);
      expect(users.userCalls, ['addRole:7']);
      expect(users.roleBodies.single['user_role'], {
        'role': 'ur_coach',
        'user_role_sports_attributes': [
          {'sport_type': 'st_tennis'},
        ],
      });
      expect(find.text('Role added.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a failing save keeps the screen', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent());
      await tester.pumpWidget(signedInApp(users: users));
      await _openRoles(tester);
      await _tap(tester, RolesTestIds.player);
      users.failure = const OfflineFailure();
      await _tap(tester, RolesTestIds.sport('st_pickleball'));
      await _tap(tester, RolesTestIds.sportsSave);
      expect(_id(RolesTestIds.sportsFailed), findsOneWidget);
      expect(_id(RolesTestIds.sportsRoot), findsOneWidget);
      handle.dispose();
    });
  });

  group('kids', () {
    Future<void> openKids(WidgetTester tester) async {
      await _openRoles(tester);
      await _tap(tester, RolesTestIds.parent);
    }

    testWidgets('no kids: the parent role is enabled by adding the first', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent());
      await tester.pumpWidget(signedInApp(users: users));
      await openKids(tester);
      expect(_id(KidsSettingsTestIds.enable), findsOneWidget);
      await _tap(tester, KidsSettingsTestIds.add);
      await tester.enterText(_field(KidEditTestIds.firstName), ' Kai ');
      await tester.enterText(_field(KidEditTestIds.lastName), 'Lee');
      await _tap(tester, KidEditTestIds.sport('st_tennis'));
      await _tap(tester, KidEditTestIds.save);
      expect(users.userCalls, ['kid:create']);
      final fields = {
        for (final e in users.kidForms.single.fields) e.key: e.value,
      };
      expect(fields['user[first_name]'], 'Kai');
      expect(fields['user[parent_user_id]'], '7');
      expect(fields['user[user_roles_attributes][0][role]'], 'ur_player');
      expect(find.text('Kid added.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a kid needs names and a sport', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent());
      await tester.pumpWidget(signedInApp(users: users));
      await openKids(tester);
      await _tap(tester, KidsSettingsTestIds.add);
      await _tap(tester, KidEditTestIds.save);
      expect(_id(KidEditTestIds.firstNameError), findsOneWidget);
      expect(_id(KidEditTestIds.lastNameError), findsOneWidget);
      expect(_id(KidEditTestIds.sportError), findsOneWidget);
      expect(users.userCalls, isEmpty);
      handle.dispose();
    });

    testWidgets('a mobile number of a registered user is refused', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent());
      final phone = FakePhoneVerificationRepository(
        status: const MobileNumberStatus(userExist: true, isSignedUp: true),
      );
      await tester.pumpWidget(signedInApp(users: users, phone: phone));
      await openKids(tester);
      await _tap(tester, KidsSettingsTestIds.add);
      await tester.enterText(_field(KidEditTestIds.firstName), 'Kai');
      await tester.enterText(_field(KidEditTestIds.lastName), 'Lee');
      await tester.enterText(_field(KidEditTestIds.mobile), '5559998888');
      await _tap(tester, KidEditTestIds.sport('st_tennis'));
      await _tap(tester, KidEditTestIds.save);
      expect(find.text('This number is already registered.'), findsOneWidget);
      expect(users.userCalls, isEmpty);
      handle.dispose();
    });

    testWidgets('kids are listed, edited and removed', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent(kids: [_kai, _mia]));
      await tester.pumpWidget(signedInApp(users: users));
      await openKids(tester);
      expect(find.text('Kai Lee'), findsOneWidget);
      expect(find.text('Mia Lee'), findsOneWidget);
      // Two kids: no more can be added.
      expect(_id(KidsSettingsTestIds.add), findsNothing);
      expect(_id(KidsSettingsTestIds.max), findsOneWidget);

      // Edit Kai: padel instead of tennis keeps the ids.
      await _tap(tester, KidsSettingsTestIds.edit(21));
      expect(
        tester
            .widget<TextField>(_field(KidEditTestIds.firstName))
            .controller!
            .text,
        'Kai',
      );
      await _tap(tester, KidEditTestIds.sport('st_padel'));
      await _tap(tester, KidEditTestIds.sport('st_tennis'));
      await _tap(tester, KidEditTestIds.save);
      expect(users.updated, hasLength(1));
      final (kidId, form) = users.updated.single;
      expect(kidId, 21);
      final f = {for (final e in form.fields) e.key: e.value};
      const role = 'user[user_roles_attributes][0]';
      expect(f['$role[id]'], '51');
      expect(f['$role[user_role_sports_attributes][1][_destroy]'], 'true');
      handle.dispose();
    });

    testWidgets('removing a kid asks first', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent(kids: [_kai, _mia]));
      await tester.pumpWidget(signedInApp(users: users));
      await openKids(tester);
      await _tap(tester, KidsSettingsTestIds.remove(22));
      await _tap(tester, KidsSettingsTestIds.confirmNo);
      expect(users.userCalls, isEmpty);
      await _tap(tester, KidsSettingsTestIds.remove(22));
      expect(find.text('The account of Mia Lee is deleted.'), findsOneWidget);
      await _tap(tester, KidsSettingsTestIds.confirmYes);
      expect(users.userCalls, ['delete:22']);
      expect(find.text('Mia Lee'), findsNothing);
      expect(find.text('Kid removed.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('removing the last kid turns the parent role off', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent(kids: [_kai]));
      await tester.pumpWidget(signedInApp(users: users));
      await openKids(tester);
      await _tap(tester, KidsSettingsTestIds.remove(21));
      expect(find.textContaining('parent role is turned off'), findsOneWidget);
      await _tap(tester, KidsSettingsTestIds.confirmYes);
      expect(users.userCalls, ['delete:21']);
      expect(_id(KidsSettingsTestIds.enable), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a failing removal keeps the kid', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent(kids: [_kai, _mia]));
      await tester.pumpWidget(signedInApp(users: users));
      await openKids(tester);
      users.failure = const OfflineFailure();
      await _tap(tester, KidsSettingsTestIds.remove(22));
      await _tap(tester, KidsSettingsTestIds.confirmYes);
      expect(_id(KidsSettingsTestIds.removeFailed), findsOneWidget);
      handle.dispose();
    });
  });

  group('change mobile number', () {
    Future<void> openPhone(WidgetTester tester) async {
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.profile);
      await _tap(tester, ProfileTestIds.changePhone);
    }

    testWidgets('verify the new number, then it is changed', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent());
      final phone = FakePhoneVerificationRepository(
        status: const MobileNumberStatus(userExist: false),
      );
      await tester.pumpWidget(signedInApp(users: users, phone: phone));
      await openPhone(tester);
      await tester.enterText(_field(ChangePhoneTestIds.number), '5559990000');
      await _tap(tester, ChangePhoneTestIds.send);
      expect(phone.validated.single.nationalNumber, '5559990000');
      expect(phone.sent.single.regionCode, 'US');
      expect(_id(ChangePhoneTestIds.code), findsOneWidget);
      await tester.enterText(_field(ChangePhoneTestIds.code), '123456');
      await _tap(tester, ChangePhoneTestIds.verify);
      expect(phone.verifiedCodes, ['123456']);
      expect(users.phoneBodies.single, {
        'mobile_number': '5559990000',
        'country_code': '1',
        'region_code': 'US',
      });
      expect(find.text('Mobile number changed.'), findsOneWidget);
      expect(_id(ChangePhoneTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets('a number of another account is refused', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final phone = FakePhoneVerificationRepository(
        status: const MobileNumberStatus(userExist: true, isSignedUp: true),
      );
      await tester.pumpWidget(
        signedInApp(users: _users(_parent()), phone: phone),
      );
      await openPhone(tester);
      await tester.enterText(_field(ChangePhoneTestIds.number), '5559990000');
      await _tap(tester, ChangePhoneTestIds.send);
      expect(
        find.text('This number belongs to another account.'),
        findsOneWidget,
      );
      expect(phone.sent, isEmpty);
      handle.dispose();
    });

    testWidgets('the current number and an invalid one are refused', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final phone = FakePhoneVerificationRepository();
      await tester.pumpWidget(
        signedInApp(users: _users(_parent()), phone: phone),
      );
      await openPhone(tester);
      await tester.enterText(_field(ChangePhoneTestIds.number), '5551234567');
      await _tap(tester, ChangePhoneTestIds.send);
      expect(find.text('That is already your number.'), findsOneWidget);
      await tester.enterText(_field(ChangePhoneTestIds.number), '12');
      await _tap(tester, ChangePhoneTestIds.send);
      expect(phone.validated, isEmpty);
      handle.dispose();
    });

    testWidgets('a wrong code does not change the number; resend sends again', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent());
      final phone = FakePhoneVerificationRepository(
        status: const MobileNumberStatus(userExist: false),
        verifyResult: const SmsCodePayload(valid: false),
      );
      await tester.pumpWidget(signedInApp(users: users, phone: phone));
      await openPhone(tester);
      await tester.enterText(_field(ChangePhoneTestIds.number), '5559990000');
      await _tap(tester, ChangePhoneTestIds.send);
      await tester.enterText(_field(ChangePhoneTestIds.code), '000000');
      await _tap(tester, ChangePhoneTestIds.verify);
      expect(find.text('That code is not right.'), findsOneWidget);
      expect(users.phoneBodies, isEmpty);
      await _tap(tester, ChangePhoneTestIds.resend);
      expect(phone.sent, hasLength(2));
      handle.dispose();
    });

    testWidgets('a failing change keeps the screen', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(_parent());
      final phone = FakePhoneVerificationRepository(
        status: const MobileNumberStatus(userExist: false),
      );
      await tester.pumpWidget(signedInApp(users: users, phone: phone));
      await openPhone(tester);
      await tester.enterText(_field(ChangePhoneTestIds.number), '5559990000');
      await _tap(tester, ChangePhoneTestIds.send);
      users.failure = const OfflineFailure();
      await tester.enterText(_field(ChangePhoneTestIds.code), '123456');
      await _tap(tester, ChangePhoneTestIds.verify);
      expect(_id(ChangePhoneTestIds.error), findsOneWidget);
      expect(_id(ChangePhoneTestIds.root), findsOneWidget);
      handle.dispose();
    });
  });

  for (final dark in [false, true]) {
    testWidgets('roles and kids meet guidelines (${dark ? 'dark' : 'light'})', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(
        signedInApp(users: _users(_parent(kids: [_kai], coach: true))),
      );
      await _openRoles(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await _tap(tester, RolesTestIds.parent);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
