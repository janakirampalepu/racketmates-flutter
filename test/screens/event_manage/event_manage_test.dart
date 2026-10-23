import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/create_event_when_where/create_event_when_where_test_ids.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/event_manage/event_manage_test_ids.dart';
import 'package:racketmates/screens/event_manage_schedule/event_manage_schedule_test_ids.dart';
import 'package:racketmates/screens/event_manage_add_people/event_manage_add_people_test_ids.dart';
import 'package:racketmates/screens/event_manage_players/event_manage_players_test_ids.dart';
import 'package:racketmates/screens/event_manage_score_entry/event_manage_score_entry_test_ids.dart';
import 'package:racketmates/screens/event_manage_scores/event_manage_scores_test_ids.dart';
import 'package:racketmates/screens/event_manage_settings/event_manage_settings_test_ids.dart';
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

class _Open {
  _Open(this.schedule, this.actions, this.create);

  final FakeScheduleRepository schedule;
  final FakeEventActionsRepository actions;
  final FakeCreateEventRepository create;
}

/// Opens event 101 from [fixture] like a deep link, then goes to [route].
Future<_Open> _open(
  WidgetTester tester,
  String fixture, {
  String? route,
  AppFailure? failure,
  List<AppUser> people = const [],
  void Function(Map<String, dynamic> event)? edit,
}) async {
  useTallScreen(tester);
  final json = apiFixture(fixture);
  if (edit != null) edit(json['event'] as Map<String, dynamic>);
  final schedule = FakeScheduleRepository(
    event: EventDetailsResponse.fromJson(json).event,
  );
  final actions = FakeEventActionsRepository(failure: failure);
  final create = FakeCreateEventRepository(players: people);
  await tester.pumpWidget(
    signedInApp(
      schedule: schedule,
      actions: actions,
      createEvent: create,
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
  unawaited(GoRouter.of(context).push(route ?? AppRoutes.eventFor(101)));
  await tester.pumpAndSettle();
  return _Open(schedule, actions, create);
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

int _eventLoads(_Open o) =>
    o.schedule.calls.where((c) => c == 'event-101').length;

void main() {
  group('entry', () {
    testWidgets('a manager reaches the hub from the event menu', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'events_show_manage_practice');
      await _tap(tester, EventDetailsTestIds.menu);
      expect(_id(EventDetailsTestIds.menuManageEvent), findsOneWidget);
      await tester.tap(_id(EventDetailsTestIds.menuManageEvent));
      await tester.pumpAndSettle();

      expect(_id(EventManageTestIds.root), findsOneWidget);
      expect(_id(EventManageTestIds.settings), findsOneWidget);
      expect(_id(EventManageTestIds.players), findsOneWidget);
      expect(_id(EventManageTestIds.schedule), findsOneWidget);
      expect(_id(EventManageTestIds.scores), findsNothing); // no matches
      handle.dispose();
    });

    testWidgets('someone who cannot manage has no manage entry', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'events_show_invited');
      expect(_id(EventDetailsTestIds.menu), findsNothing);
      handle.dispose();
    });

    testWidgets('a game offers scores and moves its matches one by one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageFor(101),
      );
      expect(_id(EventManageTestIds.scores), findsOneWidget);
      expect(
        find.text(
          'Changing the time of this event is not available in this build yet.',
        ),
        findsNothing,
      );
      await tester.tap(_id(EventManageTestIds.schedule));
      await tester.pumpAndSettle();
      expect(_id(EventManageScheduleTestIds.matches), findsOneWidget);
      handle.dispose();
    });
  });

  group('settings', () {
    testWidgets('change the deadline, limits and switch, then save', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_practice',
        route: AppRoutes.eventManageSettingsFor(101),
      );
      await _tap(tester, EventManageSettingsTestIds.unitDays);
      await _tap(
        tester,
        '${EventManageSettingsTestIds.deadlinePrefix}_increase',
      );
      await _tap(tester, EventManageSettingsTestIds.allowManage);
      await _tap(tester, '${EventManageSettingsTestIds.rsvpPrefix}_increase');
      await _tap(tester, EventManageSettingsTestIds.pickManually);
      final loadsBefore = _eventLoads(o);
      await _tap(tester, EventManageSettingsTestIds.save);

      final call = o.actions.manageCalls.single;
      expect(call.name, 'updateSettings:101');
      expect(call.data, {
        'event': {
          'attendance_deadline_unit': 2,
          'attendance_deadline_unit_type': 'adut_day',
          'allow_participants_manage_players': true,
          'players_limit': 4,
          'rsvp_limit': 7,
          'player_acceptance_type': 'pat_pick_manually',
        },
      });
      // The event is reloaded and the screen closes with a confirmation.
      expect(_eventLoads(o), greaterThan(loadsBefore));
      expect(_id(EventManageSettingsTestIds.root), findsNothing);
      expect(find.text('Changes saved.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a rejected change shows the server message and stays', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_practice',
        route: AppRoutes.eventManageSettingsFor(101),
        failure: const ServerFailure(422, 'Players limit is too low'),
      );
      await _tap(tester, EventManageSettingsTestIds.save);
      expect(o.actions.manageCalls, hasLength(1));
      expect(_id(EventManageSettingsTestIds.error), findsOneWidget);
      expect(find.text('Players limit is too low'), findsOneWidget);
      expect(_id(EventManageSettingsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a game edits the scoring format and results switch', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageSettingsFor(101),
      );
      expect(o.create.scoringRequests.single, (
        sport: 'st_tennis',
        eventType: 'et_competitive',
      ));
      await _tap(tester, EventManageSettingsTestIds.allowLogResults);
      await _tap(
        tester,
        '${EventManageSettingsTestIds.scoringPrefix}_scoring_format_sf_single_set',
      );
      await _tap(
        tester,
        '${EventManageSettingsTestIds.scoringPrefix}_score_increase',
      );
      await _tap(tester, EventManageSettingsTestIds.save);

      final event = (o.actions.manageCalls.single.data as Map)['event'] as Map;
      expect(event['allow_participants_to_log_results'], isTrue);
      expect(event['scoring_format'], 'sf_single_set');
      expect(event['minimum_score_to_win'], 7); // default 6, one step up
      expect(event['deciding_set_type'], 'dst_decide_later');
      handle.dispose();
    });

    testWidgets('a played event is read only', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final json = apiFixture('events_show_manage_practice');
      (json['event'] as Map<String, dynamic>)['settings_locked'] = true;
      final schedule = FakeScheduleRepository(
        event: EventDetailsResponse.fromJson(json).event,
      );
      await tester.pumpWidget(signedInApp(schedule: schedule));
      await tester.pumpAndSettle();
      unawaited(
        GoRouter.of(tester.element(_id(HomeTestIds.root)))
            .push(AppRoutes.eventManageSettingsFor(101)),
      );
      await tester.pumpAndSettle();
      expect(_id(EventManageSettingsTestIds.locked), findsOneWidget);
      expect(_id(EventManageSettingsTestIds.save), findsNothing);
      handle.dispose();
    });
  });

  group('people', () {
    testWidgets('grouped by response, the organizer cannot be removed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        'events_show_manage_practice',
        route: AppRoutes.eventManagePlayersFor(101),
      );
      expect(find.text('Coaches (1)'), findsOneWidget);
      expect(find.text('Confirmed (1)'), findsOneWidget);
      expect(find.text('To be confirmed (1)'), findsOneWidget);
      expect(find.text('Invited (1)'), findsOneWidget);
      expect(find.text('Declined (1)'), findsOneWidget);
      expect(find.text('Alex Kim'), findsOneWidget);

      final organizer = tester.widget<CheckboxListTile>(
        find.descendant(
          of: _id(EventManagePlayersTestIds.participant(7)),
          matching: find.byType(CheckboxListTile),
        ),
      );
      expect(organizer.onChanged, isNull);
      expect(_id(EventManagePlayersTestIds.remove), findsNothing);
      handle.dispose();
    });

    testWidgets('confirm a person who asked to join', (tester) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_practice',
        route: AppRoutes.eventManagePlayersFor(101),
      );
      // Someone who only has an invitation cannot be confirmed here.
      await _tap(tester, EventManagePlayersTestIds.participant(9));
      expect(_id(EventManagePlayersTestIds.confirm), findsNothing);
      await _tap(tester, EventManagePlayersTestIds.participant(9));
      await _tap(tester, EventManagePlayersTestIds.participant(8));
      await _tap(tester, EventManagePlayersTestIds.confirm);

      expect(o.actions.manageCalls.single.name, 'pickPlayers:101');
      expect(o.actions.manageCalls.single.data, [8]);
      expect(_id(EventManagePlayersTestIds.remove), findsNothing); // cleared
      handle.dispose();
    });

    testWidgets('remove people after confirming', (tester) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_practice',
        route: AppRoutes.eventManagePlayersFor(101),
      );
      await _tap(tester, EventManagePlayersTestIds.participant(9));
      await _tap(tester, EventManagePlayersTestIds.participant(10));
      await _tap(tester, EventManagePlayersTestIds.remove);
      // Dismissing the dialog sends nothing.
      await _tap(tester, EventManagePlayersTestIds.dialogDismiss);
      expect(o.actions.manageCalls, isEmpty);
      await _tap(tester, EventManagePlayersTestIds.remove);
      await _tap(tester, EventManagePlayersTestIds.dialogConfirm);

      expect(o.actions.manageCalls.single.name, 'removeParticipants:101');
      expect(o.actions.manageCalls.single.data, [9, 10]);
      handle.dispose();
    });

    testWidgets('add players: only people not in the event are offered', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_practice',
        route: AppRoutes.eventManagePlayersFor(101),
        people: const [
          AppUser(id: 8, firstName: 'Alex', lastName: 'Kim'), // already in
          AppUser(id: 12, firstName: 'Sam', lastName: 'Fox'),
          AppUser(id: 13, firstName: 'Kai', lastName: 'Orr'),
        ],
      );
      await _tap(tester, EventManagePlayersTestIds.addPlayers);
      expect(o.create.searches.first.role, 'ur_player');
      expect(o.create.searches.first.sport, 'st_tennis');
      expect(_id(EventManageAddPeopleTestIds.person(8)), findsNothing);
      await _tap(tester, EventManageAddPeopleTestIds.person(12));
      await _tap(tester, EventManageAddPeopleTestIds.person(13));
      await _tap(tester, EventManageAddPeopleTestIds.add);

      expect(
        o.actions.manageCalls.single.name,
        'addParticipants:101:ur_player',
      );
      expect(o.actions.manageCalls.single.data, [12, 13]);
      expect(_id(EventManagePlayersTestIds.root), findsOneWidget); // back
      handle.dispose();
    });

    testWidgets('add coaches searches coaches', (tester) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_practice',
        route: AppRoutes.eventManagePlayersFor(101),
        people: const [AppUser(id: 12, firstName: 'Sam', lastName: 'Fox')],
      );
      await _tap(tester, EventManagePlayersTestIds.addCoaches);
      expect(o.create.searches.first.role, 'ur_coach');
      await _tap(tester, EventManageAddPeopleTestIds.person(12));
      await _tap(tester, EventManageAddPeopleTestIds.add);
      expect(o.actions.manageCalls.single.name, 'addParticipants:101:ur_coach');
      handle.dispose();
    });

    testWidgets('nothing to add and nothing chosen', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        'events_show_manage_practice',
        route: AppRoutes.eventManageAddPeopleFor(101, coaches: false),
      );
      expect(_id(EventManageAddPeopleTestIds.empty), findsOneWidget);
      final add = tester.widget<FilledButton>(
        find.descendant(
          of: _id(EventManageAddPeopleTestIds.add),
          matching: find.byType(FilledButton),
        ),
      );
      expect(add.onPressed, isNull);
      handle.dispose();
    });
  });

  group('schedule', () {
    testWidgets('starts from the current time and venue and saves them', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_practice',
        route: AppRoutes.eventManageScheduleFor(101),
      );
      expect(find.text('Central Courts'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      // The courts of the venue were loaded and the booked one is ticked.
      expect(_id(CreateEventWhenWhereTestIds.court(11)), findsOneWidget);
      expect(_id(CreateEventWhenWhereTestIds.court(12)), findsOneWidget);

      await tester.enterText(
        _field(CreateEventWhenWhereTestIds.notes),
        'Moved indoors',
      );
      await tester.pump();
      await _tap(tester, CreateEventWhenWhereTestIds.next);

      final call = o.actions.manageCalls.single;
      expect(call.name, 'reschedule:101');
      expect(call.data, {
        'event': {
          'event_schedule_options_attributes': [
            {
              'place_id': 5,
              'start_time': '2030-11-03T18:00Z',
              'duration': 90,
              'timezone_info_id': 14,
            },
          ],
          'event_venue_courts_attributes': [
            {'place_court_id': 11, 'order': 1},
          ],
          'notes_for_event': 'Moved indoors',
        },
      });
      expect(find.text('Changes saved.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a rejected reschedule shows the server message', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_practice',
        route: AppRoutes.eventManageScheduleFor(101),
        failure: const ServerFailure(422, 'The venue is closed then'),
      );
      await _tap(tester, CreateEventWhenWhereTestIds.next);
      expect(o.actions.manageCalls, hasLength(1));
      expect(find.text('The venue is closed then'), findsOneWidget);
      expect(_id(CreateEventWhenWhereTestIds.root), findsOneWidget);
      handle.dispose();
    });
  });

  group('scores', () {
    testWidgets('the matches show their results', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageScoresFor(101),
      );
      expect(find.textContaining('Alex Kim vs Pat Lee'), findsOneWidget);
      expect(find.textContaining('6-4, 7-6'), findsOneWidget);
      expect(find.textContaining('No score yet'), findsOneWidget);
      expect(find.text('Unfinished'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('add the third set; the tie-break scores stay', (tester) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageScoreFor(101, 301),
      );
      // Sets 1 and 2 are prefilled.
      expect(
        tester
            .widget<TextField>(_field(EventManageScoreEntryTestIds.top(1)))
            .controller
            ?.text,
        '6',
      );
      expect(find.text('Sets won: 2 – 0'), findsOneWidget);

      await tester.enterText(_field(EventManageScoreEntryTestIds.top(3)), '2');
      await tester.pump();
      // One side only: an incomplete set.
      await _tap(tester, EventManageScoreEntryTestIds.save);
      expect(find.text('Enter both scores of a set.'), findsOneWidget);
      expect(o.actions.manageCalls, isEmpty);

      await tester.enterText(
        _field(EventManageScoreEntryTestIds.bottom(3)),
        '6',
      );
      await tester.pump();
      expect(find.text('Sets won: 2 – 1'), findsOneWidget);
      await _tap(tester, EventManageScoreEntryTestIds.save);

      final call = o.actions.manageCalls.single;
      expect(call.name, 'updateScores:101:301');
      final match =
          (call.data as Map<String, dynamic>)['event_match']
              as Map<String, dynamic>;
      expect(match['request_unfinished_match'], isFalse);
      final scores = (match['event_scores_attributes'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        scores
            .where((s) => s['set_tie_breaker'] == false)
            .map(
              (s) => '${s['event_match_side_id']}:${s['set']}:${s['score']}',
            ),
        ['401:1:6', '402:1:4', '401:2:7', '402:2:6', '401:3:2', '402:3:6'],
      );
      expect(scores.where((s) => s['set_tie_breaker'] == true), hasLength(2));
      expect(find.text('Changes saved.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a single-set match, empty, cannot be saved', (tester) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageScoreFor(101, 302),
      );
      expect(find.text('Score'), findsOneWidget); // one row, not "Set 1"
      await _tap(tester, EventManageScoreEntryTestIds.save);
      expect(find.text('Enter a score.'), findsOneWidget);
      expect(o.actions.manageCalls, isEmpty);

      await tester.enterText(_field(EventManageScoreEntryTestIds.top(1)), '6');
      await tester.enterText(
        _field(EventManageScoreEntryTestIds.bottom(1)),
        '3',
      );
      await tester.pump();
      await _tap(tester, EventManageScoreEntryTestIds.save);
      expect(o.actions.manageCalls.single.name, 'updateScores:101:302');
      // The match was marked unfinished and saving keeps it so.
      final match =
          (o.actions.manageCalls.single.data as Map)['event_match'] as Map;
      expect(match['request_unfinished_match'], isTrue);
      handle.dispose();
    });

    testWidgets('the unfinished status can be removed', (tester) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageScoreFor(101, 302),
      );
      await _tap(tester, EventManageScoreEntryTestIds.clearUnfinished);
      expect(o.actions.manageCalls.single.name, 'clearUnfinished:101:302');
      handle.dispose();
    });

    List<Map<String, dynamic>> sentScores(_Open o) =>
        (((o.actions.manageCalls.single.data!
                        as Map<String, dynamic>)['event_match']
                    as Map<String, dynamic>)['event_scores_attributes']
                as List)
            .cast<Map<String, dynamic>>();

    Future<void> type(WidgetTester tester, String id, String text) =>
        tester.enterText(_field(id), text);

    testWidgets('a stored set tie-break is shown and kept', (tester) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageScoreFor(101, 301),
      );
      expect(
        tester
            .widget<TextField>(
              _field(EventManageScoreEntryTestIds.tieBreakTop(2)),
            )
            .controller!
            .text,
        '7',
      );
      expect(
        tester
            .widget<TextField>(
              _field(EventManageScoreEntryTestIds.tieBreakBottom(2)),
            )
            .controller!
            .text,
        '5',
      );
      await _tap(tester, EventManageScoreEntryTestIds.save);
      expect(
        sentScores(o)
            .where((s) => s['set_tie_breaker'] == true)
            .map((s) => (s['event_match_side_id'], s['score'])),
        [(401, '7'), (402, '5')],
      );
      handle.dispose();
    });

    testWidgets('a level set asks for its tie-break', (tester) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageScoreFor(101, 301),
      );
      expect(_id(EventManageScoreEntryTestIds.tieBreakTop(3)), findsNothing);
      await type(tester, EventManageScoreEntryTestIds.top(3), '6');
      await type(tester, EventManageScoreEntryTestIds.bottom(3), '6');
      await tester.pump();
      expect(_id(EventManageScoreEntryTestIds.tieBreakTop(3)), findsOneWidget);

      await _tap(tester, EventManageScoreEntryTestIds.save);
      expect(o.actions.manageCalls, isEmpty);
      expect(find.text('Enter both scores of a set.'), findsOneWidget);

      await type(tester, EventManageScoreEntryTestIds.tieBreakTop(3), '7');
      await type(tester, EventManageScoreEntryTestIds.tieBreakBottom(3), '7');
      await tester.pump();
      await _tap(tester, EventManageScoreEntryTestIds.save);
      expect(o.actions.manageCalls, isEmpty);
      expect(find.text('A tie-break cannot end level.'), findsOneWidget);

      await type(tester, EventManageScoreEntryTestIds.tieBreakBottom(3), '5');
      await tester.pump();
      await _tap(tester, EventManageScoreEntryTestIds.save);
      expect(
        sentScores(o)
            .where((s) => s['set'] == '3' && s['set_tie_breaker'] == true)
            .map((s) => (s['event_match_side_id'], s['score'])),
        [(401, '7'), (402, '5')],
      );
      handle.dispose();
    });

    testWidgets('level sets offer a match tie-break for the last set', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageScoreFor(101, 301),
      );
      expect(_id(EventManageScoreEntryTestIds.decidingPrompt), findsNothing);
      // Second set 3-6: one set each.
      await type(tester, EventManageScoreEntryTestIds.top(2), '3');
      await type(tester, EventManageScoreEntryTestIds.bottom(2), '6');
      await tester.pump();
      expect(
        _id(EventManageScoreEntryTestIds.tieBreakTop(2)),
        findsNothing,
      ); // no longer the 7-6 it was
      expect(_id(EventManageScoreEntryTestIds.decidingPrompt), findsOneWidget);
      expect(_id(EventManageScoreEntryTestIds.top(3)), findsOneWidget);

      await _tap(
        tester,
        EventManageScoreEntryTestIds.deciding('dst_tie_break'),
      );
      expect(_id(EventManageScoreEntryTestIds.top(3)), findsNothing);
      expect(
        _id(EventManageScoreEntryTestIds.matchTieBreakTop),
        findsOneWidget,
      );
      expect(_id(EventManageScoreEntryTestIds.decidingPrompt), findsNothing);

      await _tap(tester, EventManageScoreEntryTestIds.save);
      expect(o.actions.manageCalls, isEmpty); // the tie-break is needed now

      await type(tester, EventManageScoreEntryTestIds.matchTieBreakTop, '10');
      await type(tester, EventManageScoreEntryTestIds.matchTieBreakBottom, '8');
      await tester.pump();
      expect(find.text('Sets won: 2 – 1'), findsOneWidget);
      await _tap(tester, EventManageScoreEntryTestIds.save);

      final match =
          (o.actions.manageCalls.single.data!
                  as Map<String, dynamic>)['event_match']
              as Map<String, dynamic>;
      expect(match['deciding_set_type'], 'dst_tie_break');
      final scores = sentScores(o);
      expect(
        scores
            .where((s) => s['match_tie_breaker'] == true)
            .map((s) => (s['event_match_side_id'], s['set'], s['score'])),
        [(401, '6', '10'), (402, '6', '8')],
      );
      // The old 7-5 tie-break of set 2 is cleared by its id.
      final cleared = scores.where((s) => s.containsKey('id'));
      expect(cleared.map((s) => s['score']), ['', '']);
      handle.dispose();
    });

    testWidgets('a regular last set needs no tie-break', (tester) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageScoreFor(101, 301),
      );
      await type(tester, EventManageScoreEntryTestIds.top(2), '3');
      await type(tester, EventManageScoreEntryTestIds.bottom(2), '6');
      await tester.pump();
      await _tap(
        tester,
        EventManageScoreEntryTestIds.deciding('dst_regular_set'),
      );
      expect(_id(EventManageScoreEntryTestIds.matchTieBreakTop), findsNothing);
      await type(tester, EventManageScoreEntryTestIds.top(3), '6');
      await type(tester, EventManageScoreEntryTestIds.bottom(3), '2');
      await tester.pump();
      await _tap(tester, EventManageScoreEntryTestIds.save);
      final match =
          (o.actions.manageCalls.single.data!
                  as Map<String, dynamic>)['event_match']
              as Map<String, dynamic>;
      expect(match['deciding_set_type'], 'dst_regular_set');
      handle.dispose();
    });

    testWidgets('a score the server rejects shows its message', (tester) async {
      final handle = tester.ensureSemantics();
      final o = await _open(
        tester,
        'events_show_manage_game',
        route: AppRoutes.eventManageScoreFor(101, 301),
        failure: const ServerFailure(422, 'Set 3 is not a valid score'),
      );
      await tester.enterText(_field(EventManageScoreEntryTestIds.top(3)), '9');
      await tester.enterText(
        _field(EventManageScoreEntryTestIds.bottom(3)),
        '8',
      );
      await tester.pump();
      await _tap(tester, EventManageScoreEntryTestIds.save);
      expect(o.actions.manageCalls, hasLength(1));
      expect(find.text('Set 3 is not a valid score'), findsOneWidget);
      expect(_id(EventManageScoreEntryTestIds.root), findsOneWidget);
      handle.dispose();
    });
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'manage screens meet contrast and tap-target guidelines ($mode)',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue =
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await _open(
          tester,
          'events_show_manage_game',
          route: AppRoutes.eventManageFor(101),
        );

        Future<void> check() async {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        }

        await check(); // hub
        await _tap(tester, EventManageTestIds.settings);
        await check(); // settings with scoring
        await tester.pageBack();
        await tester.pumpAndSettle();
        await _tap(tester, EventManageTestIds.players);
        await check(); // people
        await tester.pageBack();
        await tester.pumpAndSettle();
        await _tap(tester, EventManageTestIds.scores);
        await check(); // matches
        await _tap(tester, EventManageScoresTestIds.match(302));
        await _tap(tester, EventManageScoreEntryTestIds.save); // with an error
        await check(); // score entry
        handle.dispose();
      },
    );
  }
}
