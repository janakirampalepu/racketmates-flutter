import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/event_manage_pairs/event_manage_pairs_test_ids.dart';
import 'package:racketmates/screens/event_manage_rounds/event_manage_rounds_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';
import '../../support/fixtures.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

EventParticipant _p(int id, String first, String last) => EventParticipant(
  id: id * 10,
  userId: id,
  user: AppUser(id: id, firstName: first, lastName: last),
);

final _ann = _p(1, 'Ann', 'Lee');
final _bo = _p(2, 'Bo', 'Chan');
final _cy = _p(3, 'Cy', 'Park');
final _di = _p(4, 'Di', 'Ng');
final _ed = _p(5, 'Ed', 'Ito');

Future<FakeEventActionsRepository> _open(
  WidgetTester tester, {
  List<List<EventParticipant>> pairs = const [],
  List<EventParticipant> loose = const [],
  AppFailure? failure,
  String? generateResult,
}) async {
  useTallScreen(tester);
  final actions = FakeEventActionsRepository(failure: failure)
    ..generateResult = generateResult
    ..participantGroups = {
      'pairs': [EventParticipantGroup(eventParticipantPairs: pairs)],
      '': [EventParticipantGroup(eventParticipants: loose)],
    };
  await tester.pumpWidget(
    signedInApp(
      schedule: FakeScheduleRepository(
        event: EventDetailsResponse.fromJson(
          apiFixture('events_show_setup_rounds_fixed'),
        ).event,
      ),
      actions: actions,
    ),
  );
  await tester.pumpAndSettle();
  final context = tester.element(_id(HomeTestIds.root));
  unawaited(GoRouter.of(context).push(AppRoutes.eventManagePairsFor(101)));
  await tester.pumpAndSettle();
  return actions;
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the pairs and the players without a partner', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(
      tester,
      pairs: [
        [_ann, _bo],
      ],
      loose: [_cy, _di],
    );
    expect(find.text('Ann Lee & Bo Chan'), findsOneWidget);
    expect(_id(EventManagePairsTestIds.player(3)), findsOneWidget);
    expect(_id(EventManagePairsTestIds.player(4)), findsOneWidget);
    expect(_id(EventManagePairsTestIds.noPairs), findsNothing);
    handle.dispose();
  });

  testWidgets('no pairs and nobody left say so', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);
    expect(_id(EventManagePairsTestIds.noPairs), findsOneWidget);
    expect(_id(EventManagePairsTestIds.unpairedNone), findsOneWidget);
    handle.dispose();
  });

  testWidgets('two players are paired, and a pair can be undone', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, loose: [_cy, _di, _ed]);
    OutlinedButton pair() => tester.widget<OutlinedButton>(
      find.descendant(
        of: _id(EventManagePairsTestIds.pair),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(pair().onPressed, isNull);

    await _tap(tester, EventManagePairsTestIds.player(3));
    expect(pair().onPressed, isNull); // one is not a pair
    await _tap(tester, EventManagePairsTestIds.player(4));
    expect(pair().onPressed, isNotNull);
    // Two chosen: the third waits.
    expect(
      tester
          .widget<CheckboxListTile>(
            find.descendant(
              of: _id(EventManagePairsTestIds.player(5)),
              matching: find.byType(CheckboxListTile),
            ),
          )
          .onChanged,
      isNull,
    );

    await _tap(tester, EventManagePairsTestIds.pair);
    expect(find.text('Cy Park & Di Ng'), findsOneWidget);
    expect(_id(EventManagePairsTestIds.player(3)), findsNothing);
    expect(_id(EventManagePairsTestIds.player(5)), findsOneWidget);

    await _tap(tester, EventManagePairsTestIds.removeAdded(0));
    expect(find.text('Cy Park & Di Ng'), findsNothing);
    expect(_id(EventManagePairsTestIds.player(3)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('continuing without new pairs generates and opens the rounds', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final actions = await _open(
      tester,
      pairs: [
        [_ann, _bo],
      ],
      loose: [_cy],
    );
    await _tap(tester, EventManagePairsTestIds.next);
    expect(actions.manageCalls.single.name, 'generateRounds:101');
    expect(
      actions.manageCalls.single.data,
      isNull,
    ); // the server keeps its pairs
    expect(_id(EventManageRoundsTestIds.root), findsOneWidget);
    expect(_id(EventManagePairsTestIds.root), findsNothing);
    handle.dispose();
  });

  testWidgets('new pairs are sent with the existing ones', (tester) async {
    final handle = tester.ensureSemantics();
    final actions = await _open(
      tester,
      pairs: [
        [_ann, _bo],
      ],
      loose: [_cy, _di],
    );
    await _tap(tester, EventManagePairsTestIds.player(3));
    await _tap(tester, EventManagePairsTestIds.player(4));
    await _tap(tester, EventManagePairsTestIds.pair);
    await _tap(tester, EventManagePairsTestIds.next);
    expect(actions.manageCalls.single.data, [
      [1, 2],
      [3, 4],
    ]);
    handle.dispose();
  });

  testWidgets('too few players is explained and nothing opens', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(
      tester,
      generateResult: 'egr_insufficient_confirmed_players',
      loose: [_cy],
    );
    await _tap(tester, EventManagePairsTestIds.next);
    expect(find.text('Waiting for players'), findsOneWidget);
    await _tap(tester, EventManagePairsTestIds.waitingOk);
    expect(_id(EventManagePairsTestIds.root), findsOneWidget);
    expect(_id(EventManageRoundsTestIds.root), findsNothing);
    handle.dispose();
  });

  testWidgets('a rejected generation shows the server message', (tester) async {
    final handle = tester.ensureSemantics();
    // The failure applies to the lists too: load them first, then fail.
    final actions = await _open(tester, loose: [_cy]);
    actions.failure = const ServerFailure(500, 'Could not generate');
    await _tap(tester, EventManagePairsTestIds.next);
    expect(find.text('Could not generate'), findsOneWidget);
    expect(_id(EventManagePairsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('players are filtered by the match type they prefer', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final actions = await _open(tester, loose: [_cy]);
    expect(_id(EventManagePairsTestIds.filter('all')), findsOneWidget);
    await _tap(tester, EventManagePairsTestIds.filter('mt_doubles'));
    expect(actions.participantQueries.last['preferredMatchType'], 'mt_doubles');
    expect(actions.participantQueries.last['excludeWithPartner'], isTrue);
    await _tap(tester, EventManagePairsTestIds.filter('mt_undecided'));
    expect(
      actions.participantQueries.last['preferredMatchType'],
      'mt_undecided',
    );
    await _tap(tester, EventManagePairsTestIds.filter('all'));
    expect(actions.participantQueries.last['preferredMatchType'], isNull);
    handle.dispose();
  });

  testWidgets('players that cannot be loaded show a message', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, failure: const OfflineFailure());
    expect(find.text('The players could not be loaded.'), findsOneWidget);
    handle.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets('pairs meet guidelines (${dark ? 'dark' : 'light'})', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _open(
        tester,
        pairs: [
          [_ann, _bo],
        ],
        loose: [_cy, _di],
      );
      await _tap(tester, EventManagePairsTestIds.player(3));
      await _tap(tester, EventManagePairsTestIds.player(4));
      await _tap(tester, EventManagePairsTestIds.pair);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
