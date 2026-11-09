import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/schedule_filter.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_members_screen.dart';
import 'package:racketmates/screens/team_details/team_rankings_screen.dart';
import 'package:racketmates/screens/team_details/team_schedule_screen.dart';

import '../../support/fakes.dart';

/// Isolated widget tests for the 3 thin `TeamDetailsScreen` destination
/// screens that each watch `teamDetailsProvider` on their own (members,
/// rankings, schedule): confirm a real failure's message replaces the
/// generic `teamDetailsLoadError` text instead of being discarded. These
/// screens are pushed from Team Home only once that same provider has
/// already resolved successfully there, so a failing fetch can't be
/// reached through the full app flow — tested here in isolation instead,
/// the same pattern `place_picker_test.dart` uses.
Team _team() => const Team(
  id: 31,
  name: 'Sunday Smashers',
  teamType: TeamTypes.competitive,
  teamSports: [TeamSport(id: 1, sportType: 'st_tennis')],
);

Widget _host(FakeTeamsRepository repo, Widget screen) => ProviderScope(
  overrides: [
    teamsRepositoryProvider.overrideWithValue(repo),
    scheduleFilterStoreProvider(true)
        .overrideWithValue(InMemoryScheduleFilterStore()),
  ],
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: screen,
  ),
);

void main() {
  for (final entry in {
    'TeamMembersScreen': const TeamMembersScreen(teamId: 31),
    'TeamRankingsScreen': const TeamRankingsScreen(teamId: 31),
    'TeamScheduleScreen': const TeamScheduleScreen(teamId: 31),
  }.entries) {
    testWidgets(
      '${entry.key}: a server failure message replaces the generic text',
      (tester) async {
        final handle = tester.ensureSemantics();
        final repo = FakeTeamsRepository(teams: [_team()])
          ..detailsFailure = const ServerFailure(500, 'Team not available.');
        await tester.pumpWidget(_host(repo, entry.value));
        await tester.pumpAndSettle();
        expect(find.text('Team not available.'), findsOneWidget);
        expect(find.text("We couldn't load this team."), findsNothing);
        handle.dispose();
      },
    );
  }
}
