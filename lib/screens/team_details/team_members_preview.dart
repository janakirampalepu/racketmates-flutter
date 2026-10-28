import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/widgets/home_sections.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

/// Team Home's one team-only section (native `layoutTeamMembers`): a short
/// preview of the roster with "See all" and a "Manage members" row below.
/// "Manage members" always opens the full member list/management screen
/// (`TeamMembersScreen`); "See all" instead opens the ranking list when the
/// team has ranking on (native `sectionTitle(..., showSeeAll: true) { if
/// isTeamRankingEnabled { push(.teamMemberRankingListView) } else {
/// push(.teamMemberListView) } }` — Team Home has no rankings icon of its
/// own; this is how native reaches it). There is no Home equivalent — every
/// other dashboard section is shared (`common/widgets/home_sections.dart`).
class TeamMembersPreview extends ConsumerWidget {
  const TeamMembersPreview({
    required this.teamId,
    required this.rankingEnabled,
    super.key,
  });

  final int teamId;
  final bool rankingEnabled;

  static const _previewCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final roster = ref.watch(
      teamRosterProvider((
        teamId: teamId,
        inactive: false,
        search: '',
        sportKey: null,
      )),
    );

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
