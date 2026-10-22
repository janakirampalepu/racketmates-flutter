import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/common/chat/chat_ui.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/chat/chat_test_ids.dart';

/// The chat tab (native `UIKitChannelListFragment`): the user's Sendbird
/// channels, once connected.
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

    if (status == ChatStatus.connected) {
      // The UIKit list brings its own header.
      return TestId(
        ChatTestIds.root,
        child: TestId(
          ChatTestIds.list,
          child: ref
              .watch(chatUiProvider)
              .channelList(
                context,
                onOpen: (url) => context.push(AppRoutes.chatChannelFor(url)),
              ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: TestId(
          ChatTestIds.title,
          child: Semantics(header: true, child: Text(l10n.navChat)),
        ),
      ),
      body: TestId(
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
