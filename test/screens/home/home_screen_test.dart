import 'package:racketmates/common/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/startup/downtime.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/widgets/family_user_picker.dart';
import 'package:racketmates/l10n/app_localizations_en.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';
import 'package:racketmates/screens/settings/settings_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';
import '../../support/fixtures.dart';

final _l10n = AppLocalizationsEn();

Finder _id(String id) => find.bySemanticsIdentifier(id);

FakeScheduleRepository _fullRepo() => FakeScheduleRepository(
  upcoming: [
    scheduleItem(1),
    scheduleItem(2, type: 'et_practice'),
  ],
  pending: const [
    PendingAction(
      eventId: 4,
      eventType: 'et_game',
      eventDate: '2026-11-04',
      eventParticipantUser: AppUser(firstName: 'Sam', lastName: 'Lee'),
      primarySwipeAction: 'user_action_submit_scores',
    ),
  ],
  activity: const [
    HomePageStats(
      year: 2026,
      wins: 5,
      losses: 3,
      totalEvents: 9,
      totalHours: 18,
      gamesHours: 10,
      practiceHours: 5,
      lessonHours: 2,
      meetingHours: 1,
      weeklyAverageValue: '2h',
    ),
  ],
  event: EventDetailsResponse.fromJson(apiFixture('events_show')).event,
);

