import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/content/content_cache.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/create_event_invite_settings/create_event_invite_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_players/create_event_players_test_ids.dart';
import 'package:racketmates/screens/create_event_review/create_event_review_test_ids.dart';
import 'package:racketmates/screens/create_event_settings/create_event_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_sport/create_event_sport_test_ids.dart';
import 'package:racketmates/screens/create_event_team_choice/create_event_team_choice_test_ids.dart';
import 'package:racketmates/screens/create_event_team_select/create_event_team_select_test_ids.dart';
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
        ('et_practice_drill', 'Practice drill'),
        ('et_casual_meeting', 'Casual meetup'),
        ('et_round_robin', 'Round robin'),
      ].indexed)
        {
          'id': i + 1,
          'data_type': 'event_type',
          'key': e.$1,
          'localized_label': e.$2,
        },
    ],
  );

const _alex = AppUser(id: 8, firstName: 'Alex', lastName: 'Kim');
const _pat = AppUser(id: 9, firstName: 'Pat', lastName: 'Lee');
const _sam = AppUser(id: 10, firstName: 'Sam', lastName: 'Fox');
const _smashers = Team(
  id: 31,
  name: 'Sunday Smashers',
  teamType: TeamTypes.competitive,
  teamSports: [TeamSport(id: 1, sportType: 'st_tennis')],
);
const _courtsAt = PlaceItem(
  id: 5,
  name: 'Central Courts',
  addressDetail: PlaceAddress(latitude: 40.7, longitude: -74),
);

class _Wizard {
  _Wizard({List<Team> captain = const [_smashers]})
    : teams = FakeTeamsRepository(
        captain: captain,
        membersByTeam: {
          31: const [
            TeamPlayer(id: 501, userId: 8, isPlayer: true, user: _alex),
            TeamPlayer(id: 502, userId: 9, isCoach: true, user: _pat),
          ],
        },
      ),
      // Everyone on the platform; the team roster is only Alex and Pat.
      create = FakeCreateEventRepository(players: [_alex, _pat, _sam]),
      places = FakePlacesRepository(places: [_courtsAt]);

  final FakeTeamsRepository teams;
  final FakeCreateEventRepository create;
  final FakePlacesRepository places;

  Widget app() => signedInApp(
    teams: teams,
    createEvent: create,
    places: places,
    contentCache: _content(),
  );
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String type) async {
  await tester.pumpAndSettle();
  await _tap(tester, MainShellTestIds.navSchedule);
  await _tap(tester, ScheduleTestIds.createEvent);
  await _tap(tester, CreateEventTypeTestIds.type(type));
}

Future<void> _sport(WidgetTester tester) async {
  await _tap(tester, CreateEventSportTestIds.sport('st_tennis'));
  await _tap(tester, CreateEventSportTestIds.next);
}

Future<void> _chooseTeamEvent(WidgetTester tester) async {
  await _tap(tester, CreateEventTeamChoiceTestIds.team);
  await _tap(tester, CreateEventTeamChoiceTestIds.next);
}

