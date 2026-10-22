import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/team_details/team_members_tab.dart';
import 'package:racketmates/screens/team_details/team_rankings_tab.dart';
import 'package:racketmates/screens/team_details/team_schedule_tab.dart';

/// The team home (native `TeamHomeFragment`): its schedule, the ranking of its
/// members (when the team has player ranking on) and the members with their
/// management. Team settings, archiving and deleting a team, entering points
/// and the activity summary are later work.
class TeamDetailsScreen extends ConsumerWidget {
  const TeamDetailsScreen({required this.teamId, super.key});

  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final team = ref.watch(teamDetailsProvider(teamId));

    Widget loaded(Team t) {
      final ranking = t.enablePlayerRanking ?? false;
      return DefaultTabController(
        length: ranking ? 3 : 2,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: BackButton(onPressed: () => context.pop()),
            title: TestId(
              TeamDetailsTestIds.title,
              child: Semantics(header: true, child: Text(t.name ?? '')),
            ),
            bottom: TabBar(
              tabs: [
                TestId(
                  TeamDetailsTestIds.tabSchedule,
                  child: Tab(text: l10n.teamTabSchedule),
                ),
                if (ranking)
                  TestId(
                    TeamDetailsTestIds.tabRankings,
                    child: Tab(text: l10n.teamTabRankings),
                  ),
                TestId(
                  TeamDetailsTestIds.tabMembers,
                  child: Tab(text: l10n.teamTabMembers),
                ),
              ],
            ),
          ),
          body: TestId(
            TeamDetailsTestIds.root,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      [
                        ref.refLabel(
                          t.teamType,
                          teamTypeLabel(l10n, t.teamType),
                        ),
                        if (t.sportKeys.isNotEmpty) teamSportsText(l10n, t),
                      ].join(' · '),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      TeamScheduleTab(
                        teamId: teamId,
                        archived: t.archived ?? false,
                      ),
                      if (ranking) TeamRankingsTab(team: t),
                      TeamMembersTab(team: t),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return team.when(
      loading: () => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: TestId(
          TeamDetailsTestIds.root,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: TestId(
          TeamDetailsTestIds.root,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TestId(
                  TeamDetailsTestIds.error,
                  child: Text(l10n.teamDetailsLoadError),
                ),
                TestId(
                  TeamDetailsTestIds.retry,
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(teamDetailsProvider(teamId)),
                    child: Text(l10n.retryAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: loaded,
    );
  }
}
