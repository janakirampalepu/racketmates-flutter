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

/// `events_show_accepted` with [action] as the user's primary action.
EventDetailsResponse _offering(String action, {String access = 'up_enabled'}) {
  final json = apiFixture('events_show_accepted');
  final mine =
      ((json['event'] as Map<String, dynamic>)['current_user_event_details']
                  as List)
              .first
          as Map<String, dynamic>;
  mine['primary_action'] = {'action': action, 'access': access};
  return EventDetailsResponse.fromJson(json);
}

Future<FakeEventActionsRepository> _open(
  WidgetTester tester,
  EventDetailsResponse initial, {
  AppFailure? failure,
}) async {
  useTallScreen(tester);
  final actions = FakeEventActionsRepository(
    response: EventDetailsResponse.fromJson(apiFixture('events_show_accepted')),
    failure: failure,
  );
  await tester.pumpWidget(
    signedInApp(
      schedule: FakeScheduleRepository(event: initial.event),
      actions: actions,
    ),
  );
  await tester.pumpAndSettle();
  final context = tester.element(_id(HomeTestIds.root));
  unawaited(GoRouter.of(context).push(AppRoutes.eventFor(101)));
  await tester.pumpAndSettle();
  return actions;
}

Future<void> _tapAndWait(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  const confirm = 'user_action_confirm_scores';

  testWidgets('confirming scores posts accept_scores and follows the server', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final actions = await _open(tester, _offering(confirm));
    expect(find.text('Confirm scores'), findsOneWidget);

    await _tapAndWait(tester, _id(EventDetailsTestIds.confirmScores));

    expect(actions.calls, ['acceptScores']);
    expect(find.text('Scores confirmed.'), findsOneWidget);
    // The returned event no longer offers it.
    expect(_id(EventDetailsTestIds.confirmScores), findsNothing);
    handle.dispose();
  });

  testWidgets('a rejected confirmation shows the server message', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final actions = await _open(
      tester,
      _offering(confirm),
      failure: const ServerFailure(422, 'Scores are already confirmed'),
    );
    await _tapAndWait(tester, _id(EventDetailsTestIds.confirmScores));
    expect(actions.calls, ['acceptScores']);
    expect(find.text('Scores are already confirmed'), findsOneWidget);
    expect(_id(EventDetailsTestIds.confirmScores), findsOneWidget);
    handle.dispose();
  });

  testWidgets('it is not offered unless the server enables it', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _offering(confirm, access: 'up_disabled'));
    expect(_id(EventDetailsTestIds.confirmScores), findsNothing);
    handle.dispose();
  });

  testWidgets('another action does not offer it', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _offering('user_action_submit_scores'));
    expect(_id(EventDetailsTestIds.confirmScores), findsNothing);
    handle.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets(
      'confirm scores meets guidelines (${dark ? 'dark' : 'light'})',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await _open(tester, _offering(confirm));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      },
    );
  }
}
