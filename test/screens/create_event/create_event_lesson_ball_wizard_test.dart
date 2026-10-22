import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/content/content_cache.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/create_event_assign_type/create_event_assign_type_test_ids.dart';
import 'package:racketmates/screens/create_event_coaches/create_event_coaches_test_ids.dart';
import 'package:racketmates/screens/create_event_invite_settings/create_event_invite_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_players/create_event_players_test_ids.dart';
import 'package:racketmates/screens/create_event_review/create_event_review_test_ids.dart';
import 'package:racketmates/screens/create_event_settings/create_event_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_sport/create_event_sport_test_ids.dart';
import 'package:racketmates/screens/create_event_success/create_event_success_test_ids.dart';
import 'package:racketmates/screens/create_event_team_choice/create_event_team_choice_test_ids.dart';
import 'package:racketmates/screens/create_event_type/create_event_type_test_ids.dart';
import 'package:racketmates/screens/create_event_when_where/create_event_when_where_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/place_picker/place_picker_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

InMemoryContentCache _content() => InMemoryContentCache()
  ..snapshot = ContentSnapshot(
    referenceData: [
      {
        'id': 1,
        'data_type': 'event_type',
        'key': 'et_individual_lesson',
        'localized_label': 'Private lesson',
      },
      {
        'id': 2,
        'data_type': 'event_type',
        'key': 'et_practice_ball',
        'localized_label': 'Ball machine',
      },
    ],
  );

const _alex = AppUser(id: 8, firstName: 'Alex', lastName: 'Kim');
const _pat = AppUser(id: 9, firstName: 'Pat', lastName: 'Lee');
const _sam = AppUser(id: 10, firstName: 'Sam', lastName: 'Fox');
const _courtsAt = PlaceItem(
  id: 5,
  name: 'Central Courts',
  addressDetail: PlaceAddress(latitude: 40.7, longitude: -74),
);

class _Wizard {
  _Wizard()
    : create = FakeCreateEventRepository(players: [_alex, _pat, _sam]),
      places = FakePlacesRepository(
        places: [_courtsAt],
        detailsById: {
          5: _courtsAt.copyWith(
            placeCourts: const [
              PlaceCourt(id: 11, name: 'Court 1', sportType: 'st_tennis'),
              PlaceCourt(id: 12, name: 'Court 2', sportType: 'st_tennis'),
            ],
          ),
        },
      );

  final FakeCreateEventRepository create;
  final FakePlacesRepository places;

  Widget app() => signedInApp(
    createEvent: create,
    places: places,
    contentCache: _content(),
  );
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

Future<void> _toSport(WidgetTester tester, String type) async {
  await tester.pumpAndSettle();
  await _tap(tester, MainShellTestIds.navSchedule);
  await _tap(tester, ScheduleTestIds.createEvent);
  await _tap(tester, CreateEventTypeTestIds.type(type));
  await _tap(tester, CreateEventSportTestIds.sport('st_tennis'));
  await _tap(tester, CreateEventSportTestIds.next);
}

Future<void> _venue(WidgetTester tester, {List<int> courts = const []}) async {
  await _tap(tester, CreateEventWhenWhereTestIds.venueButton);
  await _tap(tester, PlacePickerTestIds.place(5));
  for (final c in courts) {
    await _tap(tester, CreateEventWhenWhereTestIds.court(c));
  }
  await _tap(tester, CreateEventWhenWhereTestIds.dateButton);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await _tap(tester, CreateEventWhenWhereTestIds.timeButton);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await _tap(tester, CreateEventWhenWhereTestIds.next);
}

void main() {
  testWidgets(
    'lesson: no team choice, coaches limited to two, no manage switch',
    (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final w = _Wizard();
      await tester.pumpWidget(w.app());
      await _toSport(tester, 'et_individual_lesson');

      expect(_id(CreateEventTeamChoiceTestIds.root), findsNothing);
      expect(_id(CreateEventSettingsTestIds.root), findsOneWidget);
      expect(_id(CreateEventSettingsTestIds.allowManage), findsNothing);
      await _tap(tester, CreateEventSettingsTestIds.next);

      expect(_id(CreateEventCoachesTestIds.root), findsOneWidget);
      expect(find.text('Choose up to two coaches.'), findsOneWidget);
      for (final id in [8, 9, 10]) {
        await _tap(tester, CreateEventCoachesTestIds.coach(id));
      }
      // The third coach was ignored.
      await _tap(tester, CreateEventCoachesTestIds.next);
      await _venue(tester, courts: [11, 12]);
      await _tap(tester, CreateEventAssignTypeTestIds.next);
      await _tap(tester, CreateEventInviteSettingsTestIds.next);
      await _tap(tester, CreateEventPlayersTestIds.player(10));
      await _tap(tester, CreateEventPlayersTestIds.next);
      await _tap(tester, CreateEventReviewTestIds.create);

      final event = w.create.body!['event'] as Map<String, dynamic>;
      final coaches = (event['event_participants_attributes'] as List)
          .where((p) => (p as Map)['is_coach'] == true)
          .map((p) => (p as Map)['user_id']);
      expect(coaches, [8, 9]);
      // One court only.
      expect(event['event_venue_courts_attributes'], [
        {'place_court_id': 11, 'order': 1},
      ]);
      handle.dispose();
    },
  );

  testWidgets('lesson: invite several, the player limit is fixed at one', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _toSport(tester, 'et_individual_lesson');
    await _tap(tester, CreateEventSettingsTestIds.next);
    await _tap(tester, CreateEventCoachesTestIds.coach(8));
    await _tap(tester, CreateEventCoachesTestIds.next);
    await _venue(tester);

    expect(find.text('Who is the lesson for?'), findsOneWidget);
    expect(find.text('Several players'), findsOneWidget);
    await _tap(tester, CreateEventAssignTypeTestIds.next);

    expect(_id(CreateEventInviteSettingsTestIds.root), findsOneWidget);
    expect(
      _id('${CreateEventInviteSettingsTestIds.playersPrefix}_increase'),
      findsNothing,
    );
    expect(
      _id('${CreateEventInviteSettingsTestIds.rsvpPrefix}_increase'),
      findsOneWidget,
    );
    await _tap(tester, CreateEventInviteSettingsTestIds.next);

    // Several players can be invited.
    await _tap(tester, CreateEventPlayersTestIds.player(9));
    await _tap(tester, CreateEventPlayersTestIds.player(10));
    expect(_id(CreateEventPlayersTestIds.selected), findsOneWidget);
    await _tap(tester, CreateEventPlayersTestIds.next);
    await _tap(tester, CreateEventReviewTestIds.create);

    final event = w.create.body!['event'] as Map<String, dynamic>;
    expect(event['assign_type'], 'at_assign_later');
    expect(event['players_limit'], 1);
    expect(
      (event['event_participants_attributes'] as List)
          .where((p) => (p as Map)['is_player'] == true)
          .map((p) => (p as Map)['user_id']),
      [9, 10],
    );
    handle.dispose();
  });

