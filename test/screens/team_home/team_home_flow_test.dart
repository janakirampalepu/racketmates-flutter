import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/subscription/subscription_test_ids.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/team_details/team_members_tab.dart';
import 'package:racketmates/screens/team_details/team_rankings_tab.dart';
import 'package:racketmates/screens/teams/teams_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

/// Scopes a text finder to the pushed full member list, since the
/// dashboard's `TeamMembersPreview` (left mounted underneath the push) can
/// show the same member names/roles.
Finder _inMembers(Finder matching) =>
    find.descendant(of: find.byType(TeamMembersTab), matching: matching);

/// Same idea for the pushed rankings screen.
Finder _inRankings(Finder matching) =>
    find.descendant(of: find.byType(TeamRankingsTab), matching: matching);

const _alex = AppUser(id: 8, uid: 'u8', firstName: 'Alex', lastName: 'Kim');
const _pat = AppUser(id: 9, uid: 'u9', firstName: 'Pat', lastName: 'Ng');
const _sam = AppUser(id: 7, uid: 'uid-7', firstName: 'Sam', lastName: 'Lee');

const _all = {
  'team.team_players.update': AccessInfo(access: 'up_enabled'),
  'team.team_players.inactivate': AccessInfo(access: 'up_enabled'),
  'team.team_players.reactivate': AccessInfo(access: 'up_enabled'),
  'team.team_players.destroy': AccessInfo(access: 'up_enabled'),
  'team.team_players.create': AccessInfo(access: 'up_enabled'),
};

Team _team({
  Map<String, AccessInfo>? permissions = _all,
  bool ranking = true,
  bool archived = false,
}) => Team(
  id: 31,
  name: 'Sunday Smashers',
  teamType: TeamTypes.competitive,
  archived: archived,
  enablePlayerRanking: ranking,
  teamSports: const [
    TeamSport(id: 1, sportType: 'st_tennis'),
    TeamSport(id: 2, sportType: 'st_padel'),
  ],
  userPermissions: permissions,
);

const _captain = TeamPlayer(
  id: 500,
  userId: 7,
  isCaptain: true,
  isPlayer: true,
  user: _sam,
);
const _alexPlayer = TeamPlayer(id: 501, userId: 8, isPlayer: true, user: _alex);
const _patCoach = TeamPlayer(id: 502, userId: 9, isCoach: true, user: _pat);

const _reference = [
  {
    'id': 1,
    'data_type': 'ranking_period_duration',
    'key': 'rpd_all_time',
    'localized_label': 'All time',
  },
  {
    'id': 2,
    'data_type': 'ranking_period_duration',
    'key': 'rpd_this_year',
    'localized_label': 'This year',
  },
  {
    'id': 3,
    'data_type': 'match_type',
    'key': 'mt_singles',
    'localized_label': 'Singles',
  },
  {
    'id': 4,
    'data_type': 'match_type',
    'key': 'mt_doubles',
    'localized_label': 'Doubles',
  },
];

