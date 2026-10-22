import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';
import '../../support/fixtures.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

EventDetails get _event =>
    EventDetailsResponse.fromJson(apiFixture('events_show')).event!;

Future<void> _open(WidgetTester tester, FakeScheduleRepository repo) async {
  await tester.pumpWidget(signedInApp(schedule: repo));
  await tester.pumpAndSettle();
  // Open through the router like a deep link / notification would.
  final context = tester.element(_id(HomeTestIds.root));
  unawaited(GoRouter.of(context).push(AppRoutes.eventFor(101)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows type, status, when, where, own status, spots, notes and players',
    (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final repo = FakeScheduleRepository(event: _event);
      await _open(tester, repo);

      expect(_id(EventDetailsTestIds.root), findsOneWidget);
      expect(find.text('Game'), findsOneWidget);
      expect(find.textContaining('Scheduled'), findsOneWidget);
      expect(_id(EventDetailsTestIds.when), findsOneWidget);
      expect(find.textContaining('Central Courts'), findsOneWidget);
      expect(find.textContaining('1 Main St'), findsOneWidget);
      expect(find.text("You're going\nSee you there"), findsOneWidget);
      expect(find.text('1 spots left'), findsOneWidget);
      expect(find.text('Bring balls'), findsOneWidget);
      // Players only: the coach is not listed.
      expect(_id(EventDetailsTestIds.player(1)), findsOneWidget);
      expect(_id(EventDetailsTestIds.player(2)), findsOneWidget);
      expect(_id(EventDetailsTestIds.player(3)), findsNothing);
      expect(find.text('Sam Lee'), findsOneWidget);
      expect(find.text('Alex Kim'), findsOneWidget);
      expect(repo.calls, contains('event-101'));
      handle.dispose();
    },
  );

  testWidgets('a sparse event renders without place, notes or players', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository(
      event: const EventDetails(id: 101, eventType: 'et_practice'),
    );
    await _open(tester, repo);
    expect(find.text('Practice'), findsOneWidget);
    expect(_id(EventDetailsTestIds.where), findsNothing);
    expect(_id(EventDetailsTestIds.notes), findsNothing);
    expect(find.text('No players yet.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('load failure shows an error and retry fetches again', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository(event: _event)
      ..failing.add('event-101');
    await _open(tester, repo);
    expect(find.text('Could not load this event.'), findsOneWidget);

    repo.failing.clear();
    await tester.tap(_id(EventDetailsTestIds.retry));
    await tester.pumpAndSettle();
    expect(find.text('Game'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a malformed event id falls back to home', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(signedInApp());
    await tester.pumpAndSettle();
    final context = tester.element(_id(HomeTestIds.root));
    unawaited(GoRouter.of(context).push('${AppRoutes.event}/not-a-number'));
    await tester.pumpAndSettle();
    expect(_id(HomeTestIds.root), findsOneWidget);
    expect(_id(EventDetailsTestIds.root), findsNothing);
    handle.dispose();
  });

  testWidgets('event details keep the shell tabs reachable after back', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, FakeScheduleRepository(event: _event));
    await tester.tap(_id(EventDetailsTestIds.back));
    await tester.pumpAndSettle();
    await tester.tap(_id(MainShellTestIds.navSchedule));
    await tester.pumpAndSettle();
    expect(_id(ScheduleTestIds.root), findsOneWidget);
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'event details meets contrast and tap-target guidelines ($mode)',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue =
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        useTallScreen(tester);
        await _open(tester, FakeScheduleRepository(event: _event));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      },
    );
  }
}
