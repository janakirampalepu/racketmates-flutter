import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/common/chat/chat_ui.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
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
                child: TestId(
                  TeamChatTestIds.list,
                  child: ref
                      .watch(chatUiProvider)
                      .channelList(
                        context,
                        customTypesFilter: t.chatRoomTypesForFiltering ?? [],
                        onOpen: (url) =>
                            context.push(AppRoutes.chatChannelFor(url)),
                        onCreate: () {},
                      ),
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
