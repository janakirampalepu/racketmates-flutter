import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/widgets/sport_select_row.dart';
import 'package:racketmates/screens/create_event_sport/create_event_sport_test_ids.dart';
import 'package:racketmates/screens/create_event_settings/create_event_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_team_choice/create_event_team_choice_test_ids.dart';
import 'package:racketmates/screens/create_event_type/create_event_type_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/subscription/subscription_test_ids.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/team_shell/team_shell_test_ids.dart';
import 'package:racketmates/screens/teams/teams_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

const _perms = {
  'team.settings': AccessInfo(access: 'up_enabled'),
  'team.archive': AccessInfo(access: 'up_enabled'),
  'team.unarchive': AccessInfo(access: 'up_enabled'),
  'team.destroy': AccessInfo(access: 'up_enabled'),
  'team.events.create': AccessInfo(access: 'up_enabled'),
};

Team _team({
  Map<String, AccessInfo>? permissions = _perms,
  bool archived = false,
}) => Team(
  id: 31,
  name: 'Sunday Smashers',
  teamType: TeamTypes.competitive,
  archived: archived,
  enablePlayerRanking: false,
  teamSports: const [
    TeamSport(id: 1, sportType: 'st_tennis'),
    TeamSport(id: 2, sportType: 'st_padel'),
  ],
  userPermissions: permissions,
);

Future<FakeTeamsRepository> _openTeam(
  WidgetTester tester, {
  Team? team,
  FakeSessionInfoRepository? sessionInfo,
}) async {
  final teams = FakeTeamsRepository(teams: [team ?? _team()]);
  await tester.pumpWidget(signedInApp(teams: teams, sessionInfo: sessionInfo));
  await tester.pumpAndSettle();
  await tester.tap(_id(MainShellTestIds.navTeams));
  await tester.pumpAndSettle();
  await tester.tap(_id(TeamsTestIds.tile(31)));
  await tester.pumpAndSettle();
  return teams;
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.tap(_id(id));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) =>
    _tap(tester, TeamHomeActionIds.settingsButton);

/// Create event now lives on Team Schedule, not Team Home.
Future<void> _openTeamSchedule(WidgetTester tester) =>
    _tap(tester, TeamShellTestIds.navSchedule);

/// Opens the archive/delete overflow sheet (the "⋮" in the settings
/// toolbar) before tapping one of its rows.
Future<void> _openActionsMenu(WidgetTester tester) =>
    _tap(tester, TeamSettingsTestIds.actionsMenu);

SessionInfoResponse _free() => const SessionInfoResponse(
  user: SessionInfoUser(
    id: 7,
    hasFullFeatureAccess: false,
    trialRemainingDays: 30,
    timezoneIdentifier: 'America/New_York',
  ),
);