void main() {
  testWidgets('the choice must be made before continuing', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_Wizard().app());
    await _open(tester, 'et_practice_drill');
    await _sport(tester);

    FilledButton next() => tester.widget<FilledButton>(
      find.descendant(
        of: _id(CreateEventTeamChoiceTestIds.next),
        matching: find.byType(FilledButton),
      ),
    );
    expect(next().onPressed, isNull);
    await _tap(tester, CreateEventTeamChoiceTestIds.nonTeam);
    expect(next().onPressed, isNotNull);
    handle.dispose();
  });

  testWidgets('team practice: pick a captained team, invite its members', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _open(tester, 'et_practice_drill');
    await _sport(tester);
    await _chooseTeamEvent(tester);

    // Only teams the user captains that play the sport are offered.
    expect(w.teams.captainRequests.single.sport, 'st_tennis');
    expect(w.teams.captainRequests.single.userIds, ['7']);
    expect(find.text('Sunday Smashers'), findsOneWidget);
    expect(find.text('Competitive · Tennis'), findsOneWidget);
    await _tap(tester, CreateEventTeamSelectTestIds.next);
    expect(_id(CreateEventTeamSelectTestIds.requiredError), findsOneWidget);
    expect(_id(CreateEventTeamSelectTestIds.root), findsOneWidget);
    await _tap(tester, CreateEventTeamSelectTestIds.team(31));
    await _tap(tester, CreateEventTeamSelectTestIds.next);
    await _tap(tester, CreateEventSettingsTestIds.next);

    // Players come from the team roster, filtered by role and sport.
    expect(w.teams.memberSearches.first, (
      team: 31,
      query: '',
      role: 'ur_player',
      sport: 'st_tennis',
    ));
    expect(w.create.searches, isEmpty);
    expect(_id(CreateEventPlayersTestIds.player(8)), findsOneWidget);
    expect(_id(CreateEventPlayersTestIds.player(9)), findsNothing); // a coach
    expect(
      _id(CreateEventPlayersTestIds.player(10)),
      findsNothing,
    ); // not on the team
    await _tap(tester, CreateEventPlayersTestIds.player(8));
    await _tap(tester, CreateEventPlayersTestIds.next);

    await _tap(tester, CreateEventWhenWhereTestIds.venueButton);
    await _tap(tester, PlacePickerTestIds.place(5));
    await _tap(tester, CreateEventWhenWhereTestIds.dateButton);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tap(tester, CreateEventWhenWhereTestIds.timeButton);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tap(tester, CreateEventWhenWhereTestIds.next);
    await _tap(tester, CreateEventInviteSettingsTestIds.next);

    expect(_id(CreateEventReviewTestIds.summaryTeam), findsOneWidget);
    expect(find.text('Sunday Smashers'), findsOneWidget);
    await _tap(tester, CreateEventReviewTestIds.create);

    final event = w.create.body!['event'] as Map<String, dynamic>;
    expect(event['originator_type'], 'Team');
    expect(event['originator_id'], 31);
    expect(event['opponent_team_type'], 'ott_within_team');
    expect(event['event_teams_attributes'], [
      {
        'team_id': 31,
        'event_team_type': 'ett_home',
        'logged_in_user_belongs_to_team': true,
      },
    ]);
    expect(
      (event['event_participants_attributes'] as List).single['user_id'],
      8,
    );
    handle.dispose();
  });

  testWidgets('no captained team shows why and blocks continuing', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final w = _Wizard(captain: const []);
    await tester.pumpWidget(w.app());
    await _open(tester, 'et_practice_drill');
    await _sport(tester);
    await _chooseTeamEvent(tester);
    expect(_id(CreateEventTeamSelectTestIds.empty), findsOneWidget);
    await _tap(tester, CreateEventTeamSelectTestIds.next);
    expect(_id(CreateEventTeamSelectTestIds.requiredError), findsOneWidget);
    expect(_id(CreateEventTeamSelectTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('teams that cannot be loaded can be retried', (tester) async {
    final handle = tester.ensureSemantics();
    final w = _Wizard()..teams.failing = true;
    await tester.pumpWidget(w.app());
    await _open(tester, 'et_practice_drill');
    await _sport(tester);
    await _chooseTeamEvent(tester);
    expect(_id(CreateEventTeamSelectTestIds.error), findsOneWidget);
    w.teams.failing = false;
    await _tap(tester, CreateEventTeamSelectTestIds.retry);
    expect(_id(CreateEventTeamSelectTestIds.team(31)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a team meetup has no sport filter anywhere', (tester) async {
    final handle = tester.ensureSemantics();
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _open(tester, 'et_casual_meeting');
    await _chooseTeamEvent(tester);
    expect(w.teams.captainRequests.single.sport, isNull);
    await _tap(tester, CreateEventTeamSelectTestIds.team(31));
    await _tap(tester, CreateEventTeamSelectTestIds.next);
    await _tap(tester, CreateEventSettingsTestIds.next);
    expect(w.teams.memberSearches.first, (
      team: 31,
      query: '',
      role: null,
      sport: null,
    ));
    // Both roster members can be invited as attendees.
    expect(_id(CreateEventPlayersTestIds.player(8)), findsOneWidget);
    expect(_id(CreateEventPlayersTestIds.player(9)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the ranking switch is only for team round robins', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _open(tester, 'et_round_robin');
    await _sport(tester);
    await _tap(tester, CreateEventTeamChoiceTestIds.nonTeam);
    await _tap(tester, CreateEventTeamChoiceTestIds.next);
    expect(_id(CreateEventSettingsTestIds.considerRanking), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _chooseTeamEvent(tester);
    await _tap(tester, CreateEventTeamSelectTestIds.team(31));
    await _tap(tester, CreateEventTeamSelectTestIds.next);
    expect(_id(CreateEventSettingsTestIds.considerRanking), findsOneWidget);
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('team steps meet contrast and tap-target guidelines ($mode)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue =
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      useTallScreen(tester);
      await tester.pumpWidget(_Wizard().app());
      await _open(tester, 'et_practice_drill');
      await _sport(tester);

      Future<void> check() async {
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }

      await check(); // choice
      await _chooseTeamEvent(tester);
      await _tap(tester, CreateEventTeamSelectTestIds.next); // with error
      await check(); // selection
      handle.dispose();
    });
  }
}
