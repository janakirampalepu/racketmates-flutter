import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';

/// The chat screens, behind an interface: the Sendbird UIKit widgets need a
/// live connection, so tests replace them.
abstract class ChatUi {
  /// The user's channels; [onOpen] gets the url of the one tapped.
  Widget channelList(
    BuildContext context, {
    required void Function(String url) onOpen,
  });

  /// One conversation.
  Widget channel(BuildContext context, {required String channelUrl});
}

class SendbirdChatUi implements ChatUi {
  const SendbirdChatUi();

  /// The UIKit has its own light/dark switch; follow the app's.
  void _theme(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    SBUThemeProvider().setTheme(dark ? SBUTheme.dark : SBUTheme.light);
  }

  @override
  Widget channelList(
    BuildContext context, {
    required void Function(String url) onOpen,
  }) {
    _theme(context);
    return SendbirdUIKit.provider(
      child: SBUGroupChannelListScreen(
        onListItemClicked: (channel) => onOpen(channel.channelUrl),
      ),
    );
  }

  @override
  Widget channel(BuildContext context, {required String channelUrl}) {
    _theme(context);
    return SendbirdUIKit.provider(
      child: SBUGroupChannelScreen(channelUrl: channelUrl),
    );
  }
}

final chatUiProvider = Provider<ChatUi>((ref) => const SendbirdChatUi());