  testWidgets('lesson: one player now, picking another replaces the first', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _toSport(tester, 'et_individual_lesson');
    await _tap(tester, CreateEventSettingsTestIds.next);
    await _tap(tester, CreateEventCoachesTestIds.coach(8));
    await _tap(tester, CreateEventCoachesTestIds.next);
    await _venue(tester);
    await _tap(tester, CreateEventAssignTypeTestIds.assignNow);
    await _tap(tester, CreateEventAssignTypeTestIds.next);

    // No invite settings: straight to choosing the player.
    expect(_id(CreateEventInviteSettingsTestIds.root), findsNothing);
    expect(find.text('Choose the player'), findsOneWidget);
    await _tap(tester, CreateEventPlayersTestIds.player(9));
    await _tap(tester, CreateEventPlayersTestIds.player(10));
    await _tap(tester, CreateEventPlayersTestIds.next);
    await _tap(tester, CreateEventReviewTestIds.create);
    expect(_id(CreateEventSuccessTestIds.root), findsOneWidget);

    final event = w.create.body!['event'] as Map<String, dynamic>;
    expect(event['assign_type'], 'at_court_addition');
    expect(
      (event['event_participants_attributes'] as List)
          .where((p) => (p as Map)['is_player'] == true)
          .map((p) => (p as Map)['user_id']),
      [10],
    );
    handle.dispose();
  });

  testWidgets('ball machine: venue and court, one player, no settings', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _toSport(tester, 'et_practice_ball');

    // The venue comes straight after the sport: no team choice or settings.
    expect(_id(CreateEventWhenWhereTestIds.root), findsOneWidget);
    expect(
      _id('${CreateEventWhenWhereTestIds.courtCountPrefix}_increase'),
      findsNothing,
    );
    await _venue(tester, courts: [12]);

    expect(find.text('Choose the player'), findsOneWidget);
    await _tap(tester, CreateEventPlayersTestIds.next);
    expect(_id(CreateEventPlayersTestIds.error), findsOneWidget);
    await _tap(tester, CreateEventPlayersTestIds.player(8));
    await _tap(tester, CreateEventPlayersTestIds.player(9));
    await _tap(tester, CreateEventPlayersTestIds.next);

    expect(_id(CreateEventReviewTestIds.root), findsOneWidget);
    expect(find.text('Ball machine'), findsOneWidget);
    expect(find.text('Pat Lee'), findsOneWidget);
    await _tap(tester, CreateEventReviewTestIds.create);

    final event = w.create.body!['event'] as Map<String, dynamic>;
    expect(event['event_type'], 'et_practice_ball');
    expect(event['assign_type'], 'at_court_addition');
    final match = (event['event_matches_attributes'] as List).single as Map;
    expect(match['place_court_id'], 12);
    expect(
      ((match['event_match_sides_attributes'] as List).first
          as Map)['event_participants'],
      [
        {'user_id': 9, 'position': 'epp_center'},
      ],
    );
    expect(event.containsKey('attendance_deadline_unit'), isFalse);
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('lesson and ball machine steps meet guidelines ($mode)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue =
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      useTallScreen(tester);
      await tester.pumpWidget(_Wizard().app());
      await _toSport(tester, 'et_individual_lesson');

      Future<void> check() async {
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }

      await check(); // settings
      await _tap(tester, CreateEventSettingsTestIds.next);
      await check(); // coaches with hint
      await _tap(tester, CreateEventCoachesTestIds.coach(8));
      await _tap(tester, CreateEventCoachesTestIds.next);
      await _venue(tester);
      await check(); // lesson assign type
      await _tap(tester, CreateEventAssignTypeTestIds.next);
      await check(); // invite settings, fixed players limit
      handle.dispose();
    });
  }
}
