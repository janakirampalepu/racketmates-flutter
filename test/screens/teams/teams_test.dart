import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/create_team/create_team_test_ids.dart';
import 'package:racketmates/screens/create_team_members/create_team_members_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/teams/teams_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);
Finder _field(String id) =>
    find.descendant(of: _id(id), matching: find.byType(TextField));

const _smashers = Team(
  id: 31,
  name: 'Sunday Smashers',
  teamType: TeamTypes.competitive,
  teamPlayersCount: 12,
  teamSports: [
    TeamSport(id: 1, sportType: 'st_tennis'),
    TeamSport(id: 2, sportType: 'st_padel'),
  ],
);
const _casuals = Team(
  id: 32,
  name: 'Friday Casuals',
  teamType: TeamTypes.casual,
  memberCount: 1,
  teamSports: [TeamSport(id: 3, sportType: 'st_pickleball')],
);
const _alex = AppUser(id: 8, firstName: 'Alex', lastName: 'Kim');
const _pat = AppUser(id: 9, firstName: 'Pat', lastName: 'Lee');

/// An account that can play and coach, so both own-role switches show.
FakeUserRepository _playerAndCoach() => FakeUserRepository(
  profile: const UserDetails(
    user: AppUser(
      id: 7,
      userRoles: [
        UserRole(role: 'ur_player'),
        UserRole(role: 'ur_coach'),
      ],
    ),
  ),
);

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

Future<void> _openTeams(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await _tap(tester, MainShellTestIds.navTeams);
}

