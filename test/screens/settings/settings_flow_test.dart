import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/common/settings/settings_models.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/event_reminders/event_reminders_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/notification_settings/notification_settings_test_ids.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';
import 'package:racketmates/screens/settings/settings_test_ids.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/teams/teams_test_ids.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

Future<void> _openSettings(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(HomeTestIds.settingsButton));
  await tester.pumpAndSettle();
}

Future<void> _tapTile(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

void main() {
  group('settings hub', () {
    testWidgets('shows the user and opens the sub screens', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await _openSettings(tester);
      expect(_id(SettingsTestIds.root), findsOneWidget);
      expect(find.text('Sam Lee'), findsOneWidget);

      await _tapTile(tester, SettingsTestIds.notifications);
      expect(_id(NotificationSettingsTestIds.root), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await _tapTile(tester, SettingsTestIds.reminders);
      expect(_id(EventRemindersTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('shows the formatted number and opens change-phone', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(
        signedInApp(
          users: FakeUserRepository(
            profile: UserDetails(
              user: AppUser(
                id: 7,
                firstName: 'Sam',
                lastName: 'Lee',
                mobileNumber: '5551234567',
                country: const UserCountry(code: '1', regionCode: 'US'),
              ),
            ),
          ),
        ),
      );
      await _openSettings(tester);
      expect(find.text('+1 5551234567'), findsOneWidget);
      await _tapTile(tester, SettingsTestIds.myNumber);
      expect(_id(ChangePhoneTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the edit button opens the profile editor', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await _openSettings(tester);
      await _tapTile(tester, SettingsTestIds.profile);
      expect(_id(ProfileTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the help button opens support chat when there is a room', (
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
                timezoneIdentifier: 'America/New_York',
                supportChatRoomUrl: 'support-room',
              ),
            ),
          ),
        ),
      );
      await _openSettings(tester);
      await _tapTile(tester, SettingsTestIds.help);
      expect(find.text('fake channel support-room'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('logging out revokes the token and returns to welcome', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final settings = FakeSettingsRepository();
      final store = InMemoryPushTokenStore()..value = (token: 'tk', userId: 7);
      await tester.pumpWidget(
        signedInApp(settings: settings, pushTokens: store),
      );
      await _openSettings(tester);
      await _tapTile(tester, SettingsTestIds.logout);
      expect(_id(SettingsTestIds.logoutConfirm), findsOneWidget);
      await _tapTile(tester, SettingsTestIds.logoutConfirm);
      expect(_id(WelcomeTestIds.root), findsOneWidget);
      expect(settings.revoked, ['tk']);
      expect(store.value, isNull);
      handle.dispose();
    });

    testWidgets('cancelling keeps the user signed in', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final settings = FakeSettingsRepository();
      await tester.pumpWidget(signedInApp(settings: settings));
      await _openSettings(tester);
      await _tapTile(tester, SettingsTestIds.logout);
      await _tapTile(tester, SettingsTestIds.logoutCancel);
      expect(_id(SettingsTestIds.root), findsOneWidget);
      expect(settings.revoked, isEmpty);
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
        await tester.pumpWidget(signedInApp());
        await _openSettings(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('notification settings', () {
    Future<void> open(WidgetTester tester) async {
      await _openSettings(tester);
      await _tapTile(tester, SettingsTestIds.notifications);
    }

    testWidgets('push unavailable shows a hint', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await open(tester);
      expect(_id(NotificationSettingsTestIds.pushHint), findsOneWidget);
      expect(_id(NotificationSettingsTestIds.pushStatus), findsNothing);
      handle.dispose();
    });

    testWidgets('granted shows On', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(
        signedInApp(push: FakePushPlatform(available: true)),
      );
      await open(tester);
      expect(find.text('On'), findsOneWidget);
      expect(_id(NotificationSettingsTestIds.allow), findsNothing);
      handle.dispose();
    });

    testWidgets('undecided: allow asks and registers', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final push = FakePushPlatform(
        available: true,
        permissionState: PushPermission.notDetermined,
      )..answerToRequest = PushPermission.notDetermined; // prompt dismissed
      final settings = FakeSettingsRepository();
      await tester.pumpWidget(signedInApp(push: push, settings: settings));
      await open(tester);
      push.answerToRequest = PushPermission.granted;
      await _tapTile(tester, NotificationSettingsTestIds.allow);
      expect(push.permissionRequests, 2); // at sign-in, then here
      expect(find.text('On'), findsOneWidget);
      expect(settings.registrations, isNotEmpty);
      handle.dispose();
    });

    testWidgets('denied points to the system settings', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final push = FakePushPlatform(
        available: true,
        permissionState: PushPermission.denied,
      );
      await tester.pumpWidget(signedInApp(push: push));
      await open(tester);
      expect(_id(NotificationSettingsTestIds.allow), findsNothing);
      await _tapTile(tester, NotificationSettingsTestIds.openSettings);
      expect(push.settingsOpened, 1);
      handle.dispose();
    });

    testWidgets('text consent is saved', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final settings = FakeSettingsRepository();
      await tester.pumpWidget(signedInApp(settings: settings));
      await open(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(settings.textConsents, [true]);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      handle.dispose();
    });

    testWidgets('a rejected consent change reverts and says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final settings = FakeSettingsRepository()
        ..failure = const OfflineFailure();
      await tester.pumpWidget(signedInApp(settings: settings));
      await open(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(_id(NotificationSettingsTestIds.error), findsOneWidget);
      handle.dispose();
    });
  });

  group('event reminders', () {
    Future<void> open(WidgetTester tester) async {
      await _openSettings(tester);
      await _tapTile(tester, SettingsTestIds.reminders);
    }

    testWidgets('empty state', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await open(tester);
      expect(_id(EventRemindersTestIds.empty), findsOneWidget);
      handle.dispose();
    });

    testWidgets('lists and removes a reminder', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final settings = FakeSettingsRepository(
        reminders: const [
          ReminderPreference(
            id: 5,
            reminderUnit: 30,
            reminderUnitType: ReminderUnits.minute,
          ),
        ],
      );
      await tester.pumpWidget(signedInApp(settings: settings));
      await open(tester);
      expect(find.text('30 minutes before'), findsOneWidget);
      await _tapTile(tester, EventRemindersTestIds.remove(5));
      expect(settings.calls, contains('remove:7:5'));
      expect(_id(EventRemindersTestIds.empty), findsOneWidget);
      handle.dispose();
    });

    testWidgets('adds a reminder with the chosen unit and value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final settings = FakeSettingsRepository();
      await tester.pumpWidget(signedInApp(settings: settings));
      await open(tester);
      await _tapTile(tester, EventRemindersTestIds.add);
      expect(_id(EventRemindersTestIds.sheet), findsOneWidget);
      await _tapTile(tester, EventRemindersTestIds.unit(ReminderUnits.hour));
      expect(find.text('1 hour before'), findsWidgets);
      await _tapTile(tester, EventRemindersTestIds.save);
      expect(settings.calls, contains('add:7:1:rut_hour'));
      expect(find.text('1 hour before'), findsOneWidget);
      expect(_id(EventRemindersTestIds.sheet), findsNothing);
      handle.dispose();
    });

    testWidgets('a load error can be retried', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final settings = FakeSettingsRepository()..loadFails = true;
      await tester.pumpWidget(signedInApp(settings: settings));
      await open(tester);
      expect(_id(EventRemindersTestIds.error), findsOneWidget);
      settings.loadFails = false;
      await _tapTile(tester, EventRemindersTestIds.retry);
      expect(_id(EventRemindersTestIds.empty), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a rejected change shows a message', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final settings = FakeSettingsRepository(
        reminders: const [
          ReminderPreference(
            id: 5,
            reminderUnit: 10,
            reminderUnitType: ReminderUnits.minute,
          ),
        ],
      );
      await tester.pumpWidget(signedInApp(settings: settings));
      await open(tester);
      settings.failure = const OfflineFailure();
      await _tapTile(tester, EventRemindersTestIds.remove(5));
      expect(_id(EventRemindersTestIds.failed), findsOneWidget);
      expect(find.text('10 minutes before'), findsOneWidget);
      handle.dispose();
    });
  });

  group('push notifications in the app', () {
    testWidgets('a tapped notification opens the event', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final push = FakePushPlatform();
      await tester.pumpWidget(
        signedInApp(
          push: push,
          schedule: FakeScheduleRepository(
            event: const EventDetails(id: 101, eventType: 'et_practice'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      push.openedController.add(
        const PushMessage(
          id: 'm1',
          data: {
            'navigation_page': 'nnp_event_details_page',
            'event_id': '101',
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(_id(EventDetailsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the same message opens only once', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final push = FakePushPlatform();
      await tester.pumpWidget(signedInApp(push: push));
      await tester.pumpAndSettle();
      const message = PushMessage(
        id: 'dup',
        data: {'navigation_page': 'nnp_team_list_page'},
      );
      push.openedController.add(message);
      await tester.pumpAndSettle();
      expect(_id(TeamsTestIds.root), findsOneWidget);
      await tester.tap(find.byType(NavigationBar).first);
      push.openedController.add(message);
      await tester.pumpAndSettle();
      expect(_id(TeamDetailsTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets('a launch notification opens after the app starts', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final push = FakePushPlatform(
        launch: const PushMessage(
          id: 'l1',
          data: {'navigation_page': 'nnp_team_list_page'},
        ),
      );
      await tester.pumpWidget(signedInApp(push: push));
      await tester.pumpAndSettle();
      expect(_id(TeamsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a notification while the app is open shows a banner', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final push = FakePushPlatform();
      await tester.pumpWidget(signedInApp(push: push));
      await tester.pumpAndSettle();
      push.foregroundController.add(
        const PushMessage(
          id: 'f1',
          title: 'Game on',
          body: 'Tonight at 7',
          data: {'navigation_page': 'nnp_team_list_page'},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Game on'), findsOneWidget);
      await tester.tap(find.byType(SnackBarAction));
      await tester.pumpAndSettle();
      expect(_id(TeamsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('signing in registers the device', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final settings = FakeSettingsRepository();
      await tester.pumpWidget(
        signedInApp(
          push: FakePushPlatform(available: true),
          settings: settings,
        ),
      );
      await tester.pumpAndSettle();
      expect(settings.registrations.single.token, 'device-token-1');
      handle.dispose();
    });
  });
}
