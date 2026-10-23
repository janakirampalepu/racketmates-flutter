import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/screens/event_manage/event_manage_test_ids.dart';
import 'package:racketmates/screens/event_manage_rounds/event_manage_rounds_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';
import '../../support/fixtures.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

const _courtsAt = PlaceItem(
  id: 5,
  name: 'Central Courts',
  addressDetail: PlaceAddress(latitude: 40.7, longitude: -74),
);

Future<FakeEventActionsRepository> _open(
  WidgetTester tester,
  String fixture,
  String route, {
  AppFailure? failure,
  String? generateResult,
}) async {
  useTallScreen(tester);
  final actions = FakeEventActionsRepository(failure: failure)
    ..generateResult = generateResult;
  await tester.pumpWidget(
    signedInApp(
      schedule: FakeScheduleRepository(
        event: EventDetailsResponse.fromJson(apiFixture(fixture)).event,
      ),
      actions: actions,
      places: FakePlacesRepository(
        places: [_courtsAt],
        detailsById: {
          5: _courtsAt.copyWith(
            placeCourts: const [
              PlaceCourt(id: 11, name: 'Court 1', sportType: 'st_tennis'),
              PlaceCourt(id: 12, name: 'Court 2', sportType: 'st_tennis'),
              PlaceCourt(id: 13, name: 'Court 3', sportType: 'st_tennis'),
            ],
          ),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  final context = tester.element(_id(HomeTestIds.root));
  unawaited(GoRouter.of(context).push(route));
  await tester.pumpAndSettle();
  return actions;
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

void main() {
  final rounds = AppRoutes.eventManageRoundsFor(101);
  final hub = AppRoutes.eventManageFor(101);

  group('hub entry', () {
    testWidgets('managing rounds opens them', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'events_show_manage_rounds', hub);
      expect(find.text('Rounds'), findsOneWidget);
      await _tap(tester, EventManageTestIds.rounds);
      expect(_id(EventManageRoundsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('setting up generates the rounds, then opens them', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, 'events_show_setup_rounds', hub);
      expect(find.text('Set up rounds'), findsOneWidget);
      await _tap(tester, EventManageTestIds.rounds);
      expect(actions.manageCalls.single.name, 'generateRounds:101');
      expect(_id(EventManageRoundsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('too few confirmed players is explained, not opened', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        'events_show_setup_rounds',
        hub,
        generateResult: 'egr_insufficient_confirmed_players',
      );
      await _tap(tester, EventManageTestIds.rounds);
      expect(_id(EventManageTestIds.roundsWaitingDialog), findsOneWidget);
      expect(find.text('Waiting for players'), findsOneWidget);
      await _tap(tester, EventManageRoundsTestIds.waitingOk);
      expect(_id(EventManageRoundsTestIds.root), findsNothing);
      expect(_id(EventManageTestIds.rounds), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a generation the server rejects shows its message', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        'events_show_setup_rounds',
        hub,
        failure: const ServerFailure(500, 'Could not generate'),
      );
      await tester.tap(_id(EventManageTestIds.rounds));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Could not generate'), findsOneWidget);
      expect(_id(EventManageRoundsTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets('fixed partners are not available yet', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(
        tester,
        'events_show_setup_rounds_fixed',
        hub,
      );
      expect(
        find.text(
          'Choosing fixed partners is not available in this build yet.',
        ),
        findsOneWidget,
      );
      await tester.tap(_id(EventManageTestIds.rounds), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(actions.manageCalls, isEmpty);
      handle.dispose();
    });

    testWidgets('no round robin permission, no entry', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'events_show_manage_game', hub);
      expect(_id(EventManageTestIds.rounds), findsNothing);
      handle.dispose();
    });
  });

  group('rounds', () {
    testWidgets('shows a round and its matches, and switches rounds', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'events_show_manage_rounds', rounds);
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('Round 2'), findsOneWidget);
      expect(_id(EventManageRoundsTestIds.match(501)), findsOneWidget);
      expect(find.textContaining('Alex Kim vs Pat Lee'), findsOneWidget);
      expect(find.textContaining('Court 1'), findsOneWidget);
      expect(find.textContaining('No court'), findsOneWidget);
      expect(_id(EventManageRoundsTestIds.match(503)), findsNothing);

      await _tap(tester, EventManageRoundsTestIds.round(702));
      expect(_id(EventManageRoundsTestIds.match(503)), findsOneWidget);
      expect(_id(EventManageRoundsTestIds.match(501)), findsNothing);
      handle.dispose();
    });

    testWidgets('a round is added', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, 'events_show_manage_rounds', rounds);
      await _tap(tester, EventManageRoundsTestIds.add);
      expect(actions.manageCalls.single.name, 'addRound:101');
      handle.dispose();
    });

    testWidgets('only the last round can be removed, after asking', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, 'events_show_manage_rounds', rounds);
      expect(_id(EventManageRoundsTestIds.remove), findsNothing);

      await _tap(tester, EventManageRoundsTestIds.round(702));
      await _tap(tester, EventManageRoundsTestIds.remove);
      await _tap(tester, EventManageRoundsTestIds.confirmNo);
      expect(actions.manageCalls, isEmpty);

      await _tap(tester, EventManageRoundsTestIds.remove);
      await _tap(tester, EventManageRoundsTestIds.confirmYes);
      expect(actions.manageCalls.single.name, 'removeRound:101:702');
      handle.dispose();
    });

    testWidgets('a match is removed after asking', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, 'events_show_manage_rounds', rounds);
      await _tap(tester, EventManageRoundsTestIds.matchMenu(501));
      await _tap(tester, EventManageRoundsTestIds.matchRemove(501));
      await _tap(tester, EventManageRoundsTestIds.confirmNo);
      expect(actions.manageCalls, isEmpty);

      await _tap(tester, EventManageRoundsTestIds.matchMenu(501));
      await _tap(tester, EventManageRoundsTestIds.matchRemove(501));
      await _tap(tester, EventManageRoundsTestIds.confirmYes);
      expect(actions.manageCalls.single.name, 'removeMatch:101:501');
      handle.dispose();
    });

    testWidgets('a match moves to another court of the event', (tester) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, 'events_show_manage_rounds', rounds);
      await _tap(tester, EventManageRoundsTestIds.matchMenu(502));
      await _tap(tester, EventManageRoundsTestIds.matchCourt(502));
      // Only the event's own courts (11 and 12), not the venue's court 13.
      expect(_id(EventManageRoundsTestIds.court(11)), findsOneWidget);
      expect(_id(EventManageRoundsTestIds.court(12)), findsOneWidget);
      expect(_id(EventManageRoundsTestIds.court(13)), findsNothing);
      await _tap(tester, EventManageRoundsTestIds.court(12));
      expect(actions.manageCalls.single.name, 'updateMatches:101');
      expect(actions.manageCalls.single.data, {
        'event': {
          'event_matches_attributes': [
            {'id': 502, 'place_court_id': 12},
          ],
        },
      });
      handle.dispose();
    });

    testWidgets('choosing the court it is already on does nothing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final actions = await _open(tester, 'events_show_manage_rounds', rounds);
      await _tap(tester, EventManageRoundsTestIds.matchMenu(501));
      await _tap(tester, EventManageRoundsTestIds.matchCourt(501));
      await _tap(tester, EventManageRoundsTestIds.court(11));
      expect(actions.manageCalls, isEmpty);
      handle.dispose();
    });

    testWidgets('a failure shows the server message', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        'events_show_manage_rounds',
        rounds,
        failure: const ServerFailure(422, 'Round cannot be added'),
      );
      await _tap(tester, EventManageRoundsTestIds.add);
      expect(find.text('Round cannot be added'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('formats other than manual are read only', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'events_show_rounds_classic', rounds);
      expect(_id(EventManageRoundsTestIds.match(501)), findsOneWidget);
      expect(_id(EventManageRoundsTestIds.add), findsNothing);
      expect(_id(EventManageRoundsTestIds.matchMenu(501)), findsNothing);
      await _tap(tester, EventManageRoundsTestIds.round(702));
      expect(_id(EventManageRoundsTestIds.remove), findsNothing);
      handle.dispose();
    });

    testWidgets('an event without rounds says so', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'events_show_setup_rounds', rounds);
      expect(_id(EventManageRoundsTestIds.empty), findsOneWidget);
      handle.dispose();
    });
  });

  for (final dark in [false, true]) {
    testWidgets('rounds meet guidelines (${dark ? 'dark' : 'light'})', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _open(tester, 'events_show_manage_rounds', rounds);
      await _tap(tester, EventManageRoundsTestIds.round(702));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
