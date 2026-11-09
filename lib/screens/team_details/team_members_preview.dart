import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_edit.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/widgets/home_sections.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

/// Team Home's one team-only section (native `layoutTeamMembers`): a short
/// preview of the roster with "See all" and a "Manage members" row below.
/// "Manage members" opens the full member list/management screen
/// (`TeamMembersScreen`), gated by `team.manage_players` (native
/// `TeamHomeFragment.displayHomeTeamSettings`'s `layoutManageMembers`,
/// hidden when `team.userPermissions.teamManagePlayers.accessState ==
/// UP_NOT_AVAILABLE`); "See all" instead opens the ranking list when the
/// team has ranking on (native `sectionTitle(..., showSeeAll: true) { if
/// isTeamRankingEnabled { push(.teamMemberRankingListView) } else {
/// push(.teamMemberListView) } }` — Team Home has no rankings icon of its
/// own; this is how native reaches it). There is no Home equivalent — every
/// other dashboard section is shared (`common/widgets/home_sections.dart`).
///
/// The preview reads `team.teamPlayers` — the roster already embedded in
/// `GET teams/{id}` — instead of fetching `GET teams/{id}/team_players`
/// again. Native does the same: Android `TeamHomeFragment.displayTeamMembers`
/// reads `viewModel.team.value?.teamPlayers` directly (`Team.kt`'s
/// `team_players` field), and iOS's `memberSection()` reads
/// `TeamDetailsManager.shared.getTeamDetail()?.team?.teamPlayers`
/// (`Team.swift`'s `teamPlayers`) — neither calls the dedicated
/// `team_players` endpoint for this preview; only the full Manage Members
/// screen (`teamRosterProvider`) does, for its own search/pagination.
class TeamMembersPreview extends ConsumerWidget {
  const TeamMembersPreview({
    required this.team,
    required this.rankingEnabled,
    super.key,
  });

  final Team team;
  final bool rankingEnabled;

  static const _previewCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final teamId = team.id ?? 0;
    final members = [
      for (final member in team.teamPlayers ?? const <TeamPlayer>[])
        if (!member.isInactive) member,
    ];
    final canManageMembers =
        memberAccess(
          team,
          TeamSettingsPermissions.manageMembers,
          subscribed: ref.watch(sessionInfoControllerProvider).isSubscribed,
        ) !=
        AccessDecision.hidden;

    void openMembers() => context.push(AppRoutes.teamMembersFor(teamId));
    void seeAll() => rankingEnabled
        ? context.push(AppRoutes.teamRankingsFor(teamId))
        : openMembers();

    return TestId(
      TeamHomeActionIds.membersSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(
            title: l10n.teamHomeMembersTitle,
            seeAllId: TeamHomeActionIds.membersSeeAll,
            onSeeAll: seeAll,
          ),
          members.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: sdp(16)),
                  child: Text(
                    l10n.teamMembersEmpty,
                    style: TextStyle(color: n.textSecondary),
                  ),
                )
              : SizedBox(
                  height: sdp(156),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: sdp(16)),
                    itemCount: members.take(_previewCount).length,
                    separatorBuilder: (_, _) => SizedBox(width: sdp(12)),
                    itemBuilder: (context, i) => _MemberCard(
                      member: members[i],
                      testId: TeamHomeActionIds.memberPreview(
                        members[i].id ?? members[i].userId ?? 0,
                      ),
                      onTap: openMembers,
                    ),
                  ),
                ),
          if (canManageMembers)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sdp(16)),
              child: TestId(
                TeamHomeActionIds.manageMembers,
                // Native renders this as a filled, centered pill button —
                // Android's `layoutManageMembers` (`bg_white_rect`
                // background, centered icon+text), iOS's `manageMembersButton`
                // (`SecondaryButtonView`, `Background.Solid.tertiary1`) —
                // not a bare list row.
                child: Material(
                  color: n.backgroundSolidTertiary1,
                  borderRadius: BorderRadius.circular(sdp(8)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(sdp(8)),
                    onTap: openMembers,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: sdp(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: sdp(18),
                            // n.textSecondary on this tinted background
                            // clears only 4.35:1 — below this project's own
                            // enforced WCAG AA minimum (caught by the
                            // guideline test); textPrimary is the same fix
                            // already used elsewhere in this app for the
                            // same class of issue.
                            color: n.textPrimary,
                          ),
                          SizedBox(width: sdp(8)),
                          Text(
                            l10n.teamHomeManageMembers,
                            style: TextStyle(color: n.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One member card in the preview row (native `MembersView`): a circular
/// initials avatar, the name, and a role pill, matching the small square
/// card the iOS screenshot shows (previously a plain `ListTile` with no
/// avatar, which read as broken/unstyled).
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.testId,
    required this.onTap,
  });

  final TeamPlayer member;
  final String testId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    final l10n = AppLocalizations.of(context);
    final name = member.user?.displayName ?? '';
    final initial = name.trim().isEmpty ? '' : name.trim()[0].toUpperCase();
    return TestId(
      testId,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(sdp(8)),
        child: Container(
          width: sdp(120),
          padding: EdgeInsets.all(sdp(12)),
          decoration: BoxDecoration(
            color: n.backgroundSolidPrimary,
            borderRadius: BorderRadius.circular(sdp(8)),
            border: Border.all(color: n.borderSolidPrimary),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: sdp(24),
                backgroundColor: n.avatarBgColor,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: n.imagePrimeryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: sdp(8)),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: n.textPrimary, fontSize: sdp(13)),
              ),
              SizedBox(height: sdp(4)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sdp(8),
                  vertical: sdp(2),
                ),
                decoration: BoxDecoration(
                  color: n.backgroundSolidGreen4,
                  borderRadius: BorderRadius.circular(sdp(10)),
                ),
                child: Text(
                  memberRolesText(l10n, member),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: n.textPrimary, fontSize: sdp(11)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
