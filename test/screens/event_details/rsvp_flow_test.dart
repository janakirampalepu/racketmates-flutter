import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';
import '../../support/fixtures.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

EventDetailsResponse _response(String fixture) =>
    EventDetailsResponse.fromJson(apiFixture(fixture));

/// Opens event 101 (loaded from [initial]) like a deep link would.
Future<(FakeScheduleRepository, FakeEventActionsRepository)> _open(
  WidgetTester tester,
  String initial, {
  String? afterAction,
  AppFailure? failure,
}) async {
  useTallScreen(tester);
  final schedule = FakeScheduleRepository(event: _response(initial).event);
  final actions = FakeEventActionsRepository(
    response: afterAction == null ? null : _response(afterAction),
    failure: failure,
  );
  await tester.pumpWidget(signedInApp(schedule: schedule, actions: actions));
  await tester.pumpAndSettle();
  final context = tester.element(_id(HomeTestIds.root));
  unawaited(GoRouter.of(context).push(AppRoutes.eventFor(101)));
  await tester.pumpAndSettle();
  return (schedule, actions);
}

/// Taps and lets the action complete WITHOUT pumpAndSettle, which would also
/// wait out (and dismiss) the snack bar the test wants to read.
Future<void> _tapAndWaitForAction(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets(
    'accept sends the response, shows the updated event and refreshes the lists',
    (tester) async {
      final handle = tester.ensureSemantics();
      final (schedule, actions) = await _open(
        tester,
        'events_show_invited',
        afterAction: 'events_show_accepted',
      );
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      schedule.calls.clear();

      await _tapAndWaitForAction(
        tester,
        _id(EventDetailsTestIds.action('accept')),
      );

      expect(actions.calls, ['accept:101:1']);
      expect(actions.optionIds.single, isEmpty);
      // Buttons now follow the server's new actions.
      expect(find.text('Confirm'), findsNothing);
      expect(find.text('Leave event'), findsOneWidget);
      expect(find.text('Your response was saved.'), findsOneWidget);
      // Home sections were reloaded because the RSVP changes what they show.
      // Home is paused behind the details screen; it reloads when shown again.
      await tester.tap(_id(EventDetailsTestIds.back));
      await tester.pumpAndSettle();
      expect(schedule.calls, containsAll(['upcoming', 'pending']));
      handle.dispose();
    },
  );

  testWidgets('decline asks for confirmation first', (tester) async {
    final handle = tester.ensureSemantics();
    final (_, actions) = await _open(
      tester,
      'events_show_invited',
      afterAction: 'events_show_declined',
    );

    await tester.tap(_id(EventDetailsTestIds.action('decline')));
    await tester.pumpAndSettle();
    await tester.tap(_id(EventDetailsTestIds.confirmDismissButton));
    await tester.pumpAndSettle();
    expect(actions.calls, isEmpty);

    await tester.tap(_id(EventDetailsTestIds.action('decline')));
    await tester.pumpAndSettle();
    await tester.tap(_id(EventDetailsTestIds.confirmButton));
    await tester.pumpAndSettle();
    expect(actions.calls, ['decline:101:1']);
    expect(find.text('Rejoin'), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'leave asks for confirmation, rejoin resends the selected option ids',
    (tester) async {
      final handle = tester.ensureSemantics();
      final (_, actions) = await _open(
        tester,
        'events_show_accepted',
        afterAction: 'events_show_declined',
      );
      await tester.tap(_id(EventDetailsTestIds.action('leave')));
      await tester.pumpAndSettle();
      await tester.tap(_id(EventDetailsTestIds.confirmButton));
      await tester.pumpAndSettle();
      expect(actions.calls, ['leave:101:1']);

      await tester.tap(_id(EventDetailsTestIds.action('rejoin')));
      await tester.pumpAndSettle();
      expect(actions.calls.last, 'rejoin:101:1');
      expect(actions.optionIds.last, [900]);
      handle.dispose();
    },
  );

  testWidgets('full event: join waitlist', (tester) async {
    final handle = tester.ensureSemantics();
    final (_, actions) = await _open(
      tester,
      'events_show_full',
      afterAction: 'events_show_accepted',
    );
    await tester.tap(_id(EventDetailsTestIds.action('joinWaitlist')));
    await tester.pumpAndSettle();
    expect(actions.calls, ['waitlist:101:1']);
    handle.dispose();
  });

  testWidgets(
    'several time options are not silently guessed: explains and sends nothing',
    (tester) async {
      final handle = tester.ensureSemantics();
      final (_, actions) = await _open(tester, 'events_show_multi_option');
      await _tapAndWaitForAction(
        tester,
        _id(EventDetailsTestIds.action('accept')),
      );
      expect(actions.calls, isEmpty);
      expect(
        find.text(
          'Choosing between several times or partners is not available in this build yet.',
        ),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets(
    'subscription-gated action shows the backend message and sends nothing',
    (tester) async {
      final handle = tester.ensureSemantics();
      final (_, actions) = await _open(tester, 'events_show_subscription');
      await _tapAndWaitForAction(
        tester,
        _id(EventDetailsTestIds.action('accept')),
      );
      expect(actions.calls, isEmpty);
      expect(find.text('Upgrade to respond'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    'a rejected response shows the server message and keeps the event',
    (tester) async {
      final handle = tester.ensureSemantics();
      final (_, actions) = await _open(
        tester,
        'events_show_invited',
        failure: const ServerFailure(422, 'This event is full'),
      );
      await _tapAndWaitForAction(
        tester,
        _id(EventDetailsTestIds.action('accept')),
      );
      expect(actions.calls, ['accept:101:1']);
      expect(find.text('This event is full'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget); // still invited
      handle.dispose();
    },
  );

  testWidgets('a network failure shows the generic message', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, 'events_show_invited', failure: const OfflineFailure());
    await _tapAndWaitForAction(
      tester,
      _id(EventDetailsTestIds.action('accept')),
    );
    expect(find.text('Could not update your response.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('managers can cancel with a reason; others cannot', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final (schedule, actions) = await _open(tester, 'events_show_manager');
    await tester.tap(_id(EventDetailsTestIds.menu));
    await tester.pumpAndSettle();
    await tester.tap(_id(EventDetailsTestIds.menuCancelEvent));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: _id(EventDetailsTestIds.cancelReason),
        matching: find.byType(TextField),
      ),
      'Rain',
    );
    schedule.calls.clear();
    await _tapAndWaitForAction(tester, _id(EventDetailsTestIds.cancelConfirm));

    expect(actions.calls, ['cancel:101']);
    expect(actions.cancelReason, 'Rain');
    expect(actions.cancelRemove, isFalse);
    expect(find.text('The event was cancelled.'), findsOneWidget);
    expect(schedule.calls, contains('event-101')); // reloaded
    handle.dispose();
  });

  testWidgets('cancel and remove closes the screen', (tester) async {
    final handle = tester.ensureSemantics();
    final (_, actions) = await _open(tester, 'events_show_manager');
    await tester.tap(_id(EventDetailsTestIds.menu));
    await tester.pumpAndSettle();
    await tester.tap(_id(EventDetailsTestIds.menuCancelEvent));
    await tester.pumpAndSettle();
    await tester.tap(_id(EventDetailsTestIds.cancelRemoveSwitch));
    await tester.pump();
    await _tapAndWaitForAction(tester, _id(EventDetailsTestIds.cancelConfirm));
    expect(actions.cancelRemove, isTrue);
    expect(_id(EventDetailsTestIds.root), findsNothing);
    expect(_id(HomeTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'keeping the event does not call the backend; participants have no cancel menu',
    (tester) async {
      final handle = tester.ensureSemantics();
      final (_, actions) = await _open(tester, 'events_show_manager');
      await tester.tap(_id(EventDetailsTestIds.menu));
      await tester.pumpAndSettle();
      await tester.tap(_id(EventDetailsTestIds.menuCancelEvent));
      await tester.pumpAndSettle();
      await tester.tap(_id(EventDetailsTestIds.cancelKeep));
      await tester.pumpAndSettle();
      expect(actions.calls, isEmpty);
      handle.dispose();
    },
  );

  testWidgets('a participant without manage permission has no cancel menu', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, 'events_show_invited');
    expect(_id(EventDetailsTestIds.menu), findsNothing);
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'RSVP action bar meets contrast and tap-target guidelines ($mode)',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue =
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await _open(tester, 'events_show_invited');
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      },
    );
  }
}
