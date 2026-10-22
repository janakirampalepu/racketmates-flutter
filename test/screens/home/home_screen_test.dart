import 'package:racketmates/common/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';
import '../../support/fixtures.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

FakeScheduleRepository _fullRepo() => FakeScheduleRepository(
  upcoming: [
    scheduleItem(1),
    scheduleItem(2, type: 'et_practice'),
  ],
  past: [scheduleItem(3, date: '2026-10-01')],
  pending: const [
    PendingAction(
      eventId: 4,
      eventType: 'et_game',
      eventDate: '2026-11-04',
      eventParticipantUser: AppUser(firstName: 'Sam', lastName: 'Lee'),
    ),
  ],
  activity: const [
    HomePageStats(wins: 5, losses: 3, totalEvents: 9, totalHours: 18),
  ],
  updates: const [
    PlayerCard(
      id: 55,
      title: 'Game result',
      message: 'You won 6-4',
      eventId: 98,
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
      expect(_id(HomeTestIds.event('upcoming', 1)), findsOneWidget);
      expect(_id(HomeTestIds.event('upcoming', 2)), findsOneWidget);
      expect(_id(HomeTestIds.update(55)), findsOneWidget);
      expect(find.text('Game result'), findsOneWidget);
      expect(find.text('Wins'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(_id(HomeTestIds.event('past', 3)), findsOneWidget);
      expect(repo.calls.toSet(), {
        'pending',
        'upcoming',
        'updates',
        'activity',
        'past',
      });
      handle.dispose();
    },
  );

  testWidgets('empty sections show their empty text', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(signedInApp());
    await tester.pumpAndSettle();
    expect(find.text('Nothing needs your attention.'), findsOneWidget);
    expect(find.text('No upcoming events.'), findsOneWidget);
    expect(find.text('No updates yet.'), findsOneWidget);
    expect(find.text('No activity yet.'), findsOneWidget);
    expect(find.text('No past events.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('one failing section shows retry while the others still render', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final repo = _fullRepo()..failing.add('upcoming');
    await tester.pumpWidget(signedInApp(schedule: repo));
    await tester.pumpAndSettle();

    expect(find.text('Could not load this section.'), findsOneWidget);
    expect(_id(HomeTestIds.pendingAction(4)), findsOneWidget);
    expect(_id(HomeTestIds.event('past', 3)), findsOneWidget);

    repo.failing.clear();
    await tester.tap(_id(HomeTestIds.retry(HomeTestIds.upcomingSection)));
    await tester.pumpAndSettle();
    expect(find.text('Could not load this section.'), findsNothing);
    expect(_id(HomeTestIds.event('upcoming', 1)), findsOneWidget);
    handle.dispose();
  });

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
    expect(repo.calls.toSet(), {
      'pending',
      'upcoming',
      'updates',
      'activity',
      'past',
    });
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

  testWidgets('signing out returns to welcome', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(signedInApp());
    await tester.pumpAndSettle();
    await tester.tap(_id(HomeTestIds.signOutButton));
    await tester.pumpAndSettle();
    expect(_id(WelcomeTestIds.root), findsOneWidget);
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
