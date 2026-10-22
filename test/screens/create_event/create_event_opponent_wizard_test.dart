import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/content/content_cache.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/create_event_assign_players/create_event_assign_players_test_ids.dart';
import 'package:racketmates/screens/create_event_assign_type/create_event_assign_type_test_ids.dart';
import 'package:racketmates/screens/create_event_home_away/create_event_home_away_test_ids.dart';
import 'package:racketmates/screens/create_event_invite_settings/create_event_invite_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_matches/create_event_matches_test_ids.dart';
import 'package:racketmates/screens/create_event_opponent_select/create_event_opponent_select_test_ids.dart';
import 'package:racketmates/screens/create_event_players/create_event_players_test_ids.dart';
import 'package:racketmates/screens/create_event_review/create_event_review_test_ids.dart';
import 'package:racketmates/screens/create_event_settings/create_event_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_slot_picker/create_event_slot_picker_test_ids.dart';
import 'package:racketmates/screens/create_event_sport/create_event_sport_test_ids.dart';
import 'package:racketmates/screens/create_event_team_choice/create_event_team_choice_test_ids.dart';
import 'package:racketmates/screens/create_event_team_dynamics/create_event_team_dynamics_test_ids.dart';
import 'package:racketmates/screens/create_event_team_select/create_event_team_select_test_ids.dart';
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
        'key': 'et_competitive',
        'localized_label': 'Competitive game',
      },
    ],
  );

const _alex = AppUser(id: 8, firstName: 'Alex', lastName: 'Kim');
const _mine = Team(
  id: 31,
  name: 'Sunday Smashers',
  teamType: TeamTypes.competitive,
  teamSports: [TeamSport(id: 1, sportType: 'st_tennis')],
);
const _eagles = Team(
  id: 44,
  name: 'Eagles',
  teamType: TeamTypes.casual,
  teamSports: [TeamSport(id: 2, sportType: 'st_tennis')],
);
const _hawks = Team(id: 45, name: 'Hawks', teamType: TeamTypes.competitive);
const _courtsAt = PlaceItem(
  id: 5,
  name: 'Central Courts',
  addressDetail: PlaceAddress(latitude: 40.7, longitude: -74),
);

class _Wizard {
  _Wizard()
    : teams = FakeTeamsRepository(
        captain: const [_mine],
        membersByTeam: {
          31: const [
            TeamPlayer(id: 501, userId: 8, isPlayer: true, user: _alex),
          ],
        },
      )..opponents = const [_mine, _eagles, _hawks],
      create = FakeCreateEventRepository(players: [_alex]),
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

/// Competitive game, tennis, team event for the user's own team.
Future<void> _toDynamics(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await _tap(tester, MainShellTestIds.navSchedule);
  await _tap(tester, ScheduleTestIds.createEvent);
  await _tap(tester, CreateEventTypeTestIds.type('et_competitive'));
  await _tap(tester, CreateEventSportTestIds.sport('st_tennis'));
  await _tap(tester, CreateEventSportTestIds.next);
  await _tap(tester, CreateEventTeamChoiceTestIds.team);
  await _tap(tester, CreateEventTeamChoiceTestIds.next);
  await _tap(tester, CreateEventTeamSelectTestIds.team(31));
  await _tap(tester, CreateEventTeamSelectTestIds.next);
  expect(_id(CreateEventTeamDynamicsTestIds.root), findsOneWidget);
}

Future<void> _throughWhenWhere(WidgetTester tester) async {
  await _tap(tester, CreateEventWhenWhereTestIds.venueButton);
  await _tap(tester, PlacePickerTestIds.place(5));
  await _tap(tester, CreateEventWhenWhereTestIds.dateButton);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await _tap(tester, CreateEventWhenWhereTestIds.timeButton);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await _tap(tester, CreateEventWhenWhereTestIds.next);
}

void main() {
  testWidgets('the opponent must be chosen; a named team needs a name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(_Wizard().app());
    await _toDynamics(tester);

    FilledButton next() => tester.widget<FilledButton>(
      find.descendant(
        of: _id(CreateEventTeamDynamicsTestIds.next),
        matching: find.byType(FilledButton),
      ),
    );
    expect(next().onPressed, isNull);

    await _tap(
      tester,
      CreateEventTeamDynamicsTestIds.option('ott_unknown_team_with_name'),
    );
    expect(_id(CreateEventTeamDynamicsTestIds.name), findsOneWidget);
    await _tap(tester, CreateEventTeamDynamicsTestIds.next);
    expect(_id(CreateEventTeamDynamicsTestIds.nameError), findsOneWidget);
    expect(_id(CreateEventTeamDynamicsTestIds.root), findsOneWidget);

    await tester.enterText(
      _field(CreateEventTeamDynamicsTestIds.name),
      'Eagles FC',
    );
    await tester.pump();
    expect(_id(CreateEventTeamDynamicsTestIds.nameError), findsNothing);
    await _tap(tester, CreateEventTeamDynamicsTestIds.next);

    // No team to pick: straight to home and visiting.
    expect(_id(CreateEventHomeAwayTestIds.root), findsOneWidget);
    expect(_id(CreateEventOpponentSelectTestIds.root), findsNothing);
    handle.dispose();
  });