void main() {
  group('team settings', () {
    testWidgets('shows the team as it is', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openTeam(tester);
      await _openSettings(tester);
      expect(_id(TeamSettingsTestIds.root), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: _id(TeamSettingsTestIds.name),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'Sunday Smashers',
      );
      final tennis = tester
          .widgetList<SportSelectRow>(find.byType(SportSelectRow))
          .firstWhere(
            (w) => w.testId == TeamSettingsTestIds.sport('st_tennis'),
          );
      expect(tennis.selected, isTrue);
      handle.dispose();
    });

    testWidgets('saving sends the changes and returns to the team', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = await _openTeam(tester);
      await _openSettings(tester);
      await tester.enterText(
        find.descendant(
          of: _id(TeamSettingsTestIds.name),
          matching: find.byType(TextField),
        ),
        'Net Ninjas',
      );
      await _tap(tester, TeamSettingsTestIds.type('tt_casual'));
      await _tap(tester, TeamSettingsTestIds.sport('st_padel'));
      await _tap(tester, TeamSettingsTestIds.ranking);
      await _tap(tester, TeamSettingsTestIds.save);
      expect(teams.teamCalls, ['update:31']);
      expect(teams.updatedBody, {
        'team': {
          'id': 31,
          'name': 'Net Ninjas',
          'team_type': 'tt_casual',
          'enable_player_ranking': true,
          'team_sports_attributes': [
            {'id': 1, 'sport_type': 'st_tennis'},
            {'id': 2, 'sport_type': 'st_padel', '_destroy': true},
          ],
        },
      });
      expect(_id(TeamSettingsTestIds.root), findsNothing);
      expect(find.text('Net Ninjas'), findsWidgets);
      expect(find.text('Team updated.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('missing name, type or sport are reported', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = await _openTeam(tester);
      await _openSettings(tester);
      await tester.enterText(
        find.descendant(
          of: _id(TeamSettingsTestIds.name),
          matching: find.byType(TextField),
        ),
        '',
      );
      await _tap(tester, TeamSettingsTestIds.sport('st_tennis'));
      await _tap(tester, TeamSettingsTestIds.sport('st_padel'));
      await _tap(tester, TeamSettingsTestIds.save);
      expect(_id(TeamSettingsTestIds.nameError), findsOneWidget);
      expect(_id(TeamSettingsTestIds.sportError), findsOneWidget);
      expect(teams.teamCalls, isEmpty);
      await _tap(tester, TeamSettingsTestIds.sport('st_tennis'));
      expect(_id(TeamSettingsTestIds.sportError), findsNothing);
      handle.dispose();
    });

    testWidgets('a failing save keeps the form', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = await _openTeam(tester);
      teams.teamChangeFailure = const OfflineFailure();
      await _openSettings(tester);
      await _tap(tester, TeamSettingsTestIds.save);
      expect(_id(TeamSettingsTestIds.failed), findsOneWidget);
      expect(_id(TeamSettingsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('archiving asks, archives and shows the banner', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = await _openTeam(tester);
      await _openSettings(tester);
      await _openActionsMenu(tester);
      await _tap(tester, TeamSettingsTestIds.archive);
      await _tap(tester, TeamSettingsTestIds.confirmNo);
      expect(teams.teamCalls, isEmpty);
      await _openActionsMenu(tester);
      await _tap(tester, TeamSettingsTestIds.archive);
      await _tap(tester, TeamSettingsTestIds.confirmYes);
      expect(teams.teamCalls, ['archive:31']);
      expect(_id(TeamHomeActionIds.archivedBanner), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an archived team is unarchived from the banner', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = await _openTeam(tester, team: _team(archived: true));
      expect(_id(TeamHomeActionIds.archivedBanner), findsOneWidget);
      await _tap(tester, TeamHomeActionIds.unarchiveButton);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(teams.teamCalls, ['unarchive:31']);
      expect(_id(TeamHomeActionIds.archivedBanner), findsNothing);
      handle.dispose();
    });

    testWidgets('an archived team is unarchived from its settings', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = await _openTeam(tester, team: _team(archived: true));
      await _openSettings(tester);
      await _openActionsMenu(tester);
      expect(_id(TeamSettingsTestIds.archive), findsNothing);
      await _tap(tester, TeamSettingsTestIds.unarchive);
      await _tap(tester, TeamSettingsTestIds.confirmYes);
      expect(teams.teamCalls, ['unarchive:31']);
      expect(_id(TeamHomeActionIds.archivedBanner), findsNothing);
      handle.dispose();
    });

    testWidgets('deleting asks, deletes and leaves for the teams list', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = await _openTeam(tester);
      await _openSettings(tester);
      await _openActionsMenu(tester);
      await _tap(tester, TeamSettingsTestIds.delete);
      await _tap(tester, TeamSettingsTestIds.confirmYes);
      expect(teams.teamCalls, ['delete:31']);
      expect(_id(TeamsTestIds.root), findsOneWidget);
      expect(_id(TeamsTestIds.tile(31)), findsNothing);
      expect(find.text('Team deleted.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a failing delete keeps the team', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final teams = await _openTeam(tester);
      await _openSettings(tester);
      teams.teamChangeFailure = const OfflineFailure();
      await _openActionsMenu(tester);
      await _tap(tester, TeamSettingsTestIds.delete);
      await _tap(tester, TeamSettingsTestIds.confirmYes);
      expect(_id(TeamSettingsTestIds.actionFailed), findsOneWidget);
      expect(_id(TeamSettingsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('only the permitted actions are offered', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openTeam(
        tester,
        team: _team(
          permissions: const {
            'team.settings': AccessInfo(access: 'up_enabled'),
          },
        ),
      );
      await _openSettings(tester);
      // No archive/destroy permission at all: the overflow menu itself
      // isn't offered (native shows no "⋮" when it would be empty).
      expect(_id(TeamSettingsTestIds.actionsMenu), findsNothing);
      handle.dispose();
    });

    testWidgets('without the settings permission there is no entry', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openTeam(tester, team: _team(permissions: const {}));
      expect(_id(TeamHomeActionIds.settingsButton), findsNothing);
      await _openTeamSchedule(tester);
      expect(_id(TeamDetailsTestIds.scheduleCreateEvent), findsNothing);
      handle.dispose();
    });

    testWidgets('a disabled settings entry explains itself', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openTeam(
        tester,
        team: _team(
          permissions: const {
            'team.settings': AccessInfo(
              access: 'up_disabled',
              message: 'Settings are locked this season.',
            ),
          },
        ),
      );
      await _openSettings(tester);
      expect(find.text('Settings are locked this season.'), findsOneWidget);
      expect(_id(TeamSettingsTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets('settings that need a subscription offer the plans', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openTeam(
        tester,
        team: _team(
          permissions: const {
            'team.settings': AccessInfo(access: 'up_requires_subscription'),
          },
        ),
        sessionInfo: FakeSessionInfoRepository(response: _free()),
      );
      await _openSettings(tester);
      expect(_id(SubscriptionTestIds.root), findsOneWidget);
      handle.dispose();
    });

    for (final dark in [false, true]) {
      testWidgets('meets guidelines (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await _openTeam(tester);
        await _openSettings(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('create event from the team', () {
    testWidgets('the wizard starts for the team without asking about teams', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openTeam(tester);
      await _openTeamSchedule(tester);
      await _tap(tester, TeamDetailsTestIds.scheduleCreateEvent);
      expect(_id(CreateEventTypeTestIds.root), findsOneWidget);
      // Team events only: no individual lesson or ball machine.
      expect(
        _id(CreateEventTypeTestIds.type('et_individual_lesson')),
        findsNothing,
      );
      expect(
        _id(CreateEventTypeTestIds.type('et_practice_ball')),
        findsNothing,
      );
      await _tap(tester, CreateEventTypeTestIds.type('et_practice_drill'));
      // Only the sports the team plays.
      expect(_id(CreateEventSportTestIds.sport('st_tennis')), findsOneWidget);
      expect(_id(CreateEventSportTestIds.sport('st_padel')), findsOneWidget);
      expect(_id(CreateEventSportTestIds.sport('st_pickleball')), findsNothing);
      await _tap(tester, CreateEventSportTestIds.sport('st_tennis'));
      await _tap(tester, CreateEventSportTestIds.next);
      expect(_id(CreateEventTeamChoiceTestIds.root), findsNothing);
      expect(_id(CreateEventSettingsTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an archived team cannot get events', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openTeam(tester, team: _team(archived: true));
      await _openTeamSchedule(tester);
      await _tap(tester, TeamDetailsTestIds.scheduleCreateEvent);
      expect(
        find.textContaining('archived team cannot get new events'),
        findsOneWidget,
      );
      expect(_id(CreateEventTypeTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets('a disabled create-event permission explains itself', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await _openTeam(
        tester,
        team: _team(
          permissions: const {
            'team.events.create': AccessInfo(
              access: 'up_disabled',
              message: 'Ask the captain.',
            ),
          },
        ),
      );
      await _openTeamSchedule(tester);
      await _tap(tester, TeamDetailsTestIds.scheduleCreateEvent);
      expect(find.text('Ask the captain.'), findsOneWidget);
      expect(_id(CreateEventTypeTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets(
      'a create-event permission that needs a subscription offers it',
      (tester) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        await _openTeam(
          tester,
          team: _team(
            permissions: const {
              'team.events.create': AccessInfo(
                access: 'up_requires_subscription',
              ),
            },
          ),
          sessionInfo: FakeSessionInfoRepository(response: _free()),
        );
        await _openTeamSchedule(tester);
        await _tap(tester, TeamDetailsTestIds.scheduleCreateEvent);
        expect(_id(SubscriptionTestIds.root), findsOneWidget);
        handle.dispose();
      },
    );
  });
}
