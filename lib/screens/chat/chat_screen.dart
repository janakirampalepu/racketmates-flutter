import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/common/chat/chat_ui.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/chat/chat_test_ids.dart';

/// The chat tab (native `CustomChannelListFragment`): the user's Sendbird
/// channels, once connected.
///
/// Native hosts the Sendbird channel-list fragment inside its own toolbar
/// (title "Chat", a create-channel icon action) and hides the UIKit's own
/// header (`headerComponent.rootView.visibility = GONE`); mirrored here by
/// always wrapping the list in our own `AppBar` and suppressing the UIKit's
/// built-in header (see `SendbirdChatUi.channelList`), so the tab's header
/// matches Home/Teams instead of being drawn unclipped behind the status
/// bar (which also made the top channel rows mis-register taps).
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(chatControllerProvider);

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
    );

    void openNewChat() => context.push(AppRoutes.chatNew);

    return Scaffold(
      appBar: AppBar(
        title: TestId(
          ChatTestIds.title,
          child: Semantics(header: true, child: Text(l10n.navChat)),
        ),
        actions: status == ChatStatus.connected
            ? [
                TestId(
                  ChatTestIds.newChatButton,
                  child: IconButton(
                    tooltip: l10n.chatNewAction,
                    icon: const Icon(Icons.add_comment_outlined),
                    onPressed: openNewChat,
                  ),
                ),
              ]
            : null,
      ),
      body: status == ChatStatus.connected
          ? TestId(
              ChatTestIds.root,
              child: TestId(
                ChatTestIds.list,
                child: ref
                    .watch(chatUiProvider)
                    .channelList(
                      context,
                      onOpen: (url) =>
                          context.push(AppRoutes.chatChannelFor(url)),
                      onCreate: openNewChat,
                    ),
              ),
            )
          : TestId(
              ChatTestIds.root,
              child: switch (status) {
                ChatStatus.unavailable => message(
                  ChatTestIds.unavailable,
                  l10n.chatUnavailable,
                ),
                ChatStatus.failed => message(
                  ChatTestIds.failed,
                  l10n.chatFailed,
                  retry: true,
                ),
                _ => Center(
                  child: TestId(
                    ChatTestIds.connecting,
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
