import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/common/chat/chat_ui.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/chat/chat_test_ids.dart';

/// One conversation (native `UIKitChannelFragment`). Opens from the channel
/// list, a chat push or the support entry in settings; waits for the chat
/// connection if it is not up yet.
class ChatChannelScreen extends ConsumerWidget {
  const ChatChannelScreen({required this.channelUrl, super.key});

  final String channelUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(chatControllerProvider);
    if (status == ChatStatus.connected) {
      return TestId(
        ChatTestIds.channelRoot,
        child: ref
            .watch(chatUiProvider)
            .channel(context, channelUrl: channelUrl),
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
