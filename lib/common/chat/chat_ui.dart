import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';

/// One member of a conversation, for the channel-details screen.
///
/// Native Android splits this list into active and "past" (left) members
/// (`ChatroomDetailsPicker.getActiveChatMembers`/`getLeftChatMembers`,
/// keyed off `Member.memberState == LEFT`); the Flutter SDK's
/// `MemberState` enum has no `left` value — a `GroupChannel.members` list
/// here only ever contains current members — so that split is not
/// reproduced; everyone in [ChatChannelInfo.members] is a current member.
class ChatChannelMember {
  const ChatChannelMember({
    required this.userId,
    required this.nickname,
    required this.isMe,
    this.avatarUrl,
  });

  final String userId;
  final String nickname;
  final bool isMe;
  final String? avatarUrl;
}

/// Display info for a conversation's header and details screen: title,
/// avatar, members and whether the signed-in user has muted it.
///
/// The exact title-resolution rule native uses is considerably more
/// involved — it branches on one-to-one/support/event/announcement
/// channels and decodes a JSON blob off the channel for event names
/// (`getGroupChannelItemTitle` in `TextUtils.kt`). This follows the
/// simpler, generic rule the Sendbird UIKit itself uses instead (the
/// channel's own name, else the other members' nicknames), since that is
/// what is safely verifiable from the public SDK without a live backend;
/// native's richer per-channel-type rule is a documented follow-up.
class ChatChannelInfo {
  const ChatChannelInfo({
    required this.title,
    required this.members,
    required this.isMuted,
    this.isArchived = false,
    this.avatarUrl,
  });

  final String title;
  final String? avatarUrl;
  final List<ChatChannelMember> members;
  final bool isMuted;
  final bool isArchived;
}

/// The chat screens, behind an interface: the Sendbird UIKit widgets need a
/// live connection, so tests replace them.
abstract class ChatUi {
  /// The user's channels; [onOpen] gets the url of the one tapped.
  ///
  /// [customTypesFilter] scopes the list to a team's own channels (native
  /// `Team.filteredCustomTypeChatRoom` fed into `queryParams.
  /// customTypesFilter`); omit it for the global chat tab, which shows
  /// every channel.
  Widget channelList(
    BuildContext context, {
    required void Function(String url) onOpen,
    required VoidCallback onCreate,
    List<String>? customTypesFilter,
  });

  /// One conversation.
  Widget channel(BuildContext context, {required String channelUrl});

  /// Display info for that conversation's header and details screen.
  Future<ChatChannelInfo> channelInfo(String channelUrl);

  /// Mutes or unmutes push notifications for that conversation.
  Future<void> setMuted(String channelUrl, {required bool muted});

  /// Archives (hides) or unarchives (unhides) that conversation from the
  /// channel list (native's archive/unarchive action).
  Future<void> setArchived(String channelUrl, {required bool archived});
}

class SendbirdChatUi implements ChatUi {
  const SendbirdChatUi();

  /// The app does not use the UIKit's own purple/green brand palette: native
  /// re-skins it by shadowing the UIKit's own Android resource names
  /// (`primary_main`, `background_50`..`background_700`, in `colors.xml`)
  /// with the app's own brand colors, leaving every other UIKit color (the
  /// ones native never names in `colors.xml`: `secondary_*`, `error_*`,
  /// `overlay_*`, `information_*`, `highlight`, the light/dark text-emphasis
  /// tiers) at the UIKit's own defaults. `SBUColors.setColors` is the
  /// Flutter UIKit's equivalent override point — same field names as the
  /// Android resources — so this reproduces the Android override exactly:
  /// the `primary*`/`background*` fields come from [NativePalette] (the
  /// generated Dart form of the same `colors.xml` entries Android shadows),
  /// everything else is read back from `SBUColors` itself, unchanged.
  void _applyBrand(BuildContext context) {
    final n = context.native;
    SBUColors.setColors(
      primaryExtraDark: n.primaryExtraDark,
      primaryDark: n.primaryDark,
      primaryMain: n.primaryMain,
      primaryLight: n.primaryLight,
      // Android: `primary_extra_light` = `@android:color/transparent`.
      primaryExtraLight: Colors.transparent,
      secondaryExtraDark: SBUColors.secondaryExtraDark,
      secondaryDark: SBUColors.secondaryDark,
      secondaryMain: SBUColors.secondaryMain,
      secondaryLight: SBUColors.secondaryLight,
      secondaryExtraLight: SBUColors.secondaryExtraLight,
      errorExtraDark: SBUColors.errorExtraDark,
      errorDark: SBUColors.errorDark,
      errorMain: SBUColors.errorMain,
      errorLight: SBUColors.errorLight,
      errorExtraLight: SBUColors.errorExtraLight,
      background700: n.background700,
      background600: n.background600,
      background500: n.background500,
      background400: n.background400,
      background300: n.background300,
      background200: n.background200,
      background100: n.background100,
      background50: n.background50,
      overlayDark: SBUColors.overlayDark,
      overlayLight: SBUColors.overlayLight,
      informationExtraDark: SBUColors.informationExtraDark,
      informationDark: SBUColors.informationDark,
      informationMain: SBUColors.informationMain,
      informationLight: SBUColors.informationLight,
      informationExtraLight: SBUColors.informationExtraLight,
      highlight: SBUColors.highlight,
      lightThemeTextHighEmphasis: SBUColors.lightThemeTextHighEmphasis,
      lightThemeTextMidEmphasis: SBUColors.lightThemeTextMidEmphasis,
      lightThemeTextLowEmphasis: SBUColors.lightThemeTextLowEmphasis,
      lightThemeTextDisabled: SBUColors.lightThemeTextDisabled,
      darkThemeTextHighEmphasis: SBUColors.darkThemeTextHighEmphasis,
      darkThemeTextMidEmphasis: SBUColors.darkThemeTextMidEmphasis,
      darkThemeTextLowEmphasis: SBUColors.darkThemeTextLowEmphasis,
      darkThemeTextDisabled: SBUColors.darkThemeTextDisabled,
    );
  }

