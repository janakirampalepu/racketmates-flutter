import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_edit.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/widgets/load_error_body.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/team_details/team_rankings_tab.dart';

/// The team's player ranking (native `TeamMemberRankingFragment`, a screen
/// of its own there, not a tab on Team Home).
class TeamRankingsScreen extends ConsumerStatefulWidget {
  const TeamRankingsScreen({required this.teamId, super.key});

  final int teamId;

  @override
  ConsumerState<TeamRankingsScreen> createState() => _TeamRankingsScreenState();
}

class _TeamRankingsScreenState extends ConsumerState<TeamRankingsScreen> {
  // Lets the AppBar's "⋮" action (native's toolbar/overflow "other
  // actions" menu, top-right — not inline with the filters) reach the
  // tab's own reset-ranking sheet.
  final _tabKey = GlobalKey<TeamRankingsTabState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final team = ref.watch(teamDetailsProvider(widget.teamId));
    final teamName = team.value?.name;

    bool canReset(Team t) =>
        t.sportKeys.isNotEmpty &&
        memberAccess(
              t,
              TeamSettingsPermissions.settings,
              subscribed: ref.watch(sessionInfoControllerProvider).isSubscribed,
            ) !=
            AccessDecision.hidden;

    return Scaffold(
      backgroundColor: n.backgroundSolidPrimary,
      appBar: AppBar(
        backgroundColor: n.backgroundSolidPrimary,
        // Native: "Rankings - <Team Name>" (Android
        // `TeamMemberRankingFragment`'s title), not bare "Rankings".
        title: Text(
          teamName == null || teamName.isEmpty
              ? l10n.teamTabRankings
              : '${l10n.teamTabRankings} - $teamName',
        ),
        actions: [
          if (team.value != null && canReset(team.value!))
            TestId(
              TeamDetailsTestIds.rankingOtherActions,
              child: IconButton(
                tooltip: l10n.teamRankingOtherActions,
                onPressed: () => _tabKey.currentState?.openActionsSheet(),
                icon: const Icon(Icons.more_vert),
              ),
            ),
        ],
      ),
      body: team.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: LoadErrorBody(
            error: error,
            fallbackText: l10n.teamDetailsLoadError,
            retryId: TeamDetailsTestIds.retry,
            onRetry: () => ref.invalidate(teamDetailsProvider(widget.teamId)),
            errorTestId: TeamDetailsTestIds.error,
          ),
        ),
        data: (t) => TeamRankingsTab(key: _tabKey, team: t),
      ),
    );
  }
}
