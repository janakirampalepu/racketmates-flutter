import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/content/content_cache.dart';
import 'package:racketmates/common/create_event/create_event_api.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/create_event_assign_players/create_event_assign_players_test_ids.dart';
import 'package:racketmates/screens/create_event_assign_type/create_event_assign_type_test_ids.dart';
import 'package:racketmates/screens/create_event_invite_settings/create_event_invite_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_matches/create_event_matches_test_ids.dart';
import 'package:racketmates/screens/create_event_players/create_event_players_test_ids.dart';
import 'package:racketmates/screens/create_event_review/create_event_review_test_ids.dart';
import 'package:racketmates/screens/create_event_round_robin_format/create_event_round_robin_format_test_ids.dart';
import 'package:racketmates/screens/create_event_settings/create_event_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_slot_picker/create_event_slot_picker_test_ids.dart';
import 'package:racketmates/screens/create_event_sport/create_event_sport_test_ids.dart';
import 'package:racketmates/screens/create_event_team_choice/create_event_team_choice_test_ids.dart';
import 'package:racketmates/screens/create_event_success/create_event_success_test_ids.dart';
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
      for (final (i, e) in [
        ('et_competitive', 'Competitive game'),
        ('et_casual', 'Casual game'),
        ('et_round_robin', 'Round robin'),
      ].indexed)
        {
          'id': i + 1,
          'data_type': 'event_type',
          'key': e.$1,
          'localized_label': e.$2,
        },
      {
        'id': 20,
        'data_type': 'scoring_format',
        'key': 'sf_single_set',
        'localized_label': 'Single set',
        'localized_sub_text': 'First to the games target',
      },
    ],
  );

const _alex = AppUser(id: 8, firstName: 'Alex', lastName: 'Kim');
const _pat = AppUser(id: 9, firstName: 'Pat', lastName: 'Lee');
const _courtsAt = PlaceItem(
  id: 5,
  name: 'Central Courts',
  addressDetail: PlaceAddress(latitude: 40.7, longitude: -74),
);

class _Wizard {
  _Wizard({ScoringFormatsResponse? scoring})
    : create = scoring == null
          ? FakeCreateEventRepository(players: [_alex, _pat])
          : FakeCreateEventRepository(players: [_alex, _pat], scoring: scoring),
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

  final FakePlacesRepository places;
  final FakeCreateEventRepository create;