  /// The UIKit has its own light/dark switch; follow the app's. `background600`
  /// and `background100` differ between the app's light/dark palettes (they
  /// come from `background_solid_primary`/`others_msg_bg_color`, both
  /// day/night-qualified on Android), so the brand colors are re-applied
  /// every time this runs, not just once.
  void _theme(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    SBUThemeProvider().setTheme(dark ? SBUTheme.dark : SBUTheme.light);
    _applyBrand(context);
  }

  @override
  Widget channelList(
    BuildContext context, {
    required void Function(String url) onOpen,
    required VoidCallback onCreate,
    List<String>? customTypesFilter,
  }) {
    _theme(context);
    return SendbirdUIKit.provider(
      child: SBUGroupChannelListScreen(
        query: customTypesFilter == null
            ? null
            : (GroupChannelListQuery()..customTypesFilter = customTypesFilter),
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
      child: SBUGroupChannelScreen(
        channelUrl: channelUrl,
        // `ChatChannelScreen` draws its own header (avatar, title, a tap
        // to the details screen) matching native's own toolbar, which
        // likewise blanks the UIKit's title and buttons
        // (`UIKitChannelFragment.onBindChannelHeaderComponent`).
        customHeader: (_, _, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  @override
  Future<ChatChannelInfo> channelInfo(String channelUrl) async {
    // A bounded wait rather than none: `GroupChannel.getChannel` falls back
    // to a network call when the channel is not already cached, and with no
    // timeout a stalled request would leave the header/details screen
    // showing a spinner indefinitely with no way to retry.
    final channel = await GroupChannel.getChannel(channelUrl)
        .timeout(const Duration(seconds: 15));
    return _toInfo(channel);
  }

  @override
  Future<void> setMuted(String channelUrl, {required bool muted}) async {
    final channel = await GroupChannel.getChannel(channelUrl);
    await channel.setMyPushTriggerOption(
      muted
          ? GroupChannelPushTriggerOption.off
          : GroupChannelPushTriggerOption.all,
    );
  }

  @override
  Future<void> setArchived(String channelUrl, {required bool archived}) async {
    final channel = await GroupChannel.getChannel(channelUrl);
    if (archived) {
      await channel.hide();
    } else {
      await channel.unhide();
    }
  }

  /// A placeholder cover Sendbird itself assigns to new group channels;
  /// the UIKit's own avatar rule (below) treats it as "no cover".
  static const _sampleCoverPrefix =
      'https://static.sendbird.com/sample/cover/cover_';

  ChatChannelInfo _toInfo(GroupChannel channel) {
    final myId = SendbirdChat.currentUser?.userId;
    final others = channel.members.where((m) => m.userId != myId).toList()
      ..sort((a, b) => a.nickname.compareTo(b.nickname));
    String nameOf(User user) =>
        user.nickname.isNotEmpty ? user.nickname : user.userId;
    final title = channel.name.isNotEmpty
        ? channel.name
        : others.map(nameOf).join(', ');

    // Mirrors the UIKit's own `getGroupChannelAvatarComponent` (used by
    // the channel list, which is why it already showed the right image):
    // the channel's own cover unless it's one of Sendbird's sample
    // placeholders, else a member's photo — the UIKit composites up to 4
    // members into a grid; a single `CircleAvatar` here just shows the
    // first other member who has one, rather than channel.coverUrl alone
    // (empty for most group channels, which is why this showed the
    // UIKit's own default person icon for every group chat).
    final hasRealCover =
        channel.coverUrl.isNotEmpty &&
        !channel.coverUrl.startsWith(_sampleCoverPrefix);
    String? avatarUrl;
    if (hasRealCover) {
      avatarUrl = channel.coverUrl;
    } else {
      for (final member in others) {
        if (member.profileUrl.isNotEmpty) {
          avatarUrl = member.profileUrl;
          break;
        }
      }
    }
    return ChatChannelInfo(
      title: title.isNotEmpty ? title : channel.channelUrl,
      avatarUrl: avatarUrl,
      isMuted: channel.myPushTriggerOption == GroupChannelPushTriggerOption.off,
      isArchived: channel.isHidden,
      members: channel.members
          .map(
            (m) => ChatChannelMember(
              userId: m.userId,
              nickname: nameOf(m),
              isMe: m.userId == myId,
              avatarUrl: m.profileUrl.isNotEmpty ? m.profileUrl : null,
            ),
          )
          .toList(),
    );
  }
}

final chatUiProvider = Provider<ChatUi>((ref) => const SendbirdChatUi());

/// Shared between the channel header and the details screen so opening the
/// details screen (which re-reads this same provider) does not re-fetch.
final chatChannelInfoProvider = FutureProvider.autoDispose
    .family<ChatChannelInfo, String>(
      (ref, channelUrl) => ref.watch(chatUiProvider).channelInfo(channelUrl),
    );