Future<void> _openTeam(
  WidgetTester tester, {
  required FakeTeamsRepository teams,
  FakeScheduleRepository? schedule,
  FakeSessionInfoRepository? sessionInfo,
}) async {
  await tester.pumpWidget(
    signedInApp(
      teams: teams,
      schedule: schedule,
      sessionInfo: sessionInfo,
      content: FakeContentRepository(reference: _reference),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(_id(MainShellTestIds.navTeams));
  await tester.pumpAndSettle();
  await tester.tap(_id(TeamsTestIds.tile(31)));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

FakeTeamsRepository _repo({
  Team? team,
  List<TeamPlayer> members = const [_captain, _alexPlayer, _patCoach],
}) =>
    FakeTeamsRepository(teams: [team ?? _team()], membersByTeam: {31: members});

void main() {
  group('dashboard', () {
    testWidgets('upcoming events of the team, opening one', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final schedule = FakeScheduleRepository()
        ..upcoming = const [
          ScheduleItem(
            eventId: 101,
            eventDate: '2026-11-02',
            eventType: 'et_practice',
            placeName: 'Central Courts',
            timeSlot: '7-8 PM',
          ),
        ]
        ..event = const EventDetails(id: 101, eventType: 'et_practice');
      await _openTeam(tester, teams: _repo(), schedule: schedule);
      // The dashboard's Upcoming section, team-scoped (native
      // `HomeFragmentViewModel` parameterized by this team, same as Home).
      expect(schedule.upcomingTeamId, 31);
      expect(find.textContaining('Central Courts'), findsOneWidget);
      await tester.tap(_id(TeamHomeActionIds.upcomingEvent(101)));
      await tester.pumpAndSettle();
      expect(_id(EventDetailsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('pending actions of the team are team-scoped', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final schedule = FakeScheduleRepository();
      await _openTeam(tester, teams: _repo(), schedule: schedule);
      expect(schedule.pendingTeamId, 31);
      expect(schedule.activityTeamId, 31);
      handle.dispose();
    });
  });

  group('full schedule screen', () {
    testWidgets('past events, empty and failing states', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final schedule = FakeScheduleRepository();
      await _openTeam(tester, teams: _repo(), schedule: schedule);
      await _tap(tester, TeamHomeActionIds.upcomingSeeAll);
      expect(_id(TeamDetailsTestIds.scheduleEmpty), findsOneWidget);
      schedule.failing.add('page-past');
      await _tap(tester, TeamDetailsTestIds.schedulePast);
      expect(_id(TeamDetailsTestIds.scheduleError), findsOneWidget);
      schedule.failing.clear();
      await _tap(tester, TeamDetailsTestIds.scheduleRetry);
      expect(_id(TeamDetailsTestIds.scheduleEmpty), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an archived team opens on its past events', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final schedule = FakeScheduleRepository();
      await _openTeam(
        tester,
        teams: _repo(team: _team(archived: true)),
        schedule: schedule,
      );
      await _tap(tester, TeamHomeActionIds.upcomingSeeAll);
      expect(schedule.calls, contains('page-past'));
      expect(schedule.calls, isNot(contains('page-upcoming')));
      handle.dispose();
    });
  });

  group('rankings', () {
    TeamPlayer ranked(int id, AppUser u, int rank, int? before, int pts) =>
        TeamPlayer(
          id: id,
          user: u,
          currentRank: rank,
          previousRank: before,
          wins: 3,
          losses: 1,
          totalPoints: pts,
        );

    testWidgets('shows the table for the first sport and period', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo()
        ..ranking = [
          ranked(501, _alex, 1, 3, 120),
          ranked(502, _pat, 2, 1, 90),
        ];
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamDetailsTestIds.tabRankings);
      expect(teams.rankingRequests.last, (
        team: 31,
        sport: 'st_tennis',
        period: 'rpd_all_time',
        matchType: null,
      ));
      expect(_inRankings(find.text('Alex Kim')), findsOneWidget);
      expect(find.text('3W - 1L · 120 pts'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      handle.dispose();
    });

    testWidgets('changing sport and match type asks again', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo();
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamDetailsTestIds.tabRankings);
      await _tap(tester, TeamDetailsTestIds.rankingSport('st_padel'));
      expect(teams.rankingRequests.last.sport, 'st_padel');
      await _tap(tester, TeamDetailsTestIds.rankingMatch('mt_doubles'));
      expect(teams.rankingRequests.last.matchType, 'mt_doubles');
      await _tap(tester, TeamDetailsTestIds.rankingMatch('all'));
      expect(teams.rankingRequests.last.matchType, isNull);
      expect(_id(TeamDetailsTestIds.rankingsEmpty), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a failing table can be retried', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo()..rankingFails = true;
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamDetailsTestIds.tabRankings);
      expect(_id(TeamDetailsTestIds.rankingsError), findsOneWidget);
      teams
        ..rankingFails = false
        ..ranking = [ranked(501, _alex, 1, null, 10)];
      await _tap(tester, TeamDetailsTestIds.rankingsRetry);
      expect(_inRankings(find.text('Alex Kim')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('no ranking tab when the team has none', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openTeam(tester, teams: _repo(team: _team(ranking: false)));
      expect(_id(TeamDetailsTestIds.tabRankings), findsNothing);
      handle.dispose();
    });
  });

  group('members', () {
    Future<void> openMenu(WidgetTester tester, int id, String action) async {
      await _tap(tester, TeamDetailsTestIds.memberActions(id));
      await _tap(tester, action);
    }

    testWidgets('roles are edited and saved', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo();
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await openMenu(tester, 501, TeamDetailsTestIds.actionEdit);
      expect(_id(TeamDetailsTestIds.rolesDialog), findsOneWidget);
      await _tap(tester, TeamDetailsTestIds.rolesCoach);
      await _tap(tester, TeamDetailsTestIds.rolesSave);
      expect(teams.memberCalls, ['roles:31:501:-op']);
      expect(_inMembers(find.text('Player, Coach')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a member must keep a role', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo();
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await openMenu(tester, 501, TeamDetailsTestIds.actionEdit);
      await _tap(tester, TeamDetailsTestIds.rolesPlayer);
      await _tap(tester, TeamDetailsTestIds.rolesSave);
      expect(_id(TeamDetailsTestIds.rolesError), findsOneWidget);
      expect(teams.memberCalls, isEmpty);
      handle.dispose();
    });

    testWidgets('the only captain cannot lose the role', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo();
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await openMenu(tester, 500, TeamDetailsTestIds.actionEdit);
      await _tap(tester, TeamDetailsTestIds.rolesCaptain);
      await _tap(tester, TeamDetailsTestIds.rolesSave);
      expect(_id(TeamDetailsTestIds.rolesError), findsOneWidget);
      expect(teams.memberCalls, isEmpty);
      handle.dispose();
    });

    testWidgets('deactivating asks first and shows the member as deactivated', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo();
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await openMenu(tester, 501, TeamDetailsTestIds.actionDeactivate);
      await _tap(tester, TeamDetailsTestIds.confirmNo);
      expect(teams.memberCalls, isEmpty);
      await openMenu(tester, 501, TeamDetailsTestIds.actionDeactivate);
      await _tap(tester, TeamDetailsTestIds.confirmYes);
      expect(teams.memberCalls, ['inactivate:31:501']);
      // active members only (also true of the dashboard preview, so this
      // one is safe unscoped: neither shows Alex).
      expect(find.text('Alex Kim'), findsNothing);
      await _tap(tester, TeamDetailsTestIds.showInactive);
      expect(_inMembers(find.text('Alex Kim')), findsOneWidget);
      expect(_inMembers(find.textContaining('Deactivated')), findsOneWidget);
      await openMenu(tester, 501, TeamDetailsTestIds.actionReactivate);
      await _tap(tester, TeamDetailsTestIds.confirmYes);
      expect(teams.memberCalls.last, 'reactivate:31:501');
      expect(_inMembers(find.textContaining('Deactivated')), findsNothing);
      handle.dispose();
    });

    testWidgets('removing a member', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo();
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await openMenu(tester, 502, TeamDetailsTestIds.actionRemove);
      await _tap(tester, TeamDetailsTestIds.confirmYes);
      expect(teams.memberCalls, ['remove:31:502']);
      expect(find.text('Pat Ng'), findsNothing);
      handle.dispose();
    });

    testWidgets('the only captain cannot be deactivated or removed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo();
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await openMenu(tester, 500, TeamDetailsTestIds.actionDeactivate);
      expect(find.textContaining('needs a captain'), findsOneWidget);
      await _tap(tester, TeamDetailsTestIds.accessDialogClose);
      await openMenu(tester, 500, TeamDetailsTestIds.actionRemove);
      expect(find.textContaining('needs a captain'), findsOneWidget);
      await _tap(tester, TeamDetailsTestIds.accessDialogClose);
      expect(teams.memberCalls, isEmpty);
      handle.dispose();
    });

    testWidgets('a rejected change says so and keeps the member', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo()..changeFailure = const OfflineFailure();
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await openMenu(tester, 502, TeamDetailsTestIds.actionRemove);
      await _tap(tester, TeamDetailsTestIds.confirmYes);
      expect(
        find.text('The change could not be saved. Please try again.'),
        findsOneWidget,
      );
      expect(_inMembers(find.text('Pat Ng')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('without permissions there are no actions or add button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openTeam(
        tester,
        teams: _repo(team: _team(permissions: const {})),
      );
      await _tap(tester, TeamHomeActionIds.manageMembers);
      expect(_inMembers(find.text('Alex Kim')), findsOneWidget);
      expect(_id(TeamDetailsTestIds.memberActions(501)), findsNothing);
      expect(_id(TeamDetailsTestIds.addMembers), findsNothing);
      handle.dispose();
    });

    testWidgets('a disabled action explains itself', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo(
        team: _team(
          permissions: const {
            'team.team_players.destroy': AccessInfo(
              access: 'up_disabled',
              message: 'Members cannot be removed during a season.',
            ),
          },
        ),
      );
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await openMenu(tester, 502, TeamDetailsTestIds.actionRemove);
      expect(
        find.text('Members cannot be removed during a season.'),
        findsOneWidget,
      );
      expect(teams.memberCalls, isEmpty);
      handle.dispose();
    });

    testWidgets('an action that needs a subscription offers the plans', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo(
        team: _team(
          permissions: const {
            'team.team_players.destroy': AccessInfo(
              access: 'up_requires_subscription',
            ),
          },
        ),
      );
      await _openTeam(
        tester,
        teams: teams,
        sessionInfo: FakeSessionInfoRepository(
          response: const SessionInfoResponse(
            user: SessionInfoUser(
              id: 7,
              hasFullFeatureAccess: false,
              trialRemainingDays: 30,
              timezoneIdentifier: 'America/New_York',
            ),
          ),
        ),
      );
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await openMenu(tester, 502, TeamDetailsTestIds.actionRemove);
      expect(_id(SubscriptionTestIds.root), findsOneWidget);
      expect(teams.memberCalls, isEmpty);
      handle.dispose();
    });
  });

  group('add members', () {
    testWidgets('search, choose roles, add', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo()..candidates = const [_alex, _pat];
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await _tap(tester, TeamDetailsTestIds.addMembers);
      expect(_id(TeamAddMembersTestIds.root), findsOneWidget);
      expect(teams.candidateSearches.last.sports, ['st_tennis', 'st_padel']);
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: _id(TeamAddMembersTestIds.save),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await _tap(tester, TeamAddMembersTestIds.role(8, 'player'));
      await _tap(tester, TeamAddMembersTestIds.role(9, 'coach'));
      await _tap(tester, TeamAddMembersTestIds.role(9, 'captain'));
      await _tap(tester, TeamAddMembersTestIds.save);
      expect(teams.memberCalls, ['add:31:8p,9co']);
      expect(_id(TeamAddMembersTestIds.root), findsNothing);
      expect(find.text('Members added.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a person left with no role is dropped', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo()..candidates = const [_alex];
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await _tap(tester, TeamDetailsTestIds.addMembers);
      await _tap(tester, TeamAddMembersTestIds.role(8, 'player'));
      await _tap(tester, TeamAddMembersTestIds.role(8, 'player'));
      final save = tester.widget<FilledButton>(
        find.descendant(
          of: _id(TeamAddMembersTestIds.save),
          matching: find.byType(FilledButton),
        ),
      );
      expect(save.onPressed, isNull);
      handle.dispose();
    });

    testWidgets('a failing add keeps the choice', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo()
        ..candidates = const [_alex]
        ..changeFailure = const OfflineFailure();
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await _tap(tester, TeamDetailsTestIds.addMembers);
      await _tap(tester, TeamAddMembersTestIds.role(8, 'player'));
      await _tap(tester, TeamAddMembersTestIds.save);
      expect(_id(TeamAddMembersTestIds.failed), findsOneWidget);
      expect(_id(TeamAddMembersTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('nobody found and a failing search', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = _repo();
      await _openTeam(tester, teams: teams);
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await _tap(tester, TeamDetailsTestIds.addMembers);
      expect(_id(TeamAddMembersTestIds.empty), findsOneWidget);
      teams.membersFail = true;
      await tester.enterText(find.byType(TextField), 'x');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(_id(TeamAddMembersTestIds.error), findsOneWidget);
      handle.dispose();
    });
  });

  for (final dark in [false, true]) {
    testWidgets('team home meets guidelines (${dark ? 'dark' : 'light'})', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _openTeam(tester, teams: _repo());
      await _tap(tester, TeamHomeActionIds.manageMembers);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
