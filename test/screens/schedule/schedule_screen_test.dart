import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('past tab loads its own list; empty and error states', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository()..failing.add('page-past');
    await tester.pumpWidget(signedInApp(schedule: repo));
    await _openSchedule(tester);

    // Upcoming has no events.
    expect(_id(ScheduleTestIds.empty('upcoming')), findsOneWidget);
    expect(find.text('You have no upcoming events.'), findsOneWidget);

    await tester.tap(_id(ScheduleTestIds.tab('past')));
    await tester.pumpAndSettle();
    expect(find.text('Could not load events.'), findsOneWidget);

    repo
      ..failing.clear()
      ..pages[ScheduleTab.past] = [
        [scheduleItem(9, date: '2026-09-01')],
      ];
    await tester.tap(_id(ScheduleTestIds.retry('past')));
    await tester.pumpAndSettle();
    expect(_id(ScheduleTestIds.event('past', 9)), findsOneWidget);
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
