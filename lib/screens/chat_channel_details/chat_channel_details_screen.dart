import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_ui.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/chat_channel_details/chat_channel_details_test_ids.dart';

/// The conversation's details (native `ChatroomDetailsPicker`, a bottom
/// sheet there, `dialog_chatroom_details.xml`): a close button, a large
/// centered avatar and name, a member list, a mute switch and an
/// archive/unarchive action — all from the public Sendbird SDK, not the
/// backend. Native also splits the member list into active and "past"
/// (left) members; the Flutter SDK's `MemberState` has no `left` value
/// (`GroupChannel.members` only ever lists current members), so that
/// split is not reproduced — see `ChatChannelMember`.
class ChatChannelDetailsScreen extends ConsumerWidget {
  const ChatChannelDetailsScreen({required this.channelUrl, super.key});

  final String channelUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final info = ref.watch(chatChannelInfoProvider(channelUrl));

    return Scaffold(
      backgroundColor: n.backgroundSolidPrimary,
      appBar: AppBar(
        backgroundColor: n.backgroundSolidPrimary,
        automaticallyImplyLeading: false,
        title: Text(l10n.chatChannelDetailsTitle),
        actions: [
          IconButton(
            tooltip: l10n.closeAction,
            icon: Icon(Icons.close, color: n.imagePrimeryColor),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: TestId(
        ChatChannelDetailsTestIds.root,
        child: info.when(
          data: (data) => _DetailsBody(channelUrl: channelUrl, info: data),
          loading: () => Center(
            child: TestId(
              ChatChannelDetailsTestIds.loading,
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TestId(
                    ChatChannelDetailsTestIds.error,
                    child: Text(
                      l10n.chatChannelDetailsError,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TestId(
                    ChatChannelDetailsTestIds.retry,
                    child: FilledButton(
                      onPressed: () =>
                          ref.invalidate(chatChannelInfoProvider(channelUrl)),
                      child: Text(l10n.retryAction),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsBody extends ConsumerStatefulWidget {
  const _DetailsBody({required this.channelUrl, required this.info});

  final String channelUrl;
  final ChatChannelInfo info;

  @override
  ConsumerState<_DetailsBody> createState() => _DetailsBodyState();
}

class _DetailsBodyState extends ConsumerState<_DetailsBody> {
  static const _collapsedCount = 4;
  bool _showAllMembers = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final info = widget.info;
    final members = _showAllMembers
        ? info.members
        : info.members.take(_collapsedCount).toList();

    // Native's mute row and archive action are both rounded cards
    // (`onboard_options_btn_bg`) over the screen background.
    // `Material` (not a plain `Container`/`BoxDecoration`): `ListTile`/
    // `SwitchListTile` paint their background and ink splashes on the
    // nearest `Material` ancestor, so a decorated `Container` without one
    // hides those effects (and asserts in debug mode).
    Widget card({required Widget child}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: n.background100,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Center(
          child: Column(
            children: [
              TestId(
                ChatChannelDetailsTestIds.avatar,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: n.background200,
                  backgroundImage: info.avatarUrl != null
                      ? NetworkImage(info.avatarUrl!)
                      : null,
                  child: info.avatarUrl == null
                      ? Icon(Icons.group, color: n.textSecondary, size: 36)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TestId(
                  ChatChannelDetailsTestIds.title,
                  child: Text(
                    info.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: n.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.chatChannelDetailsMembers,
            style: TextStyle(
              color: n.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final member in members)
          TestId(
            ChatChannelDetailsTestIds.member(member.userId),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: n.background200,
                backgroundImage: member.avatarUrl != null
                    ? NetworkImage(member.avatarUrl!)
                    : null,
                child: member.avatarUrl == null
                    ? Icon(Icons.person, color: n.textSecondary)
                    : null,
              ),
              title: Text(
                member.isMe
                    ? '${member.nickname} (${l10n.chatChannelDetailsYou})'
                    : member.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        if (info.members.length > _collapsedCount)
          Center(
            child: TextButton(
              onPressed: () =>
                  setState(() => _showAllMembers = !_showAllMembers),
              child: Text(
                _showAllMembers ? l10n.seeLessAction : l10n.seeAllAction,
              ),
            ),
          ),
        const SizedBox(height: 8),
        card(
          child: TestId(
            ChatChannelDetailsTestIds.muteSwitch,
            child: SwitchListTile(
              title: Text(l10n.chatChannelDetailsMute),
              subtitle: Text(l10n.chatChannelDetailsMuteSubtitle),
              value: info.isMuted,
              onChanged: (muted) async {
                await ref
                    .read(chatUiProvider)
                    .setMuted(widget.channelUrl, muted: muted);
                ref.invalidate(chatChannelInfoProvider(widget.channelUrl));
              },
            ),
          ),
        ),
        card(
          child: TestId(
            ChatChannelDetailsTestIds.archiveButton,
            child: ListTile(
              leading: Icon(
                info.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                color: n.textPrimary,
              ),
              title: Text(
                info.isArchived
                    ? l10n.chatChannelDetailsUnarchive
                    : l10n.chatChannelDetailsArchive,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                await ref
                    .read(chatUiProvider)
                    .setArchived(widget.channelUrl, archived: !info.isArchived);
                ref.invalidate(chatChannelInfoProvider(widget.channelUrl));
              },
            ),
          ),
        ),
      ],
    );
  }
}
