import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/content/content_cache.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/create_event_coaches/create_event_coaches_test_ids.dart';
import 'package:racketmates/screens/create_event_invite_settings/create_event_invite_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_players/create_event_players_test_ids.dart';
import 'package:racketmates/screens/create_event_review/create_event_review_test_ids.dart';
import 'package:racketmates/screens/create_event_settings/create_event_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_sport/create_event_sport_test_ids.dart';
import 'package:racketmates/screens/create_event_success/create_event_success_test_ids.dart';
import 'package:racketmates/screens/create_event_type/create_event_type_test_ids.dart';
import 'package:racketmates/screens/create_event_when_where/create_event_when_where_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/place_picker/place_picker_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);
Finder _field(String id) =>
    find.descendant(of: _id(id), matching: find.byType(TextField));

InMemoryContentCache _content() => InMemoryContentCache()
  ..snapshot = ContentSnapshot(
    referenceData: [
      {
        'id': 1,
        'data_type': 'event_type',
        'key': 'et_practice_drill',
        'localized_label': 'Practice drill',
        'localized_sub_text': 'Work on skills',
      },
      {
        'id': 2,
        'data_type': 'event_type',
        'key': 'et_casual',
        'localized_label': 'Casual game',
      },
      {
        'id': 3,
        'data_type': 'event_type',
        'key': 'et_round_robin',
        'localized_label': 'Round robin',
      },
      {
        'id': 4,
        'data_type': 'event_type',
        'key': 'et_group_lesson',
        'localized_label': 'Group lesson',
      },
      {
        'id': 5,
        'data_type': 'event_type',
        'key': 'et_casual_meeting',
        'localized_label': 'Casual meetup',
      },
    ],
  );

const _alex = AppUser(id: 8, firstName: 'Alex', lastName: 'Kim');
const _pat = AppUser(id: 9, firstName: 'Pat', lastName: 'Lee');
const _courtsAt = PlaceItem(
  id: 5,
  name: 'Central Courts',
  address: '1 Main St',
  addressDetail: PlaceAddress(latitude: 40.7, longitude: -74),
);

class _Wizard {
  _Wizard()
    : places = FakePlacesRepository(
        places: [_courtsAt],
        detailsById: {
          5: _courtsAt.copyWith(
            placeCourts: const [
              PlaceCourt(id: 11, name: 'Court 1', sportType: 'st_tennis'),
              PlaceCourt(id: 12, name: 'Court 2', sportType: 'st_tennis'),
              PlaceCourt(
                id: 13,
                name: 'Pickleball 1',
                sportType: 'st_pickleball',
              ),
            ],
          ),
        },
      ),
      create = FakeCreateEventRepository(players: [_alex, _pat]);

  final FakePlacesRepository places;
  final FakeCreateEventRepository create;

  Widget app({FakeScheduleRepository? schedule}) => signedInApp(
    schedule: schedule,
    places: places,
    createEvent: create,
    contentCache: _content(),
  );
}

Future<void> _openWizard(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(MainShellTestIds.navSchedule));
  await tester.pumpAndSettle();
  await tester.tap(_id(ScheduleTestIds.createEvent));
  await tester.pumpAndSettle();
  expect(_id(CreateEventTypeTestIds.root), findsOneWidget);
}

Future<void> _throughSport(WidgetTester tester) async {
  await tester.tap(_id(CreateEventTypeTestIds.type('et_practice_drill')));
  await tester.pumpAndSettle();
  await tester.tap(_id(CreateEventSportTestIds.sport('st_tennis')));
  await tester.pumpAndSettle();
  await tester.tap(_id(CreateEventSportTestIds.next));
  await tester.pumpAndSettle();
}

Future<void> _throughSettings(WidgetTester tester) async {
  await tester.tap(_id(CreateEventSettingsTestIds.next));
  await tester.pumpAndSettle();
}

Future<void> _throughPlayers(WidgetTester tester) async {
  await tester.tap(_id(CreateEventPlayersTestIds.player(8)));
  await tester.pumpAndSettle();
  await tester.tap(_id(CreateEventPlayersTestIds.next));
  await tester.pumpAndSettle();
}