void main() {
  testWidgets('teams tab lists the signed-in user\'s teams', (tester) async {
    final handle = tester.ensureSemantics();
    final teams = FakeTeamsRepository(teams: [_smashers, _casuals]);
    await tester.pumpWidget(signedInApp(teams: teams));
    await _openTeams(tester);

    expect(teams.myTeamsRequests.single, ['7']);
    expect(_id(TeamsTestIds.tile(31)), findsOneWidget);
    expect(find.text('Sunday Smashers'), findsOneWidget);
    expect(
      find.text('Competitive · Tennis, Padel · 12 members'),
      findsOneWidget,
    );
    expect(find.text('Casual · Pickleball · 1 member'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no teams shows the empty state', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(signedInApp());
    await _openTeams(tester);
    expect(_id(TeamsTestIds.empty), findsOneWidget);
    expect(find.text('No teams yet'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a failed load can be retried', (tester) async {
    final handle = tester.ensureSemantics();
    final teams = FakeTeamsRepository(teams: [_smashers])..failing = true;
    await tester.pumpWidget(signedInApp(teams: teams));
    await _openTeams(tester);
    expect(_id(TeamsTestIds.error), findsOneWidget);
    teams.failing = false;
    await _tap(tester, TeamsTestIds.retry);
    expect(_id(TeamsTestIds.tile(31)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a team opens with its members and roles', (tester) async {
    final handle = tester.ensureSemantics();
    final teams = FakeTeamsRepository(
      teams: [_smashers],
      membersByTeam: {
        31: const [
          TeamPlayer(
            id: 501,
            userId: 8,
            isCaptain: true,
            isPlayer: true,
            user: _alex,
          ),
          TeamPlayer(id: 502, userId: 9, isCoach: true, user: _pat),
        ],
      },
    );
    await tester.pumpWidget(signedInApp(teams: teams));
    await _openTeams(tester);
    await _tap(tester, TeamsTestIds.tile(31));

    expect(_id(TeamDetailsTestIds.root), findsOneWidget);
    expect(find.text('Sunday Smashers'), findsOneWidget);
    expect(find.textContaining('Tennis, Padel'), findsOneWidget);
    await _tap(tester, TeamDetailsTestIds.tabMembers);
    expect(find.text('Alex Kim'), findsOneWidget);
    expect(find.text('Captain, Player'), findsOneWidget);
    expect(find.text('Coach'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('team details: no members and load failures', (tester) async {
    final handle = tester.ensureSemantics();
    final teams = FakeTeamsRepository(teams: [_smashers])..membersFail = true;
    await tester.pumpWidget(signedInApp(teams: teams));
    await _openTeams(tester);
    await _tap(tester, TeamsTestIds.tile(31));
    await _tap(tester, TeamDetailsTestIds.tabMembers);
    expect(_id(TeamDetailsTestIds.membersError), findsOneWidget);
    teams.membersFail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(_id(TeamDetailsTestIds.membersEmpty), findsOneWidget);
    handle.dispose();
  });

  testWidgets('create team: validation, members, request', (tester) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final teams = FakeTeamsRepository();
    final repo = FakeCreateEventRepository(players: [_alex, _pat]);
    await tester.pumpWidget(
      signedInApp(teams: teams, createEvent: repo, users: _playerAndCoach()),
    );
    await _openTeams(tester);
    await _tap(tester, TeamsTestIds.create);

    // Nothing filled in: all three errors.
    await _tap(tester, CreateTeamTestIds.next);
    expect(_id(CreateTeamTestIds.nameError), findsOneWidget);
    expect(_id(CreateTeamTestIds.typeError), findsOneWidget);
    expect(_id(CreateTeamTestIds.sportError), findsOneWidget);
    expect(_id(CreateTeamTestIds.root), findsOneWidget);

    await tester.enterText(_field(CreateTeamTestIds.name), 'Net Ninjas');
    await tester.pump();
    expect(_id(CreateTeamTestIds.nameError), findsNothing);
    await _tap(tester, CreateTeamTestIds.type(TeamTypes.competitive));
    expect(_id(CreateTeamTestIds.typeError), findsNothing);
    await _tap(tester, CreateTeamTestIds.sport('st_tennis'));
    await _tap(tester, CreateTeamTestIds.sport('st_padel'));
    await _tap(tester, CreateTeamTestIds.ranking);
    await _tap(tester, CreateTeamTestIds.selfPlayer);
    await _tap(tester, CreateTeamTestIds.next);

    // Members are searched by the team's sports.
    expect(_id(CreateTeamMembersTestIds.root), findsOneWidget);
    expect(repo.searches.first.role, isNull);
    await _tap(tester, CreateTeamMembersTestIds.role(8, 'player'));
    await _tap(tester, CreateTeamMembersTestIds.role(9, 'coach'));
    await _tap(tester, CreateTeamMembersTestIds.role(9, 'captain'));
    await _tap(tester, CreateTeamMembersTestIds.create);

    expect(teams.created, {
      'team': {
        'name': 'Net Ninjas',
        'team_type': 'tt_competitive',
        'enable_player_ranking': true,
        'team_sports_attributes': [
          {'sport_type': 'st_tennis'},
          {'sport_type': 'st_padel'},
        ],
        'team_players_attributes': [
          {
            'user_id': 7,
            'is_captain': true,
            'is_player': true,
            'is_coach': false,
          },
          {
            'user_id': 8,
            'is_captain': false,
            'is_player': true,
            'is_coach': false,
          },
          {
            'user_id': 9,
            'is_captain': true,
            'is_player': false,
            'is_coach': true,
          },
        ],
      },
    });
    // Back on the teams tab, which reloaded, with a confirmation.
    expect(_id(TeamsTestIds.root), findsOneWidget);
    expect(teams.myTeamsRequests, hasLength(2));
    expect(find.text('Team created.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('own-role switches only show for roles on the account', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    await tester.pumpWidget(signedInApp()); // the default account has no roles
    await _openTeams(tester);
    await _tap(tester, TeamsTestIds.create);
    expect(_id(CreateTeamTestIds.selfPlayer), findsNothing);
    expect(_id(CreateTeamTestIds.selfCoach), findsNothing);
    handle.dispose();
  });

  testWidgets('create team: a rejected request shows the server message', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useTallScreen(tester);
    final teams = FakeTeamsRepository()
      ..createFailure = const ServerFailure(422, 'Name has already been taken');
    await tester.pumpWidget(signedInApp(teams: teams));
    await _openTeams(tester);
    await _tap(tester, TeamsTestIds.create);
    await tester.enterText(_field(CreateTeamTestIds.name), 'Net Ninjas');
    await _tap(tester, CreateTeamTestIds.type(TeamTypes.casual));
    await _tap(tester, CreateTeamTestIds.sport('st_tennis'));
    await _tap(tester, CreateTeamTestIds.next);
    await _tap(tester, CreateTeamMembersTestIds.create);
    expect(_id(CreateTeamMembersTestIds.error), findsOneWidget);
    expect(find.text('Name has already been taken'), findsOneWidget);
    expect(_id(CreateTeamMembersTestIds.root), findsOneWidget);
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'team screens meet contrast and tap-target guidelines ($mode)',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue =
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        useTallScreen(tester);
        final teams = FakeTeamsRepository(
          teams: [_smashers, _casuals],
          membersByTeam: {
            31: const [
              TeamPlayer(id: 501, userId: 8, isCaptain: true, user: _alex),
            ],
          },
        );
        await tester.pumpWidget(
          signedInApp(
            teams: teams,
            createEvent: FakeCreateEventRepository(players: [_alex, _pat]),
          ),
        );
        await _openTeams(tester);

        Future<void> check() async {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        }

        await check(); // list
        await _tap(tester, TeamsTestIds.tile(31));
        await check(); // details
        await tester.pageBack();
        await tester.pumpAndSettle();
        await _tap(tester, TeamsTestIds.create);
        await _tap(tester, CreateTeamTestIds.next); // with errors
        await check(); // form
        await tester.enterText(_field(CreateTeamTestIds.name), 'X');
        await _tap(tester, CreateTeamTestIds.type(TeamTypes.casual));
        await _tap(tester, CreateTeamTestIds.sport('st_tennis'));
        await _tap(tester, CreateTeamTestIds.next);
        await check(); // members
        handle.dispose();
      },
    );
  }
}