  Widget app() => signedInApp(
    places: places,
    createEvent: create,
    contentCache: _content(),
  );
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

Future<void> _openWizard(WidgetTester tester, String type) async {
  await tester.pumpAndSettle();
  await _tap(tester, MainShellTestIds.navSchedule);
  await _tap(tester, ScheduleTestIds.createEvent);
  await _tap(tester, CreateEventTypeTestIds.type(type));
}

Future<void> _throughTeamChoice(WidgetTester tester) async {
  await _tap(tester, CreateEventTeamChoiceTestIds.nonTeam);
  await _tap(tester, CreateEventTeamChoiceTestIds.next);
}

Future<void> _throughSport(WidgetTester tester) async {
  await _tap(tester, CreateEventSportTestIds.sport('st_tennis'));
  await _tap(tester, CreateEventSportTestIds.next);
  await _throughTeamChoice(tester);
}

Future<void> _throughWhenWhere(
  WidgetTester tester, {
  List<int> courts = const [],
}) async {
  await _tap(tester, CreateEventWhenWhereTestIds.venueButton);
  await _tap(tester, PlacePickerTestIds.place(5));
  for (final court in courts) {
    await _tap(tester, CreateEventWhenWhereTestIds.court(court));
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
    'settings: scoring formats load, the first is chosen, score steps',
    (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final w = _Wizard();
      await tester.pumpWidget(w.app());
      await _openWizard(tester, 'et_competitive');
      await _throughSport(tester);

      expect(w.create.scoringRequests.single, (
        sport: 'st_tennis',
        eventType: 'et_competitive',
      ));
      expect(
        _id(CreateEventSettingsTestIds.format('sf_best_of_3_sets')),
        findsOneWidget,
      );
      // Server label and sub text show for formats it describes.
      expect(find.text('Single set'), findsOneWidget);
      expect(find.text('First to the games target'), findsOneWidget);
      // Tennis can decide a tied last set; best-of formats have no score.
      expect(
        _id(CreateEventSettingsTestIds.decidingSet('dst_tie_break')),
        findsOneWidget,
      );
      expect(_id(CreateEventSettingsTestIds.scoreValue), findsNothing);

      await _tap(tester, CreateEventSettingsTestIds.format('sf_single_set'));
      expect(
        _id(CreateEventSettingsTestIds.decidingSet('dst_tie_break')),
        findsNothing,
      );
      expect(find.text('6'), findsOneWidget);
      await _tap(tester, CreateEventSettingsTestIds.scoreIncrease);
      expect(find.text('7'), findsOneWidget);

      await _tap(tester, CreateEventSettingsTestIds.format('sf_time_based'));
      expect(_id(CreateEventSettingsTestIds.scoreMinutes), findsOneWidget);
      expect(find.text('15 mins'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('settings: cannot continue without formats; retry reloads', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final w = _Wizard()..create.scoringFails = true;
    await tester.pumpWidget(w.app());
    await _openWizard(tester, 'et_casual');
    await _throughSport(tester);

    expect(_id(CreateEventSettingsTestIds.scoringError), findsOneWidget);
    await _tap(tester, CreateEventSettingsTestIds.next);
    expect(_id(CreateEventSettingsTestIds.root), findsOneWidget); // blocked

    w.create.scoringFails = false;
    await _tap(tester, CreateEventSettingsTestIds.scoringRetry);
    expect(_id(CreateEventSettingsTestIds.scoringError), findsNothing);
    await _tap(tester, CreateEventSettingsTestIds.next);
    expect(_id(CreateEventMatchesTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('padel has no deciding set choice', (tester) async {
    final handle = tester.ensureSemantics();
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester, 'et_competitive');
    await _tap(tester, CreateEventSportTestIds.sport('st_pickleball'));
    await _tap(tester, CreateEventSportTestIds.next);
    await _throughTeamChoice(tester);
    expect(
      _id(CreateEventSettingsTestIds.decidingSet('dst_tie_break')),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('matches: add, change type, remove (one stays)', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester, 'et_competitive');
    await _throughSport(tester);
    await _tap(tester, CreateEventSettingsTestIds.next);

    expect(_id(CreateEventMatchesTestIds.match(0)), findsOneWidget);
    expect(_id(CreateEventMatchesTestIds.removeMatch(0)), findsNothing);
    await _tap(tester, CreateEventMatchesTestIds.addMatch);
    expect(_id(CreateEventMatchesTestIds.match(1)), findsOneWidget);
    await _tap(tester, CreateEventMatchesTestIds.matchType(1, 'mt_singles'));
    await _tap(tester, CreateEventMatchesTestIds.removeMatch(0));
    expect(_id(CreateEventMatchesTestIds.match(1)), findsNothing);
    expect(_id(CreateEventMatchesTestIds.removeMatch(0)), findsNothing);
    handle.dispose();
  });

  testWidgets('assign later: invite players, create the game', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester, 'et_competitive');
    await _throughSport(tester);
    await _tap(tester, CreateEventSettingsTestIds.format('sf_single_set'));
    await _tap(tester, CreateEventSettingsTestIds.allowLogResults);
    await _tap(tester, CreateEventSettingsTestIds.next);

    await _tap(tester, CreateEventMatchesTestIds.matchType(0, 'mt_singles'));
    await _tap(tester, CreateEventMatchesTestIds.addMatch);
    await _tap(tester, CreateEventMatchesTestIds.matchType(1, 'mt_doubles'));
    await _tap(tester, CreateEventMatchesTestIds.next);

    // Venue, one court per match (two matches), date and time.
    await _throughWhenWhere(tester, courts: [11, 12]);
    expect(_id(CreateEventAssignTypeTestIds.root), findsOneWidget);
    await _tap(tester, CreateEventAssignTypeTestIds.next);

    // Limits are sized from the matches: 2 + 4 players.
    expect(_id(CreateEventInviteSettingsTestIds.root), findsOneWidget);
    expect(find.text('6'), findsNWidgets(2));
    await _tap(tester, CreateEventInviteSettingsTestIds.next);

    await _tap(tester, CreateEventPlayersTestIds.player(8));
    await _tap(tester, CreateEventPlayersTestIds.next);

    expect(_id(CreateEventReviewTestIds.root), findsOneWidget);
    expect(find.text('Competitive game'), findsOneWidget);
    expect(_id(CreateEventReviewTestIds.summaryScoring), findsOneWidget);
    expect(find.text('Single set (6)'), findsOneWidget);
    expect(_id(CreateEventReviewTestIds.summaryMatch(1)), findsOneWidget);

    await _tap(tester, CreateEventReviewTestIds.create);
    expect(_id(CreateEventSuccessTestIds.root), findsOneWidget);

    final event = w.create.body!['event'] as Map<String, dynamic>;
    expect(event['event_type'], 'et_competitive');
    expect(event['scoring_format'], 'sf_single_set');
    expect(event['minimum_score_to_win'], 6);
    expect(event['allow_participants_to_log_results'], isTrue);
    expect(event['assign_type'], 'at_assign_later');
    expect(event['players_limit'], 6);
    final matches = event['event_matches_attributes'] as List;
    expect(matches.map((m) => (m as Map)['match_type']), [
      'mt_singles',
      'mt_doubles',
    ]);
    expect(matches.map((m) => (m as Map)['place_court_id']), [11, 12]);
    expect(
      (event['event_participants_attributes'] as List).single['user_id'],
      8,
    );
    handle.dispose();
  });

  testWidgets('assign now needs singles or doubles, then fills every spot', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester, 'et_casual');
    await _throughSport(tester);
    await _tap(tester, CreateEventSettingsTestIds.next);
    await _tap(tester, CreateEventMatchesTestIds.next); // left undecided
    await _throughWhenWhere(tester);

    // An undecided match has no spots to fill.
    await _tap(tester, CreateEventAssignTypeTestIds.assignNow);
    await _tap(tester, CreateEventAssignTypeTestIds.next);
    expect(_id(CreateEventAssignTypeTestIds.error), findsOneWidget);
    expect(_id(CreateEventAssignTypeTestIds.root), findsOneWidget);

    // Go back and decide the match.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tap(tester, CreateEventMatchesTestIds.matchType(0, 'mt_singles'));
    await _tap(tester, CreateEventMatchesTestIds.next);
    await _tap(tester, CreateEventWhenWhereTestIds.next);
    await _tap(tester, CreateEventAssignTypeTestIds.next);

    expect(_id(CreateEventAssignPlayersTestIds.root), findsOneWidget);
    await _tap(tester, CreateEventAssignPlayersTestIds.next);
    expect(_id(CreateEventAssignPlayersTestIds.error), findsOneWidget);

    const top = ('ecs_top', 'epp_center');
    const bottom = ('ecs_bottom', 'epp_center');
    await _tap(tester, CreateEventAssignPlayersTestIds.slot(0, top.$1, top.$2));
    expect(_id(CreateEventSlotPickerTestIds.root), findsOneWidget);
    await _tap(tester, CreateEventSlotPickerTestIds.person(8));
    expect(find.text('Alex Kim'), findsOneWidget);
    await _tap(
      tester,
      CreateEventAssignPlayersTestIds.slot(0, bottom.$1, bottom.$2),
    );
    await _tap(tester, CreateEventSlotPickerTestIds.person(9));
    await _tap(tester, CreateEventAssignPlayersTestIds.next);

    expect(_id(CreateEventReviewTestIds.root), findsOneWidget);
    expect(find.text('Alex Kim vs Pat Lee'), findsOneWidget);
    await _tap(tester, CreateEventReviewTestIds.create);

    final event = w.create.body!['event'] as Map<String, dynamic>;
    expect(event['assign_type'], 'at_court_addition');
    expect(event['event_participants_attributes'], isEmpty);
    final sides =
        (event['event_matches_attributes'] as List)
                .single['event_match_sides_attributes']
            as List;
    expect((sides[0] as Map)['event_participants'], [
      {'user_id': 8, 'position': 'epp_center'},
    ]);
    expect((sides[1] as Map)['event_participants'], [
      {'user_id': 9, 'position': 'epp_center'},
    ]);
    handle.dispose();
  });

  testWidgets('a spot can be cleared and refilled', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester, 'et_competitive');
    await _throughSport(tester);
    await _tap(tester, CreateEventSettingsTestIds.next);
    await _tap(tester, CreateEventMatchesTestIds.matchType(0, 'mt_singles'));
    await _tap(tester, CreateEventMatchesTestIds.next);
    await _throughWhenWhere(tester);
    await _tap(tester, CreateEventAssignTypeTestIds.assignNow);
    await _tap(tester, CreateEventAssignTypeTestIds.next);

    final slot = CreateEventAssignPlayersTestIds.slot(
      0,
      'ecs_top',
      'epp_center',
    );
    await _tap(tester, slot);
    await _tap(tester, CreateEventSlotPickerTestIds.person(8));
    expect(find.text('Alex Kim'), findsOneWidget);
    await _tap(
      tester,
      CreateEventAssignPlayersTestIds.clear(0, 'ecs_top', 'epp_center'),
    );
    expect(find.text('Alex Kim'), findsNothing);
    expect(find.text('Add player'), findsNWidgets(2));
    handle.dispose();
  });

  testWidgets('round robin: setup, format, courts, players, request', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester, 'et_round_robin');
    await _throughSport(tester);
    await _tap(tester, CreateEventSettingsTestIds.next);

    // Setup: 2 courts, doubles with fixed partners.
    expect(_id(CreateEventMatchesTestIds.root), findsOneWidget);
    await _tap(
      tester,
      '${CreateEventMatchesTestIds.courtCountPrefix}_increase',
    );
    await _tap(tester, CreateEventMatchesTestIds.partners('ept_fixed'));
    await _tap(tester, CreateEventMatchesTestIds.next);

    // The format must be chosen first.
    expect(_id(CreateEventRoundRobinFormatTestIds.root), findsOneWidget);
    FilledButton next() => tester.widget<FilledButton>(
      find.descendant(
        of: _id(CreateEventRoundRobinFormatTestIds.next),
        matching: find.byType(FilledButton),
      ),
    );
    expect(next().onPressed, isNull);
    expect(
      find.textContaining('Keep the same partner throughout'),
      findsOneWidget,
    );
    await _tap(
      tester,
      CreateEventRoundRobinFormatTestIds.format('est_king_of_the_court'),
    );
    expect(next().onPressed, isNotNull);
    await _tap(tester, CreateEventRoundRobinFormatTestIds.next);

    await _throughWhenWhere(tester, courts: [11, 12]);
    // 2 courts of doubles hold 8 players.
    expect(_id(CreateEventInviteSettingsTestIds.root), findsOneWidget);
    expect(find.text('8'), findsNWidgets(2));
    await _tap(tester, CreateEventInviteSettingsTestIds.next);
    await _tap(tester, CreateEventPlayersTestIds.player(8));
    await _tap(tester, CreateEventPlayersTestIds.next);
    await _tap(tester, CreateEventReviewTestIds.create);

    final event = w.create.body!['event'] as Map<String, dynamic>;
    expect(event['event_type'], 'et_round_robin');
    expect(event['no_of_courts'], 2);
    expect(event['game_type'], 'egt_doubles');
    expect(event['partnership_type'], 'ept_fixed');
    expect(event['event_sub_type'], 'est_king_of_the_court');
    expect(event['event_venue_courts_attributes'], [
      {'place_court_id': 11, 'order': 1},
      {'place_court_id': 12, 'order': 2},
    ]);
    expect(event.containsKey('event_matches_attributes'), isFalse);
    handle.dispose();
  });