Future<void> _throughWhenWhere(WidgetTester tester) async {
  await tester.tap(_id(CreateEventWhenWhereTestIds.venueButton));
  await tester.pumpAndSettle();
  await tester.tap(_id(PlacePickerTestIds.place(5)));
  await tester.pumpAndSettle();
  await tester.tap(_id(CreateEventWhenWhereTestIds.dateButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(_id(CreateEventWhenWhereTestIds.timeButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(_id(CreateEventWhenWhereTestIds.next));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'type step lists reference data in order and only enables supported types',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_Wizard().app());
      await _openWizard(tester);

      expect(find.text('Practice drill'), findsOneWidget);
      expect(find.text('Work on skills'), findsOneWidget);
      expect(find.text('Casual game'), findsOneWidget);
      expect(find.text('Not available in this build yet.'), findsNWidgets(2));
      // Unsupported types do nothing when tapped.
      await tester.tap(_id(CreateEventTypeTestIds.type('et_casual')));
      await tester.pumpAndSettle();
      expect(_id(CreateEventTypeTestIds.root), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('without reference data the supported type is still offered', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(signedInApp());
    await _openWizard(tester);
    expect(
      find.text('Practice Drill'),
      findsOneWidget,
    ); // humanized key fallback
    handle.dispose();
  });

  testWidgets('sport step needs a choice before continuing', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_Wizard().app());
    await _openWizard(tester);
    await tester.tap(_id(CreateEventTypeTestIds.type('et_practice_drill')));
    await tester.pumpAndSettle();
    FilledButton next() => tester.widget<FilledButton>(
      find.descendant(
        of: _id(CreateEventSportTestIds.next),
        matching: find.byType(FilledButton),
      ),
    );
    expect(next().onPressed, isNull);
    await tester.tap(_id(CreateEventSportTestIds.sport('st_padel')));
    await tester.pumpAndSettle();
    expect(next().onPressed, isNotNull);
    handle.dispose();
  });

  testWidgets('settings: deadline unit and value follow the native limits', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester);
    await _throughSport(tester);
    expect(find.textContaining('1 Hours'), findsOneWidget);

    await tester.tap(_id(CreateEventSettingsTestIds.unitDays));
    await tester.pumpAndSettle();
    for (var i = 0; i < 9; i++) {
      await tester.tap(_id('create_event_deadline_increase'));
      await tester.pump();
    }
    expect(find.textContaining('7 Days'), findsOneWidget); // capped at 7
    handle.dispose();
  });

  testWidgets(
    'players step requires at least one invitee and searches by sport',
    (tester) async {
      final handle = tester.ensureSemantics();
      final w = _Wizard();
      await tester.pumpWidget(w.app());
      await _openWizard(tester);
      await _throughSport(tester);
      await _throughSettings(tester);

      await tester.tap(_id(CreateEventPlayersTestIds.next));
      await tester.pumpAndSettle();
      expect(_id(CreateEventPlayersTestIds.error), findsOneWidget);
      expect(w.create.searches.first.sport, 'st_tennis');

      await tester.enterText(_field(CreateEventPlayersTestIds.search), 'pat');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(_id(CreateEventPlayersTestIds.player(8)), findsNothing);
      await tester.tap(_id(CreateEventPlayersTestIds.player(9)));
      await tester.pumpAndSettle();
      expect(_id(CreateEventPlayersTestIds.selected), findsOneWidget);
      await tester.tap(_id(CreateEventPlayersTestIds.next));
      await tester.pumpAndSettle();
      expect(_id(CreateEventWhenWhereTestIds.root), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    'when/where: validation, venue courts loaded by id, sport-filtered courts',
    (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final w = _Wizard();
      await tester.pumpWidget(w.app());
      await _openWizard(tester);
      await _throughSport(tester);
      await _throughSettings(tester);
      await _throughPlayers(tester);

      await tester.tap(_id(CreateEventWhenWhereTestIds.next));
      await tester.pumpAndSettle();
      expect(_id(CreateEventWhenWhereTestIds.venueError), findsOneWidget);
      expect(_id(CreateEventWhenWhereTestIds.startError), findsOneWidget);
      expect(_id(CreateEventWhenWhereTestIds.root), findsOneWidget);

      await tester.tap(_id(CreateEventWhenWhereTestIds.venueButton));
      await tester.pumpAndSettle();
      expect(w.places.searches.last.sport, 'st_tennis');
      await tester.tap(_id(PlacePickerTestIds.place(5)));
      await tester.pumpAndSettle();
      expect(w.places.detailsCalls, [5]);
      expect(find.text('Central Courts'), findsOneWidget);
      expect(_id(CreateEventWhenWhereTestIds.court(11)), findsOneWidget);
      expect(_id(CreateEventWhenWhereTestIds.court(12)), findsOneWidget);
      expect(
        _id(CreateEventWhenWhereTestIds.court(13)),
        findsNothing,
      ); // other sport
      handle.dispose();
    },
  );

  testWidgets(
    'invite settings keep the RSVP limit at or above the player limit',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_Wizard().app());
      await _openWizard(tester);
      await _throughSport(tester);
      await _throughSettings(tester);
      await _throughPlayers(tester);
      await _throughWhenWhere(tester);
      expect(_id(CreateEventInviteSettingsTestIds.root), findsOneWidget);

      String value(String prefix) => tester
          .widget<Text>(
            find.descendant(
              of: _id('${prefix}_value'),
              matching: find.byType(Text),
            ),
          )
          .data!;
      await tester.tap(
        _id('${CreateEventInviteSettingsTestIds.playersPrefix}_increase'),
      );
      await tester.pump();
      await tester.tap(
        _id('${CreateEventInviteSettingsTestIds.playersPrefix}_increase'),
      );
      await tester.pump();
      expect(value(CreateEventInviteSettingsTestIds.playersPrefix), '3');
      expect(value(CreateEventInviteSettingsTestIds.rsvpPrefix), '3');

      await tester.tap(
        _id('${CreateEventInviteSettingsTestIds.rsvpPrefix}_decrease'),
      );
      await tester.pump();
      expect(
        value(CreateEventInviteSettingsTestIds.rsvpPrefix),
        '3',
      ); // not below players
      handle.dispose();
    },
  );

  testWidgets('full journey creates the event with the expected request', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester);
    await _throughSport(tester);

    await tester.tap(_id(CreateEventSettingsTestIds.unitDays));
    await tester.pumpAndSettle();
    await tester.tap(_id('create_event_deadline_increase'));
    await tester.tap(_id(CreateEventSettingsTestIds.allowManage));
    await tester.pump();
    await _throughSettings(tester);
    await _throughPlayers(tester);

    // venue + one court + default date/time + 90 min + notes
    await tester.tap(_id(CreateEventWhenWhereTestIds.venueButton));
    await tester.pumpAndSettle();
    await tester.tap(_id(PlacePickerTestIds.place(5)));
    await tester.pumpAndSettle();
    await tester.tap(_id(CreateEventWhenWhereTestIds.court(12)));
    await tester.pump();
    await tester.tap(_id(CreateEventWhenWhereTestIds.dateButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(_id(CreateEventWhenWhereTestIds.timeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(_id(CreateEventWhenWhereTestIds.duration));
    await tester.pumpAndSettle();
    await tester.tap(find.text('90 min').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      _field(CreateEventWhenWhereTestIds.notes),
      'Bring balls',
    );
    await tester.tap(_id(CreateEventWhenWhereTestIds.next));
    await tester.pumpAndSettle();

    await tester.tap(
      _id('${CreateEventInviteSettingsTestIds.playersPrefix}_increase'),
    );
    await tester.tap(_id(CreateEventInviteSettingsTestIds.pickManually));
    await tester.pump();
    await tester.tap(_id(CreateEventInviteSettingsTestIds.next));
    await tester.pumpAndSettle();

    // Review summarizes the choices.
    expect(_id(CreateEventReviewTestIds.root), findsOneWidget);
    expect(find.text('Practice drill'), findsOneWidget);
    expect(find.text('Tennis'), findsOneWidget);
    expect(find.text('Central Courts'), findsOneWidget);
    expect(find.text('Alex Kim'), findsOneWidget);

    await tester.tap(_id(CreateEventReviewTestIds.create));
    await tester.pumpAndSettle();
    expect(_id(CreateEventSuccessTestIds.root), findsOneWidget);

    final event = w.create.body!['event'] as Map<String, dynamic>;
    expect(event['event_type'], 'et_practice_drill');
    expect(event['sport_type'], 'st_tennis');
    expect(event['originator_type'], '');
    expect(event['allow_participants_manage_players'], isTrue);
    expect(event['attendance_deadline_unit_type'], 'adut_day');
    expect(event['attendance_deadline_unit'], 2);
    expect(event['players_limit'], 2);
    expect(event['rsvp_limit'], 2);
    expect(event['player_acceptance_type'], 'pat_pick_manually');
    expect(event['notes_for_event'], 'Bring balls');
    expect(
      (event['event_participants_attributes'] as List).single['user_id'],
      8,
    );
    expect(event['event_venue_courts_attributes'], [
      {'place_court_id': 12, 'order': 1},
    ]);
    final option =
        (event['event_schedule_options_attributes'] as List).single
            as Map<String, dynamic>;
    expect(option['place_id'], 5);
    expect(option['duration'], 90);
    expect(option['timezone_info_id'], 99);
    expect(
      option['start_time'],
      matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}Z$')),
    );

    // Success: back to the schedule with the wizard cleared.
    await tester.tap(_id(CreateEventSuccessTestIds.goToSchedule));
    await tester.pumpAndSettle();
    expect(_id(ScheduleTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('success can open the created event', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    final schedule = FakeScheduleRepository(
      event: const EventDetails(id: 321, eventType: 'et_practice_drill'),
    );
    await tester.pumpWidget(w.app(schedule: schedule));
    await _openWizard(tester);
    await _throughSport(tester);
    await _throughSettings(tester);
    await _throughPlayers(tester);
    await _throughWhenWhere(tester);
    await tester.tap(_id(CreateEventInviteSettingsTestIds.next));
    await tester.pumpAndSettle();
    await tester.tap(_id(CreateEventReviewTestIds.create));
    await tester.pumpAndSettle();

    await tester.tap(_id(CreateEventSuccessTestIds.seeDetails));
    await tester.pumpAndSettle();
    expect(_id(EventDetailsTestIds.root), findsOneWidget);
    expect(schedule.calls, contains('event-321'));
    handle.dispose();
  });

  testWidgets('a rejected create shows the server message and can be retried', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard()
      ..create.createFailure = const ServerFailure(
        422,
        'Start time must be in the future',
      );
    await tester.pumpWidget(w.app());
    await _openWizard(tester);
    await _throughSport(tester);
    await _throughSettings(tester);
    await _throughPlayers(tester);
    await _throughWhenWhere(tester);
    await tester.tap(_id(CreateEventInviteSettingsTestIds.next));
    await tester.pumpAndSettle();

    await tester.tap(_id(CreateEventReviewTestIds.create));
    await tester.pumpAndSettle();
    expect(find.text('Start time must be in the future'), findsOneWidget);
    expect(_id(CreateEventReviewTestIds.root), findsOneWidget);

    w.create.createFailure = null;
    await tester.tap(_id(CreateEventReviewTestIds.create));
    await tester.pumpAndSettle();
    expect(_id(CreateEventSuccessTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'closing the wizard clears it; opening a step without a draft returns to the schedule',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_Wizard().app());
      await _openWizard(tester);
      await tester.tap(_id(CreateEventTypeTestIds.close));
      await tester.pumpAndSettle();
      expect(_id(ScheduleTestIds.root), findsOneWidget);

      final context = tester.element(_id(ScheduleTestIds.root));
      GoRouter.of(context).go(AppRoutes.createEventReview);
      await tester.pumpAndSettle();
      expect(_id(ScheduleTestIds.root), findsOneWidget);
      expect(_id(CreateEventReviewTestIds.root), findsNothing);
      handle.dispose();
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'wizard steps meet contrast and tap-target guidelines ($mode)',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue =
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        useTallScreen(tester);
        await tester.pumpWidget(_Wizard().app());
        await _openWizard(tester);

        Future<void> check() async {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        }

        await check(); // type
        await tester.tap(_id(CreateEventTypeTestIds.type('et_practice_drill')));
        await tester.pumpAndSettle();
        await check(); // sport
        await tester.tap(_id(CreateEventSportTestIds.sport('st_tennis')));
        await tester.pumpAndSettle();
        await tester.tap(_id(CreateEventSportTestIds.next));
        await tester.pumpAndSettle();
        await check(); // settings
        await _throughSettings(tester);
        await check(); // players
        await _throughPlayers(tester);
        await check(); // when/where
        await _throughWhenWhere(tester);
        await check(); // invite settings
        await tester.tap(_id(CreateEventInviteSettingsTestIds.next));
        await tester.pumpAndSettle();
        await check(); // review
        handle.dispose();
      },
    );
  }

  testWidgets(
    'group lesson asks for coaches first and searches by coach role',
    (tester) async {
      final handle = tester.ensureSemantics();
      final w = _Wizard();
      await tester.pumpWidget(w.app());
      await _openWizard(tester);
      await tester.tap(_id(CreateEventTypeTestIds.type('et_group_lesson')));
      await tester.pumpAndSettle();
      await tester.tap(_id(CreateEventSportTestIds.sport('st_tennis')));
      await tester.pumpAndSettle();
      await tester.tap(_id(CreateEventSportTestIds.next));
      await tester.pumpAndSettle();
      await _throughSettings(tester);

      expect(_id(CreateEventCoachesTestIds.root), findsOneWidget);
      expect(w.create.searches.first.role, 'ur_coach');
      await tester.tap(_id(CreateEventCoachesTestIds.next));
      await tester.pumpAndSettle();
      expect(_id(CreateEventCoachesTestIds.error), findsOneWidget);
      expect(_id(CreateEventCoachesTestIds.root), findsOneWidget);

      await tester.tap(_id(CreateEventCoachesTestIds.coach(8)));
      await tester.pumpAndSettle();
      await tester.tap(_id(CreateEventCoachesTestIds.next));
      await tester.pumpAndSettle();
      expect(_id(CreateEventPlayersTestIds.root), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('casual meetup skips the sport step and shows no courts', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester);
    await tester.tap(_id(CreateEventTypeTestIds.type('et_casual_meeting')));
    await tester.pumpAndSettle();
    expect(_id(CreateEventSportTestIds.root), findsNothing);
    expect(_id(CreateEventSettingsTestIds.next), findsOneWidget);
    await _throughSettings(tester);

    expect(find.text('Who is coming?'), findsWidgets);
    expect(w.create.searches.first.role, isNull);
    expect(w.create.searches.first.sport, isNull);
    await _throughPlayers(tester);

    await tester.tap(_id(CreateEventWhenWhereTestIds.venueButton));
    await tester.pumpAndSettle();
    expect(w.places.searches.last.sport, isNull);
    await tester.tap(_id(PlacePickerTestIds.place(5)));
    await tester.pumpAndSettle();
    expect(_id(CreateEventWhenWhereTestIds.court(11)), findsNothing);
    expect(
      _id('${CreateEventWhenWhereTestIds.courtCountPrefix}_increase'),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('court count stepper caps the selectable courts', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester);
    await _throughSport(tester);
    await _throughSettings(tester);
    await _throughPlayers(tester);
    await tester.tap(_id(CreateEventWhenWhereTestIds.venueButton));
    await tester.pumpAndSettle();
    await tester.tap(_id(PlacePickerTestIds.place(5)));
    await tester.pumpAndSettle();

    List<int> courts() => ProviderScope.containerOf(
      tester.element(_id(CreateEventWhenWhereTestIds.root)),
    ).read(createEventFlowProvider)!.courtIds;
    await tester.tap(_id(CreateEventWhenWhereTestIds.court(11)));
    await tester.pump();
    await tester.tap(_id(CreateEventWhenWhereTestIds.court(12))); // over cap
    await tester.pump();
    expect(courts(), [11]);

    await tester.tap(
      _id('${CreateEventWhenWhereTestIds.courtCountPrefix}_increase'),
    );
    await tester.pump();
    await tester.tap(_id(CreateEventWhenWhereTestIds.court(12)));
    await tester.pump();
    expect(courts(), [11, 12]);
    handle.dispose();
  });
}
