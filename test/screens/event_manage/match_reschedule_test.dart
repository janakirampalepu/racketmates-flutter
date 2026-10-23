import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/screens/create_event_when_where/create_event_when_where_test_ids.dart';
import 'package:racketmates/screens/event_manage/event_manage_test_ids.dart';
import 'package:racketmates/screens/event_manage_schedule/event_manage_schedule_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';
import '../../support/fixtures.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);
Finder _field(String id) =>
    find.descendant(of: _id(id), matching: find.byType(TextField));

const _courtsAt = PlaceItem(
  id: 5,
  name: 'Central Courts',
  addressDetail: PlaceAddress(latitude: 40.7, longitude: -74),
);

Future<FakeEventActionsRepository> _open(
  WidgetTester tester,
  String route, {
  AppFailure? failure,
}) async {
  useTallScreen(tester);
  final actions = FakeEventActionsRepository(failure: failure);
  await tester.pumpWidget(
    signedInApp(
      schedule: FakeScheduleRepository(
        event: EventDetailsResponse.fromJson(
          apiFixture('events_show_manage_game_scheduled'),
        ).event,
      ),
      actions: actions,
      places: FakePlacesRepository(
        places: [_courtsAt],
        detailsById: {
          5: _courtsAt.copyWith(
            placeCourts: const [
              PlaceCourt(id: 11, name: 'Court 1', sportType: 'st_tennis'),
              PlaceCourt(id: 12, name: 'Court 2', sportType: 'st_tennis'),
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
  testWidgets('the schedule of a game lists its matches', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, AppRoutes.eventManageFor(101));
    await _tap(tester, EventManageTestIds.schedule);
    expect(_id(EventManageScheduleTestIds.match(301)), findsOneWidget);
    expect(_id(EventManageScheduleTestIds.match(302)), findsOneWidget);
    expect(find.textContaining('Alex Kim vs Pat Lee'), findsOneWidget);
    expect(find.textContaining('Court 1'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a match starts from its own time, court and notes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final actions = await _open(
      tester,
      AppRoutes.eventManageScheduleMatchFor(101, 301),
    );
    expect(find.text('Central Courts'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(_field(CreateEventWhenWhereTestIds.notes))
          .controller!
          .text,
      'Bring balls',
    );
    await tester.enterText(
      _field(CreateEventWhenWhereTestIds.notes),
      'Indoors please',
    );
    await tester.pump();
    await _tap(tester, CreateEventWhenWhereTestIds.next);

    final call = actions.manageCalls.single;
    expect(call.name, 'rescheduleMatches:101');
    expect(call.data, {
      'event': {
        'event_matches_attributes': [
          {
            'id': 301,
            // The match's own option (04 Nov 22:00Z), 17:00 at the venue.
            'request_schedule_options': [
              {
                'place_id': 5,
                'start_time': '2030-11-04T17:00Z',
                'duration': 90,
              },
            ],
            'place_court_id': 11,
            'notes_for_match': 'Indoors please',
          },
        ],
      },
    });
    expect(find.text('Changes saved.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a match without its own time starts from the event time', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final actions = await _open(
      tester,
      AppRoutes.eventManageScheduleMatchFor(101, 302),
    );
    await _tap(tester, CreateEventWhenWhereTestIds.next);
    final match =
        ((actions.manageCalls.single.data! as Map<String, dynamic>)['event']
                as Map<String, dynamic>)['event_matches_attributes']
            as List;
    final sent = match.single as Map<String, dynamic>;
    expect(sent['id'], 302);
    expect((sent['request_schedule_options'] as List).single, {
      'place_id': 5,
      'start_time': '2030-11-03T18:00Z',
      'duration': 90,
    });
    expect(sent.containsKey('place_court_id'), isFalse); // none booked
    handle.dispose();
  });

  testWidgets('a rejected reschedule shows the server message', (tester) async {
    final handle = tester.ensureSemantics();
    final actions = await _open(
      tester,
      AppRoutes.eventManageScheduleMatchFor(101, 301),
      failure: const ServerFailure(422, 'Court 1 is taken then'),
    );
    await _tap(tester, CreateEventWhenWhereTestIds.next);
    expect(actions.manageCalls, hasLength(1));
    expect(find.text('Court 1 is taken then'), findsOneWidget);
    expect(_id(CreateEventWhenWhereTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a match the event does not have cannot be moved', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final actions = await _open(
      tester,
      AppRoutes.eventManageScheduleMatchFor(101, 999),
    );
    expect(
      find.text(
        'Changing the time of this event is not available in this build yet.',
      ),
      findsOneWidget,
    );
    expect(actions.manageCalls, isEmpty);
    handle.dispose();
  });

  testWidgets('a malformed match id goes back to the list', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, '/event/101/manage/schedule/abc');
    expect(_id(EventManageScheduleTestIds.matches), findsOneWidget);
    handle.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets(
      'the match list meets guidelines (${dark ? 'dark' : 'light'})',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await _open(tester, AppRoutes.eventManageScheduleFor(101));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      },
    );
  }
}
