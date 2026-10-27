import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (status == ChatStatus.connected) {
      // The UIKit channel screen draws its own header (avatar, channel
      // name, typing status and a working back button — native disables
      // this screen's own `ChannelHeaderComponent` the same way and relies
      // on its *own* toolbar instead). This route is pushed full-screen
      // with no Scaffold/AppBar of ours above it, so without a SafeArea
      // that header rendered under the status bar/notch: the title looked
      // missing and the back button sat behind the status bar, out of
      // reach.
      return Scaffold(
        body: SafeArea(
          child: TestId(
            ChatTestIds.channelRoot,
            child: ref
                .watch(chatUiProvider)
                .channel(context, channelUrl: channelUrl),
          ),
        ),
      );
    }
    final failed =
        status == ChatStatus.failed || status == ChatStatus.unavailable;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navChat)),
      body: TestId(
        ChatTestIds.channelRoot,
        child: Center(
          child: failed
              ? Padding(
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
                            onPressed: () => ref
                                .read(chatControllerProvider.notifier)
                                .connect(),
                            child: Text(l10n.retryAction),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : Semantics(
                  label: l10n.chatConnecting,
                  child: const CircularProgressIndicator(),
                ),
        ),
      ),
    );
  }
}