void main() {
  testWidgets(
    'a restored session lands on home and every section shows its data',
    (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final repo = _fullRepo();
      await tester.pumpWidget(signedInApp(schedule: repo));
      await tester.pumpAndSettle();

      expect(_id(HomeTestIds.root), findsOneWidget);
      expect(find.text('Hi, Sam'), findsOneWidget);
      expect(_id(HomeTestIds.pendingAction(4)), findsOneWidget);
      expect(find.text(_l10n.eventSubmitScores), findsOneWidget);
      expect(_id(HomeTestIds.event('upcoming', 1)), findsOneWidget);
      expect(_id(HomeTestIds.event('upcoming', 2)), findsOneWidget);
      expect(find.text('Wins'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('18h'), findsOneWidget);
      expect(_id(HomeTestIds.activityYear), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      // Neither native app currently fetches these.
      expect(repo.calls.toSet(), {'pending', 'upcoming', 'activity'});
      handle.dispose();
    },
  );

  testWidgets(
    'empty upcoming offers to create an event; pending shows its empty text',
    (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await tester.pumpAndSettle();
      expect(find.text(_l10n.emptyPendingActions), findsOneWidget);
      expect(find.text(_l10n.emptyUpcoming), findsOneWidget);
      expect(_id(HomeTestIds.createEvent), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('one failing section shows retry while the others still render', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final repo = _fullRepo()..failing.add('upcoming');
    await tester.pumpWidget(signedInApp(schedule: repo));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.sectionLoadError), findsOneWidget);
    expect(_id(HomeTestIds.pendingAction(4)), findsOneWidget);

    repo.failing.clear();
    await tester.tap(_id(HomeTestIds.retry(HomeTestIds.upcomingSection)));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.sectionLoadError), findsNothing);
    expect(_id(HomeTestIds.event('upcoming', 1)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a server failure message replaces the generic text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final repo = _fullRepo()
      ..failing.add('upcoming')
      ..failure = const ServerFailure(500, 'The schedule service is down.');
    await tester.pumpWidget(signedInApp(schedule: repo));
    await tester.pumpAndSettle();

    expect(find.text('The schedule service is down.'), findsOneWidget);
    expect(find.text(_l10n.sectionLoadError), findsNothing);
    handle.dispose();
  });

  testWidgets(
    'a pending action with no recognized swipe action still offers a button',
    (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final repo = _fullRepo()
        ..pending = const [
          PendingAction(
            eventId: 9,
            eventType: 'et_game',
            eventDate: '2026-11-04',
          ),
        ];
      await tester.pumpWidget(signedInApp(schedule: repo));
      await tester.pumpAndSettle();

      expect(find.text(_l10n.homePendingViewDetails), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('pull to refresh reloads all sections', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester, height: 900);
    final repo = _fullRepo();
    await tester.pumpWidget(signedInApp(schedule: repo));
    await tester.pumpAndSettle();
    repo.calls.clear();
    await tester.drag(
      find.byKey(const Key(HomeTestIds.list)),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    expect(repo.calls.toSet(), {'pending', 'upcoming', 'activity'});
    handle.dispose();
  });

  testWidgets('tapping an event opens its details and back returns home', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(signedInApp(schedule: _fullRepo()));
    await tester.pumpAndSettle();
    await tester.tap(_id(HomeTestIds.event('upcoming', 1)));
    await tester.pumpAndSettle();
    expect(_id(EventDetailsTestIds.root), findsOneWidget);

    await tester.tap(_id(EventDetailsTestIds.back));
    await tester.pumpAndSettle();
    expect(_id(HomeTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('See all opens the schedule tab', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(signedInApp(schedule: _fullRepo()));
    await tester.pumpAndSettle();
    await tester.tap(_id(HomeTestIds.seeAllUpcoming));
    await tester.pumpAndSettle();
    expect(_id(ScheduleTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('settings opens from home', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(signedInApp());
    await tester.pumpAndSettle();
    await tester.tap(_id(HomeTestIds.settingsButton));
    await tester.pumpAndSettle();
    expect(_id(SettingsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('profile failure does not break home', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(
      signedInApp(users: FakeUserRepository(failure: const OfflineFailure())),
    );
    await tester.pumpAndSettle();
    expect(_id(HomeTestIds.root), findsOneWidget);
    expect(
      find.descendant(
        of: _id(HomeTestIds.greeting),
        matching: find.text('Home'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  group('family picker', () {
    FakeUserRepository withKids() => FakeUserRepository(
      profile: const UserDetails(
        user: AppUser(
          id: 7,
          firstName: 'Sam',
          lastName: 'Lee',
          children: [AppUser(id: 8, firstName: 'Alex', lastName: 'Lee')],
        ),
      ),
    );

    testWidgets('hidden for a user with no kids', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await tester.pumpAndSettle();
      expect(_id(FamilyPickerTestIds.row), findsNothing);
      handle.dispose();
    });

    testWidgets(
      'shown for a parent, and selecting a kid reloads every section',
      (tester) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        final repo = _fullRepo();
        await tester.pumpWidget(signedInApp(schedule: repo, users: withKids()));
        await tester.pumpAndSettle();
        expect(_id(FamilyPickerTestIds.row), findsOneWidget);

        repo.calls.clear();
        await tester.tap(_id(FamilyPickerTestIds.row));
        await tester.pumpAndSettle();
        expect(_id(FamilyPickerTestIds.sheet), findsOneWidget);
        expect(_id(FamilyPickerTestIds.memberRow(8)), findsOneWidget);

        await tester.tap(_id(FamilyPickerTestIds.memberRow(8)));
        await tester.tap(_id(FamilyPickerTestIds.save));
        await tester.pumpAndSettle();

        expect(repo.calls.toSet(), {'pending', 'upcoming', 'activity'});
        handle.dispose();
      },
    );

    testWidgets('refuses to save with nobody selected', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp(users: withKids()));
      await tester.pumpAndSettle();
      await tester.tap(_id(FamilyPickerTestIds.row));
      await tester.pumpAndSettle();

      // Parent is checked first (its checkbox is the first interactive
      // element in the parent's row); uncheck it and try to save.
      await tester.tap(
        find.descendant(
          of: _id(FamilyPickerTestIds.sheet),
          matching: find.byType(Checkbox).first,
        ),
      );
      await tester.tap(_id(FamilyPickerTestIds.save));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.familyPickerSelectAtLeastOne), findsOneWidget);
      handle.dispose();
    });
  });

  group('maintenance banner', () {
    testWidgets('shows a scheduled maintenance window and can be dismissed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      const incident = Incident(name: 'Planned maintenance');
      await tester.pumpWidget(
        signedInApp(downtime: FakeDowntimeRepository.withMaintenance(incident)),
      );
      await tester.pumpAndSettle();
      expect(_id(HomeTestIds.maintenanceBanner), findsOneWidget);
      expect(find.text('Planned maintenance'), findsOneWidget);

      await tester.tap(_id(HomeTestIds.maintenanceBannerDismiss));
      await tester.pumpAndSettle();
      expect(_id(HomeTestIds.maintenanceBanner), findsNothing);
      handle.dispose();
    });

    testWidgets('does not show when there is no maintenance window', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp());
      await tester.pumpAndSettle();
      expect(_id(HomeTestIds.maintenanceBanner), findsNothing);
      handle.dispose();
    });
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('home meets contrast and tap-target guidelines ($mode)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      tester.platformDispatcher.platformBrightnessTestValue =
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(signedInApp(schedule: _fullRepo()));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
