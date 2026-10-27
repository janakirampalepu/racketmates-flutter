import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/team_details/team_members_tab.dart';

/// The team's full member list and management (native
/// `TeamActiveParticipantFragment`, reached from Team Home's "Manage
/// members" row rather than embedded as a tab).
class TeamMembersScreen extends ConsumerWidget {
  const TeamMembersScreen({required this.teamId, super.key});

  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final team = ref.watch(teamDetailsProvider(teamId));
    return Scaffold(
      backgroundColor: n.backgroundSolidPrimary,
      appBar: AppBar(
        backgroundColor: n.backgroundSolidPrimary,
        title: Text(l10n.teamTabMembers),
      ),
      body: team.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
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
                  onPressed: () => ref.invalidate(teamDetailsProvider(teamId)),
                  child: Text(l10n.retryAction),
                ),
              ),
            ],
          ),
        ),
        data: (t) => TeamMembersTab(team: t),
      ),
    );
  }
}
