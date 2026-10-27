import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_ui.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/chat_channel_details/chat_channel_details_test_ids.dart';

/// The conversation's details (native `ChatroomDetailsPicker`, a bottom
/// sheet there): avatar, name, a mute switch and the member list — all from
/// the public Sendbird SDK, not the backend. Native's richer version also
/// has per-channel-type icons, a split of active/left members and an
/// archive/unarchive action; left as a follow-up (see `CLAUDE.md`).
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
        title: Text(l10n.chatChannelDetailsTitle),
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
            child: TestId(
              ChatChannelDetailsTestIds.error,
              child: Text(l10n.chatChannelDetailsError),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({required this.channelUrl, required this.info});

  final String channelUrl;
  final ChatChannelInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
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
              TestId(
                ChatChannelDetailsTestIds.title,
                child: Text(
                  info.title,
                  style: TextStyle(
                    color: n.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TestId(
          ChatChannelDetailsTestIds.muteSwitch,
          child: SwitchListTile(
            title: Text(l10n.chatChannelDetailsMute),
            value: info.isMuted,
            onChanged: (muted) async {
              await ref
                  .read(chatUiProvider)
                  .setMuted(channelUrl, muted: muted);
              ref.invalidate(chatChannelInfoProvider(channelUrl));
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.chatChannelDetailsMembers,
            style: TextStyle(color: n.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        for (final member in info.members)
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
              ),
            ),
          ),
      ],
    );
  }
}
