import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/widgets/home_sections.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

/// Team Home's one team-only section (native `layoutTeamMembers`): a short
/// preview of the roster with "See all" and a "Manage members" row below,
/// both opening the full member list/management screen
/// (`TeamMembersScreen`). There is no Home equivalent — every other
/// dashboard section is shared (`common/widgets/home_sections.dart`).
class TeamMembersPreview extends ConsumerWidget {
  const TeamMembersPreview({required this.teamId, super.key});

  final int teamId;

  static const _previewCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final roster = ref.watch(
      teamRosterProvider((teamId: teamId, inactive: false)),
    );

    void openMembers() => context.push(AppRoutes.teamMembersFor(teamId));

    return TestId(
      TeamHomeActionIds.membersSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(
            title: l10n.teamHomeMembersTitle,
            seeAllId: TeamHomeActionIds.membersSeeAll,
            onSeeAll: openMembers,
          ),
          roster.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: EdgeInsets.symmetric(horizontal: sdp(16)),
              child: Text(
                l10n.teamMembersLoadError,
                style: TextStyle(color: n.textSecondary),
              ),
            ),
            data: (members) => members.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: sdp(16)),
                    child: Text(
                      l10n.teamMembersEmpty,
                      style: TextStyle(color: n.textSecondary),
                    ),
                  )
                : Column(
                    children: [
                      for (final m in members.take(_previewCount))
                        TestId(
                          TeamHomeActionIds.memberPreview(
                            m.id ?? m.userId ?? 0,
                          ),
                          child: ListTile(
                            title: Text(m.user?.displayName ?? ''),
                            subtitle: Text(memberRolesText(l10n, m)),
                            onTap: openMembers,
                          ),
                        ),
                    ],
                  ),
          ),
          TestId(
            TeamHomeActionIds.manageMembers,
            child: ListTile(
              leading: const Icon(Icons.group_outlined),
              title: Text(l10n.teamHomeManageMembers),
              onTap: openMembers,
            ),
          ),
        ],
      ),
    );
  }
}
