import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/create_event/drafts_models.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';
import '../../support/fixtures.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

Future<void> _openSchedule(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(MainShellTestIds.navSchedule));
  await tester.pumpAndSettle();
  expect(_id(ScheduleTestIds.root), findsOneWidget);
}

void main() {
  testWidgets('upcoming list renders server data and opens event details', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final repo = FakeScheduleRepository(
      pages: {
        ScheduleTab.upcoming: [
          [scheduleItem(1), scheduleItem(2, type: 'et_practice')],
        ],
      },
      event: EventDetailsResponse.fromJson(apiFixture('events_show')).event,
    );
    await tester.pumpWidget(signedInApp(schedule: repo));
    await _openSchedule(tester);

    expect(_id(ScheduleTestIds.event('upcoming', 1)), findsOneWidget);
    expect(_id(ScheduleTestIds.event('upcoming', 2)), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('6:00 PM - 7:30 PM'), findsWidgets);
    // No swipeLeft/swipeRight on this fixture: falls back to "View event".
    expect(find.text('View event'), findsWidgets);

    await tester.tap(_id(ScheduleTestIds.event('upcoming', 1)));
    await tester.pumpAndSettle();
    expect(_id(EventDetailsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the List/Calendar toggle shows a placeholder for Calendar', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository();
    await tester.pumpWidget(signedInApp(schedule: repo));
    await _openSchedule(tester);
    expect(_id(ScheduleTestIds.calendarPlaceholder), findsNothing);

    await tester.tap(_id(ScheduleTestIds.viewToggleCalendar));
    await tester.pumpAndSettle();
    expect(_id(ScheduleTestIds.calendarPlaceholder), findsOneWidget);

    await tester.tap(_id(ScheduleTestIds.viewToggleList));
    await tester.pumpAndSettle();
    expect(_id(ScheduleTestIds.calendarPlaceholder), findsNothing);
    handle.dispose();
  });

  testWidgets(
    'scrolling to the end loads the next page until a page is empty',
    (tester) async {
      final handle = tester.ensureSemantics();
      final repo = FakeScheduleRepository(
        pages: {
          ScheduleTab.upcoming: [
            [for (var i = 1; i <= 10; i++) scheduleItem(i)],
            [for (var i = 11; i <= 12; i++) scheduleItem(i)],
          ],
        },
      );
      await tester.pumpWidget(signedInApp(schedule: repo));
      await _openSchedule(tester);
      expect(repo.requestedPages, [1]);

      final list = find.byKey(Key(ScheduleTestIds.list('upcoming')));
      await tester.drag(list, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(repo.requestedPages, [1, 2]);
      await tester.drag(list, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(_id(ScheduleTestIds.event('upcoming', 12)), findsOneWidget);
      expect(repo.requestedPages, [1, 2, 3]); // page 3 empty -> stop

      await tester.drag(list, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(repo.requestedPages, [1, 2, 3]);
      handle.dispose();
    },
  );

  testWidgets('owner filter narrows the request to managing only', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository(
      pages: {
        ScheduleTab.upcoming: [
          [scheduleItem(1)],
        ],
      },
    );
    await tester.pumpWidget(signedInApp(schedule: repo));
    await _openSchedule(tester);
    expect(repo.lastEventRoles, ['managing', 'participant']);

    await tester.tap(_id(ScheduleTestIds.filterButton));
    await tester.pumpAndSettle();
    await tester.tap(_id(ScheduleFilterTestIds.ownerParticipant));
    await tester.pumpAndSettle();
    await tester.tap(_id(ScheduleFilterTestIds.apply));
    await tester.pumpAndSettle();

    expect(repo.lastEventRoles, ['managing']);
    handle.dispose();
  });

  testWidgets(
    'the past row is always offered; drafts/to-be-rescheduled hide when empty',
    (tester) async {
      final handle = tester.ensureSemantics();
      final repo = FakeScheduleRepository();
      await tester.pumpWidget(signedInApp(schedule: repo));
      await _openSchedule(tester);
      expect(_id(ScheduleTestIds.topRowDrafts), findsNothing);
      expect(_id(ScheduleTestIds.topRowToBeScheduled), findsNothing);
      expect(_id(ScheduleTestIds.topRowPast), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    'the drafts/to-be-rescheduled rows show with a count when non-empty',
    (tester) async {
      final handle = tester.ensureSemantics();
      final repo = FakeScheduleRepository()
        ..toBeScheduledItems = [scheduleItem(5)];
      await tester.pumpWidget(
        signedInApp(
          schedule: repo,
          drafts: FakeDraftsRepository(
            drafts: const [DraftSummary(eventId: 1, eventType: 'et_casual')],
          ),
        ),
      );
      await _openSchedule(tester);
      expect(_id(ScheduleTestIds.topRowDrafts), findsOneWidget);
      expect(_id(ScheduleTestIds.topRowToBeScheduled), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    'a failed drafts fetch keeps the row reachable instead of hiding it',
    (tester) async {
      final handle = tester.ensureSemantics();
      final drafts = FakeDraftsRepository()..listFails = true;
      await tester.pumpWidget(
        signedInApp(schedule: FakeScheduleRepository(), drafts: drafts),
      );
      await _openSchedule(tester);
      expect(_id(ScheduleTestIds.topRowDrafts), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('the to-be-rescheduled row opens its own screen', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository()
      ..toBeScheduledItems = [scheduleItem(5)];
    await tester.pumpWidget(signedInApp(schedule: repo));
    await _openSchedule(tester);

    expect(_id(ScheduleTestIds.topRowToBeScheduled), findsOneWidget);
    await tester.tap(_id(ScheduleTestIds.topRowToBeScheduled));
    await tester.pumpAndSettle();
    expect(_id(ToBeScheduledTestIds.root), findsOneWidget);
    expect(_id(ToBeScheduledTestIds.event(5)), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'the past-events row opens its own screen; empty and error states',
    (tester) async {
      final handle = tester.ensureSemantics();
      final repo = FakeScheduleRepository()..failing.add('page-past');
      await tester.pumpWidget(signedInApp(schedule: repo));
      await _openSchedule(tester);
      expect(_id(ScheduleTestIds.empty('upcoming')), findsOneWidget);
      expect(find.text('You have no upcoming events.'), findsOneWidget);

      await tester.tap(_id(ScheduleTestIds.topRowPast));
      await tester.pumpAndSettle();
      expect(_id(PastEventsTestIds.root), findsOneWidget);
      expect(find.text('Could not load past events.'), findsOneWidget);

      repo
        ..failing.clear()
        ..pages[ScheduleTab.past] = [
          [scheduleItem(9, date: '2026-09-01')],
        ];
      await tester.tap(_id(ScheduleTestIds.retry('past')));
      await tester.pumpAndSettle();
      expect(_id(ScheduleTestIds.event('past', 9)), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('a server failure message replaces the generic text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository()
      ..failing.add('page-upcoming')
      ..failure = const ServerFailure(500, 'Could not load this schedule.');
    await tester.pumpWidget(signedInApp(schedule: repo));
    await _openSchedule(tester);
    expect(find.text('Could not load this schedule.'), findsOneWidget);
    expect(find.text('Could not load events.'), findsNothing);
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('schedule meets contrast and tap-target guidelines ($mode)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue =
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      useTallScreen(tester);
      final repo = FakeScheduleRepository(
        pages: {
          ScheduleTab.upcoming: [
            [scheduleItem(1), scheduleItem(2)],
          ],
        },
      );
      await tester.pumpWidget(signedInApp(schedule: repo));
      await _openSchedule(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
