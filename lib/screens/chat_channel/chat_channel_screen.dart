import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/common/chat/chat_ui.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/chat/chat_test_ids.dart';

/// One conversation (native `CustomChannelFragment`/`UIKitChannelFragment`).
/// Opens from the channel list, a chat push or the support entry in
/// settings; waits for the chat connection if it is not up yet.
class ChatChannelScreen extends ConsumerWidget {
  const ChatChannelScreen({required this.channelUrl, super.key});

  final String channelUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(chatControllerProvider);
    final n = context.native;

    // Native's own toolbar (`fragment_custom_channel.xml`): a back button
    // tinted the brand lime (`image_primery_color`) and, tappable on its
    // own (`profileTitleLayout.setOnClickListener`), the channel's avatar
    // and name opening the details screen (`ChatroomDetailsPicker`). The
    // UIKit's own header (avatar/title/typing/back) is suppressed in
    // `SendbirdChatUi.channel` so this is the only header shown.
    final info = status == ChatStatus.connected
        ? ref.watch(chatChannelInfoProvider(channelUrl))
        : null;
    final title = info?.value?.title ?? l10n.navChat;
    final avatarUrl = info?.value?.avatarUrl;

    return Scaffold(
      backgroundColor: n.backgroundSolidPrimary,
      appBar: AppBar(
        backgroundColor: n.backgroundSolidPrimary,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: n.ndotsColor),
        ),
        leading: TestId(
          ChatTestIds.channelBackButton,
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icon(Icons.arrow_back, color: n.imagePrimeryColor),
            onPressed: () => context.pop(),
          ),
        ),
        titleSpacing: 0,
        title: status == ChatStatus.connected
            ? TestId(
                ChatTestIds.channelHeader,
                child: InkWell(
                  onTap: () =>
                      context.push(AppRoutes.chatChannelDetailsFor(channelUrl)),
                  child: Row(
                    children: [
                      TestId(
                        ChatTestIds.channelAvatar,
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: n.background200,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  color: n.textSecondary,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TestId(
                          ChatTestIds.channelTitle,
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: n.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Text(l10n.navChat),
      ),
      body: TestId(
        ChatTestIds.channelRoot,
        child: switch (status) {
          ChatStatus.connected => ref
              .watch(chatUiProvider)
              .channel(context, channelUrl: channelUrl),
          ChatStatus.unavailable || ChatStatus.failed => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TestId(
                    ChatTestIds.failed,
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        status == ChatStatus.unavailable
                            ? l10n.chatUnavailable
                            : l10n.chatFailed,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (status == ChatStatus.failed) ...[
                    const SizedBox(height: 16),
                    TestId(
                      ChatTestIds.retry,
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
          ),
          _ => Center(
            child: Semantics(
              label: l10n.chatConnecting,
              child: const CircularProgressIndicator(),
            ),
          ),
        },
      ),
    );
  }
}
