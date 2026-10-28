import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/common/chat/chat_ui.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/widgets/family_user_picker.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_chat_test_ids.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

/// The team's chat tab (native `CustomChannelListFragment` hosted inside
/// `TeamsHostActivity`): the same channel-list screen the global Chat tab
/// uses, scoped to the team's own channels via `GroupChannelListQuery.
/// customTypesFilter` (native: `Team.filteredCustomTypeChatRoom`, read from
/// `chat_room_types_for_filtering` on `GET teams/{id}`).
///
/// Native hides the "add channel" button in this context
/// (`addChannel.visibility = View.GONE`) and titles the toolbar
/// "&lt;Chat&gt; - &lt;team name&gt;"; both are mirrored here.
class TeamChatScreen extends ConsumerWidget {
  const TeamChatScreen({required this.teamId, super.key});

  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final status = ref.watch(chatControllerProvider);
    final team = ref.watch(teamDetailsProvider(teamId));

    Widget message(String id, String text, {bool retry = false}) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TestId(
              id,
              child: Semantics(
                liveRegion: true,
                child: Text(text, textAlign: TextAlign.center),
              ),
            ),
            if (retry) ...[
              const SizedBox(height: 16),
              TestId(
                TeamChatTestIds.retry,
                child: FilledButton(
                  onPressed: () =>
                      ref.read(chatControllerProvider.notifier).connect(),
                  child: Text(l10n.retryAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: n.backgroundSolidPrimary,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(sdp(1)),
          child: Container(height: sdp(1), color: n.ndotsColor),
        ),
        title: TestId(
          TeamChatTestIds.title,
          child: Semantics(
            header: true,
            child: Text(l10n.teamChatTitle(team.value?.name ?? '')),
          ),
        ),
      ),
      body: status == ChatStatus.connected
          ? team.when(
              loading: () => TestId(
                TeamChatTestIds.root,
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => TestId(
                TeamChatTestIds.root,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.teamDetailsLoadError),
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
              data: (t) => TestId(
                TeamChatTestIds.root,
                child: Column(
                  children: [
                    _TeamFamilyRow(teamId: teamId),
                    Expanded(
                      child: TestId(
                        TeamChatTestIds.list,
                        child: ref
                            .watch(chatUiProvider)
                            .channelList(
                              context,
                              customTypesFilter:
                                  t.chatRoomTypesForFiltering ?? [],
                              onOpen: (url) =>
                                  context.push(AppRoutes.chatChannelFor(url)),
                              onCreate: () {},
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : TestId(
              TeamChatTestIds.root,
              child: switch (status) {
                ChatStatus.unavailable => message(
                  TeamChatTestIds.unavailable,
                  l10n.chatUnavailable,
                ),
                ChatStatus.failed => message(
                  TeamChatTestIds.failed,
                  l10n.chatFailed,
                  retry: true,
                ),
                _ => Center(
                  child: TestId(
                    TeamChatTestIds.connecting,
                    child: Semantics(
                      label: l10n.chatConnecting,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                ),
              },
            ),
    );
  }
}

/// Native `CustomChannelListFragment.handleTeamSelectedPlayers`: the
/// signed-in user's own family (parent + kids, `getTeamFamilySelectedUsers`)
/// who are ALSO on this team's roster — shown only when there is more than
/// one, same `MAX_DISPLAY_CHILDS`-style overlapping-avatar row the global
/// chat/Home/Teams screens already use. Traced in full: selecting a member
/// here never touches the channel-list query on either native app (only
/// `team.filteredCustomTypeChatRoom` does, already wired above) — it is
/// purely a cosmetic "who's chatting" indicator, so this stays
/// non-interactive rather than wiring a selection that would do nothing.
class _TeamFamilyRow extends ConsumerWidget {
  const _TeamFamilyRow({required this.teamId});

  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final roster = ref
        .watch(
          teamRosterProvider((
            teamId: teamId,
            inactive: false,
            search: '',
            sportKey: null,
          )),
        )
        .value;
    if (user == null || roster == null) return const SizedBox.shrink();
    final rosterUserIds = {for (final m in roster) m.userId};
    final members = [
      for (final m in familyMembers(user))
        if (rosterUserIds.contains(m.id)) m,
    ];
    if (members.length <= 1) return const SizedBox.shrink();
    final sdp = context.sdp;
    return TestId(
      FamilyPickerTestIds.row,
      child: Padding(
        padding: EdgeInsets.fromLTRB(sdp(12), sdp(8), sdp(12), 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, member) in members.take(3).indexed)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : sdp(8)),
                child: FamilyAvatar(member: member, isSelected: false),
              ),
          ],
        ),
      ),
    );
  }
}
