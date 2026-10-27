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
    required VoidCallback onCreate,
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
    required VoidCallback onCreate,
  }) {
    _theme(context);
    return SendbirdUIKit.provider(
      child: SBUGroupChannelListScreen(
        onCreateButtonClicked: onCreate,
        onListItemClicked: (channel) => onOpen(channel.channelUrl),
        // The host screen (`ChatScreen`) draws its own AppBar (title +
        // create action), matching native's own toolbar which hides the
        // UIKit's header entirely (`UIKitChannelListFragment.
        // onBindHeaderComponent`); without this the UIKit's 56dp header row
        // renders unclipped at the very top of the tab (the shell has no
        // AppBar of its own to provide a safe area), overlapping the status
        // bar so it looked missing and the first rows mis-registered taps.
        customHeader: (_, _, _, _) => const SizedBox.shrink(),
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