  testWidgets('round robin singles hides the partner choice', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _openWizard(tester, 'et_round_robin');
    await _throughSport(tester);
    await _tap(tester, CreateEventSettingsTestIds.next);
    expect(
      _id(CreateEventMatchesTestIds.partners('ept_rotating')),
      findsOneWidget,
    );
    await _tap(tester, CreateEventMatchesTestIds.gameType('egt_singles'));
    expect(
      _id(CreateEventMatchesTestIds.partners('ept_rotating')),
      findsNothing,
    );
    await _tap(tester, CreateEventMatchesTestIds.next);
    expect(find.textContaining('Rotate opponents each match'), findsOneWidget);
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('game steps meet contrast and tap-target guidelines ($mode)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue =
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      useTallScreen(tester);
      await tester.pumpWidget(_Wizard().app());
      await _openWizard(tester, 'et_competitive');

      Future<void> check() async {
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }

      await _throughSport(tester);
      await check(); // settings with scoring
      await _tap(tester, CreateEventSettingsTestIds.next);
      await _tap(tester, CreateEventMatchesTestIds.addMatch);
      await _tap(tester, CreateEventMatchesTestIds.matchType(0, 'mt_singles'));
      await check(); // matches
      await _tap(tester, CreateEventMatchesTestIds.next);
      await _tap(tester, CreateEventWhenWhereTestIds.next); // errors shown
      await _throughWhenWhere(tester);
      await check(); // assign type
      await _tap(tester, CreateEventAssignTypeTestIds.assignNow);
      await _tap(
        tester,
        CreateEventAssignTypeTestIds.next,
      ); // match 2 undecided
      await check(); // with error
      handle.dispose();
    });

    testWidgets('round robin steps meet guidelines ($mode)', (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue =
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      useTallScreen(tester);
      await tester.pumpWidget(_Wizard().app());
      await _openWizard(tester, 'et_round_robin');

      Future<void> check() async {
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }

      await _throughSport(tester);
      await _tap(tester, CreateEventSettingsTestIds.next);
      await check(); // setup
      await _tap(tester, CreateEventMatchesTestIds.next);
      await _tap(
        tester,
        CreateEventRoundRobinFormatTestIds.format('est_classic'),
      );
      await check(); // format
      handle.dispose();
    });
  }
}