  testWidgets('within the team goes straight on to the settings', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(_Wizard().app());
    await _toDynamics(tester);
    await _tap(
      tester,
      CreateEventTeamDynamicsTestIds.option('ott_within_team'),
    );
    await _tap(tester, CreateEventTeamDynamicsTestIds.next);
    expect(_id(CreateEventSettingsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('choose an opponent team: others only, searchable, required', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _toDynamics(tester);
    await _tap(
      tester,
      CreateEventTeamDynamicsTestIds.option('ott_specific_team'),
    );
    await _tap(tester, CreateEventTeamDynamicsTestIds.next);

    expect(w.teams.opponentRequests.first.exclude, 31);
    expect(w.teams.opponentRequests.first.sport, 'st_tennis');
    expect(_id(CreateEventOpponentSelectTestIds.team(44)), findsOneWidget);
    expect(_id(CreateEventOpponentSelectTestIds.team(45)), findsOneWidget);
    expect(_id(CreateEventOpponentSelectTestIds.team(31)), findsNothing);

    await _tap(tester, CreateEventOpponentSelectTestIds.next);
    expect(_id(CreateEventOpponentSelectTestIds.requiredError), findsOneWidget);
    expect(_id(CreateEventOpponentSelectTestIds.root), findsOneWidget);

    await tester.enterText(
      _field(CreateEventOpponentSelectTestIds.search),
      'eag',
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(w.teams.opponentRequests.last.query, 'eag');
    expect(_id(CreateEventOpponentSelectTestIds.team(45)), findsNothing);
    await _tap(tester, CreateEventOpponentSelectTestIds.team(44));
    await _tap(tester, CreateEventOpponentSelectTestIds.next);
    expect(_id(CreateEventHomeAwayTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no other teams and load failures are explained', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard()..teams.opponents = const [];
    await tester.pumpWidget(w.app());
    await _toDynamics(tester);
    await _tap(
      tester,
      CreateEventTeamDynamicsTestIds.option('ott_specific_team'),
    );
    await _tap(tester, CreateEventTeamDynamicsTestIds.next);
    expect(_id(CreateEventOpponentSelectTestIds.empty), findsOneWidget);

    w.teams
      ..opponents = const [_eagles]
      ..failing = true;
    await tester.enterText(
      _field(CreateEventOpponentSelectTestIds.search),
      'e',
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(_id(CreateEventOpponentSelectTestIds.error), findsOneWidget);
    w.teams.failing = false;
    await _tap(tester, CreateEventOpponentSelectTestIds.retry);
    expect(_id(CreateEventOpponentSelectTestIds.team(44)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('home and visiting: swap and undecided', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(_Wizard().app());
    await _toDynamics(tester);
    await _tap(
      tester,
      CreateEventTeamDynamicsTestIds.option('ott_specific_team'),
    );
    await _tap(tester, CreateEventTeamDynamicsTestIds.next);
    await _tap(tester, CreateEventOpponentSelectTestIds.team(44));
    await _tap(tester, CreateEventOpponentSelectTestIds.next);

    String name(String id) => tester
        .widget<Text>(
          find.descendant(of: _id(id), matching: find.byType(Text)).first,
        )
        .data!;
    expect(name(CreateEventHomeAwayTestIds.homeName), 'Sunday Smashers');
    expect(name(CreateEventHomeAwayTestIds.awayName), 'Eagles');
    await _tap(tester, CreateEventHomeAwayTestIds.swap);
    expect(name(CreateEventHomeAwayTestIds.homeName), 'Eagles');
    expect(name(CreateEventHomeAwayTestIds.awayName), 'Sunday Smashers');

    await _tap(tester, CreateEventHomeAwayTestIds.notDecided);
    expect(_id(CreateEventHomeAwayTestIds.homeName), findsNothing);
    expect(_id(CreateEventHomeAwayTestIds.swap), findsNothing);
    await _tap(tester, CreateEventHomeAwayTestIds.next);
    expect(_id(CreateEventSettingsTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets('game against a team: assign our players now, create it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _toDynamics(tester);
    await _tap(
      tester,
      CreateEventTeamDynamicsTestIds.option('ott_specific_team'),
    );
    await _tap(tester, CreateEventTeamDynamicsTestIds.next);
    await _tap(tester, CreateEventOpponentSelectTestIds.team(44));
    await _tap(tester, CreateEventOpponentSelectTestIds.next);
    await _tap(tester, CreateEventHomeAwayTestIds.swap); // Eagles are home
    await _tap(tester, CreateEventHomeAwayTestIds.next);
    await _tap(tester, CreateEventSettingsTestIds.next);
    await _tap(tester, CreateEventMatchesTestIds.matchType(0, 'mt_singles'));
    await _tap(tester, CreateEventMatchesTestIds.next);
    await _throughWhenWhere(tester);
    await _tap(tester, CreateEventAssignTypeTestIds.assignNow);
    await _tap(tester, CreateEventAssignTypeTestIds.next);

    // The opponent side is not ours to fill.
    expect(
      find.text('The opponent team assigns its own players.'),
      findsOneWidget,
    );
    expect(
      _id(CreateEventAssignPlayersTestIds.slot(0, 'ecs_bottom', 'epp_center')),
      findsNothing,
    );
    await _tap(tester, CreateEventAssignPlayersTestIds.next);
    expect(_id(CreateEventAssignPlayersTestIds.error), findsOneWidget);
    await _tap(
      tester,
      CreateEventAssignPlayersTestIds.slot(0, 'ecs_top', 'epp_center'),
    );
    // Only our team's roster is offered.
    await _tap(tester, CreateEventSlotPickerTestIds.person(8));
    await _tap(tester, CreateEventAssignPlayersTestIds.next);

    expect(_id(CreateEventReviewTestIds.summaryOpponent), findsOneWidget);
    expect(find.text('Eagles (Home team)'), findsOneWidget);
    await _tap(tester, CreateEventReviewTestIds.create);

    final event = w.create.body!['event'] as Map<String, dynamic>;
    expect(event['originator_type'], 'Team');
    expect(event['opponent_team_type'], 'ott_specific_team');
    expect(event['event_teams_attributes'], [
      {
        'team_id': 31,
        'event_team_type': 'ett_visiting',
        'logged_in_user_belongs_to_team': true,
      },
      {
        'team_id': 44,
        'event_team_type': 'ett_home',
        'logged_in_user_belongs_to_team': false,
      },
    ]);
    final sides =
        (event['event_matches_attributes'] as List)
                .single['event_match_sides_attributes']
            as List;
    expect((sides[0] as Map)['team_id'], 31);
    expect((sides[1] as Map)['team_id'], 44);
    expect((sides[0] as Map)['event_participants'], [
      {'user_id': 8, 'position': 'epp_center'},
    ]);
    expect(event['players_limit'], 1);
    handle.dispose();
  });

  testWidgets('game against a named team: invite our players, create it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final w = _Wizard();
    await tester.pumpWidget(w.app());
    await _toDynamics(tester);
    await _tap(
      tester,
      CreateEventTeamDynamicsTestIds.option('ott_unknown_team_with_name'),
    );
    await tester.enterText(
      _field(CreateEventTeamDynamicsTestIds.name),
      'Eagles FC',
    );
    await tester.pump();
    await _tap(tester, CreateEventTeamDynamicsTestIds.next);
    await _tap(tester, CreateEventHomeAwayTestIds.next);
    await _tap(tester, CreateEventSettingsTestIds.next);
    await _tap(tester, CreateEventMatchesTestIds.matchType(0, 'mt_doubles'));
    await _tap(tester, CreateEventMatchesTestIds.next);
    await _throughWhenWhere(tester);
    await _tap(tester, CreateEventAssignTypeTestIds.next); // assign later

    // A doubles match needs two of our players against a named team.
    expect(_id(CreateEventInviteSettingsTestIds.root), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2));
    await _tap(tester, CreateEventInviteSettingsTestIds.next);
    await _tap(tester, CreateEventPlayersTestIds.player(8));
    await _tap(tester, CreateEventPlayersTestIds.next);
    expect(find.text('Eagles FC (Visiting team)'), findsOneWidget);
    await _tap(tester, CreateEventReviewTestIds.create);

    final event = w.create.body!['event'] as Map<String, dynamic>;
    expect(event['opponent_team_type'], 'ott_unknown_team_with_name');
    expect(event['opponent_team_name'], 'Eagles FC');
    expect(event['home_team_not_decided'], isFalse);
    expect((event['event_teams_attributes'] as List).last, {
      'event_team_type': 'ett_visiting',
      'logged_in_user_belongs_to_team': false,
    });
    expect(event['assign_type'], 'at_assign_later');
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'opponent steps meet contrast and tap-target guidelines ($mode)',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue =
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        useTallScreen(tester);
        await tester.pumpWidget(_Wizard().app());
        await _toDynamics(tester);

        Future<void> check() async {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        }

        await _tap(
          tester,
          CreateEventTeamDynamicsTestIds.option('ott_unknown_team_with_name'),
        );
        await _tap(tester, CreateEventTeamDynamicsTestIds.next); // name error
        await check(); // dynamics
        await tester.pageBack();
        await tester.pumpAndSettle();
        await _tap(tester, CreateEventTeamSelectTestIds.next);
        await _tap(
          tester,
          CreateEventTeamDynamicsTestIds.option('ott_specific_team'),
        );
        await _tap(tester, CreateEventTeamDynamicsTestIds.next);
        await _tap(tester, CreateEventOpponentSelectTestIds.next); // with error
        await check(); // opponent
        await _tap(tester, CreateEventOpponentSelectTestIds.team(44));
        await _tap(tester, CreateEventOpponentSelectTestIds.next);
        await check(); // home / visiting
        handle.dispose();
      },
    );
  }
}
