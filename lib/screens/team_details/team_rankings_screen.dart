import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/widgets/load_error_body.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/team_details/team_rankings_tab.dart';

/// The team's player ranking (native `TeamMemberRankingFragment`, a screen
/// of its own there, not a tab on Team Home).
class TeamRankingsScreen extends ConsumerWidget {
  const TeamRankingsScreen({required this.teamId, super.key});

  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final team = ref.watch(teamDetailsProvider(teamId));
    final teamName = team.value?.name;
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
      ),
      body: team.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: LoadErrorBody(
            error: error,
            fallbackText: l10n.teamDetailsLoadError,
            retryId: TeamDetailsTestIds.retry,
            onRetry: () => ref.invalidate(teamDetailsProvider(teamId)),
            errorTestId: TeamDetailsTestIds.error,
          ),
        ),
        data: (t) => TeamRankingsTab(team: t),
      ),
    );
  }
}
