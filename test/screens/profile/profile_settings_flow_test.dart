import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/links/external_links.dart';
import 'package:racketmates/common/media/image_picker_service.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/common/share/share_service.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';
import 'package:racketmates/screens/settings/settings_test_ids.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

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

const _sam = AppUser(
  id: 7,
  firstName: 'Sam',
  lastName: 'Lee',
  email: 'sam@example.com',
  mobileNumber: '5551234567',
  roles: ['ur_player'],
  userRoles: [UserRole(id: 3, role: 'ur_player')],
);

FakeUserRepository _users({AppUser user = _sam}) =>
    FakeUserRepository(profile: UserDetails(user: user));

void main() {
  group('profile', () {
    testWidgets('shows the user and saves a changed name', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users();
      await tester.pumpWidget(signedInApp(users: users));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.profile);
      expect(_id(ProfileTestIds.root), findsOneWidget);
      expect(
        tester
            .widget<TextField>(_field(ProfileTestIds.firstName))
            .controller!
            .text,
        'Sam',
      );
      expect(find.textContaining('5551234567'), findsOneWidget);
      await tester.enterText(_field(ProfileTestIds.firstName), 'Samuel');
      await tester.enterText(_field(ProfileTestIds.email), ' Sam@Example.com ');
      await _tap(tester, ProfileTestIds.save);
      final (id, body) = users.profileUpdates.single;
      expect(id, 7);
      expect((body['user'] as Map)['first_name'], 'Samuel');
      expect((body['user'] as Map)['email'], 'sam@example.com');
      // Same email as before: no duplicate check.
      expect(users.duplicateChecks, isEmpty);
      expect(_id(ProfileTestIds.root), findsNothing);
      expect(find.text('Profile updated.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('required names and a valid email', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users();
      await tester.pumpWidget(signedInApp(users: users));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.profile);
      await tester.enterText(_field(ProfileTestIds.firstName), '');
      await tester.enterText(_field(ProfileTestIds.lastName), ' ');
      await tester.enterText(_field(ProfileTestIds.email), 'nope');
      await _tap(tester, ProfileTestIds.save);
      expect(_id(ProfileTestIds.firstNameError), findsOneWidget);
      expect(_id(ProfileTestIds.lastNameError), findsOneWidget);
      expect(_id(ProfileTestIds.emailError), findsOneWidget);
      expect(users.profileUpdates, isEmpty);
      await tester.enterText(_field(ProfileTestIds.firstName), 'Sam');
      await tester.pump();
      expect(_id(ProfileTestIds.firstNameError), findsNothing);
      handle.dispose();
    });

    testWidgets('a changed email that is taken is refused', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users()..emailTaken = true;
      await tester.pumpWidget(signedInApp(users: users));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.profile);
      await tester.enterText(_field(ProfileTestIds.email), 'other@example.com');
      await _tap(tester, ProfileTestIds.save);
      expect(users.duplicateChecks.single.email, 'other@example.com');
      expect(users.duplicateChecks.single.userId, 7);
      expect(find.text('This email is already in use.'), findsOneWidget);
      expect(users.profileUpdates, isEmpty);
      handle.dispose();
    });

    testWidgets('clearing the email is allowed', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users();
      await tester.pumpWidget(signedInApp(users: users));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.profile);
      await tester.enterText(_field(ProfileTestIds.email), '');
      await _tap(tester, ProfileTestIds.save);
      expect(((users.profileUpdates.single.$2['user']) as Map)['email'], '');
      handle.dispose();
    });

    testWidgets('a failing save keeps the form', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users();
      await tester.pumpWidget(signedInApp(users: users));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.profile);
      users.failure = const OfflineFailure();
      await tester.enterText(_field(ProfileTestIds.firstName), 'Samuel');
      await _tap(tester, ProfileTestIds.save);
      expect(_id(ProfileTestIds.saveFailed), findsOneWidget);
      expect(_id(ProfileTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a photo is chosen and uploaded', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users();
      final picker = FakePhotoPicker('/tmp/me.jpg');
      await tester.pumpWidget(signedInApp(users: users, photoPicker: picker));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.profile);
      expect(_id(ProfileTestIds.removePhoto), findsNothing);
      await _tap(tester, ProfileTestIds.changePhoto);
      await _tap(tester, ProfileTestIds.choosePhoto);
      expect(picker.requests, [PhotoSource.gallery]);
      expect(users.avatars, [(7, '/tmp/me.jpg')]);
      expect(find.text('Photo updated.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
      'a cancelled picker changes nothing; a failing upload says so',
      (tester) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        final users = _users();
        final picker = FakePhotoPicker();
        await tester.pumpWidget(signedInApp(users: users, photoPicker: picker));
        await _openSettings(tester);
        await _tap(tester, SettingsTestIds.profile);
        await _tap(tester, ProfileTestIds.changePhoto);
        await _tap(tester, ProfileTestIds.takePhoto);
        expect(picker.requests, [PhotoSource.camera]);
        expect(users.avatars, isEmpty);
        picker.path = '/tmp/me.jpg';
        users.failure = const OfflineFailure();
        await _tap(tester, ProfileTestIds.changePhoto);
        await _tap(tester, ProfileTestIds.takePhoto);
        expect(_id(ProfileTestIds.photoFailed), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('a photo can be removed', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users(
        user: const AppUser(
          id: 7,
          firstName: 'Sam',
          lastName: 'Lee',
          avatarFileAttachmentUrl: 'https://example.test/me.png',
        ),
      );
      await tester.pumpWidget(signedInApp(users: users));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.profile);
      await _tap(tester, ProfileTestIds.removePhoto);
      expect(users.removedAvatars, [7]);
      expect(find.text('Photo removed.'), findsOneWidget);
      expect(_id(ProfileTestIds.removePhoto), findsNothing);
      handle.dispose();
    });

    testWidgets('a profile that cannot load can be retried', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final users = _users()..failure = const OfflineFailure();
      await tester.pumpWidget(signedInApp(users: users));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.profile);
      expect(_id(ProfileTestIds.loadError), findsOneWidget);
      users.failure = null;
      await _tap(tester, ProfileTestIds.retry);
      expect(_id(ProfileTestIds.firstName), findsOneWidget);
      handle.dispose();
    });

    for (final dark in [false, true]) {
      testWidgets('meets guidelines (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(signedInApp(users: _users()));
        await _openSettings(tester);
        await _tap(tester, SettingsTestIds.profile);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('share with friends', () {
    testWidgets('shares the link with the message', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final share = FakeShareService();
      await tester.pumpWidget(signedInApp(share: share));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.share);
      await _tap(tester, ShareTestIds.share);
      expect(share.shared, ['Join me on Racketmates: $appDownloadUrl']);
      handle.dispose();
    });

    testWidgets('copies the link', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(signedInApp());
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.share);
      await _tap(tester, ShareTestIds.copy);
      expect(copied, appDownloadUrl);
      expect(find.text('Link copied.'), findsOneWidget);
      handle.dispose();
    });
  });

  group('contact us', () {
    testWidgets('sends the message with the account email filled in', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final support = FakeSupportRepository();
      await tester.pumpWidget(signedInApp(support: support, users: _users()));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.contact);
      expect(
        tester.widget<TextField>(_field(ContactTestIds.email)).controller!.text,
        'sam@example.com',
      );
      await tester.enterText(_field(ContactTestIds.subject), 'Help');
      await tester.enterText(_field(ContactTestIds.question), 'It broke');
      await _tap(tester, ContactTestIds.submit);
      expect(support.sent.single.subject, 'Help');
      expect(support.sent.single.feedback, 'It broke');
      expect(support.sent.single.email, 'sam@example.com');
      expect(support.sent.single.mobileNumber, '5551234567');
      expect(find.text('Thank you. We will get back to you.'), findsOneWidget);
      expect(_id(ContactTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets('all fields are required and the email valid', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final support = FakeSupportRepository();
      await tester.pumpWidget(
        signedInApp(
          support: support,
          users: _users(user: const AppUser(id: 7)),
        ),
      );
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.contact);
      await _tap(tester, ContactTestIds.submit);
      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(_id(ContactTestIds.subjectError), findsOneWidget);
      expect(_id(ContactTestIds.questionError), findsOneWidget);
      await tester.enterText(_field(ContactTestIds.email), 'nope');
      await _tap(tester, ContactTestIds.submit);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(support.sent, isEmpty);
      handle.dispose();
    });

    testWidgets('a failing send keeps the message', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final support = FakeSupportRepository()..failure = const OfflineFailure();
      await tester.pumpWidget(signedInApp(support: support, users: _users()));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.contact);
      await tester.enterText(_field(ContactTestIds.subject), 'Help');
      await tester.enterText(_field(ContactTestIds.question), 'It broke');
      await _tap(tester, ContactTestIds.submit);
      expect(_id(ContactTestIds.failed), findsOneWidget);
      expect(_id(ContactTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('with a support chat room the contact form is not offered', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: FakeSessionInfoRepository(
            response: const SessionInfoResponse(
              user: SessionInfoUser(
                id: 7,
                hasFullFeatureAccess: true,
                timezoneIdentifier: 'America/New_York',
                supportChatRoomUrl: 'support-room',
              ),
            ),
          ),
        ),
      );
      await _openSettings(tester);
      expect(_id(SettingsTestIds.support), findsOneWidget);
      expect(_id(SettingsTestIds.contact), findsNothing);
      handle.dispose();
    });
  });

  group('delete account', () {
    testWidgets('asks first, sends the request, then signs out', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final support = FakeSupportRepository();
      await tester.pumpWidget(signedInApp(support: support, users: _users()));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.deleteAccount);
      await _tap(tester, DeleteAccountTestIds.delete);
      await _tap(tester, DeleteAccountTestIds.cancel);
      expect(support.sent, isEmpty);
      await _tap(tester, DeleteAccountTestIds.delete);
      await _tap(tester, DeleteAccountTestIds.confirmDelete);
      expect(support.sent.single.subject, 'Delete My Account');
      expect(
        support.sent.single.feedback,
        'Please delete my account at the earliest',
      );
      expect(support.sent.single.email, 'sam@example.com');
      expect(_id(DeleteAccountTestIds.processing), findsOneWidget);
      await _tap(tester, DeleteAccountTestIds.processingOk);
      expect(_id(WelcomeTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('without an email the native placeholder is used', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final support = FakeSupportRepository();
      await tester.pumpWidget(
        signedInApp(
          support: support,
          users: _users(user: const AppUser(id: 7)),
        ),
      );
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.deleteAccount);
      await _tap(tester, DeleteAccountTestIds.delete);
      await _tap(tester, DeleteAccountTestIds.confirmDelete);
      expect(support.sent.single.email, 'noemail@gmail.com');
      handle.dispose();
    });

    testWidgets('a failing request keeps the user signed in', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final support = FakeSupportRepository()..failure = const OfflineFailure();
      await tester.pumpWidget(signedInApp(support: support, users: _users()));
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.deleteAccount);
      await _tap(tester, DeleteAccountTestIds.delete);
      await _tap(tester, DeleteAccountTestIds.confirmDelete);
      expect(_id(DeleteAccountTestIds.failed), findsOneWidget);
      expect(_id(DeleteAccountTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a subscriber is pointed to the store', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final links = FakeExternalLinks();
      await tester.pumpWidget(
        signedInApp(
          links: links,
          sessionInfo: FakeSessionInfoRepository(
            response: const SessionInfoResponse(
              user: SessionInfoUser(
                id: 7,
                hasFullFeatureAccess: true,
                subscribedDeviceType: 'dt_android',
                timezoneIdentifier: 'America/New_York',
              ),
            ),
          ),
        ),
      );
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.deleteAccount);
      expect(_id(DeleteAccountTestIds.subscriptionNote), findsOneWidget);
      await tester.tap(_id(DeleteAccountTestIds.manageSubscription));
      expect(links.opened, [SubscriptionLinks.manageAndroid]);
      handle.dispose();
    });

    testWidgets('no subscription note without a subscription', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await _openSettings(tester);
      await _tap(tester, SettingsTestIds.deleteAccount);
      expect(_id(DeleteAccountTestIds.subscriptionNote), findsNothing);
      handle.dispose();
    });
  });
}
