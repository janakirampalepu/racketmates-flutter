import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_avatar.dart';
import 'package:racketmates/common/chat/chat_channel_display.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/chat/chat_test_ids.dart';
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
/// Title and avatar now use native's own richer, per-channel-type rule
/// (`resolveChannelDisplay`/`getGroupChannelItemTitle` in `TextUtils.kt`,
/// confirmed to match iOS exactly), not the Sendbird UIKit's generic one
/// (channel name, else member nicknames) this used to fall back to —
/// [title] can still be empty when `channel.data` is missing/unreadable,
/// same as native; callers supply their own fallback for that case.
class ChatChannelInfo {
  const ChatChannelInfo({
    required this.title,
    required this.members,
    required this.isMuted,
    this.iconAsset = 'ic_chat_unknown',
    this.iconBackground = ChatIconBackground.none,
    this.isArchived = false,
    this.avatarUrl,
  });

  final String title;
  final String? avatarUrl;
  final String iconAsset;
  final ChatIconBackground iconBackground;
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
  /// every channel. [archived] shows hidden (archived) channels instead of
  /// the normal active list (native `displayActiveChatList`/
  /// `displayArchiveChatList`'s `hiddenChannelFilter` toggle).
  Widget channelList(
    BuildContext context, {
    required void Function(String url) onOpen,
    required VoidCallback onCreate,
    List<String>? customTypesFilter,
    bool archived = false,
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

  /// Whether at least one channel (in [customTypesFilter]'s scope, when
  /// given) is archived — native only shows the Active/Archived toggle at
  /// all once there is something to switch to (`displayArchiveBanner`/
  /// `displayArchivedBanner`, both gated on a non-empty archived count).
  Future<bool> hasArchivedChannels({List<String>? customTypesFilter});
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
    bool archived = false,
  }) {
    // Deliberately NOT `SBUGroupChannelListScreen` any more: that widget
    // reads its own `GroupChannelListQuery` once in `initState` and never
    // re-queries from `didUpdateWidget` (confirmed by reading the package
    // source, `sbu_group_channel_list_screen.dart`), so it depends on being
    // *remounted* with a fresh key to pick up a changed `archived`/
    // `customTypesFilter` — which works in isolation (verified with a
    // throwaway widget test reproducing the exact pattern) but, combined
    // with the SDK's own local collection cache and a separate bug in
    // `GroupChannel.hide()` (see `setArchived`), still wasn't reliably
    // showing the right list end-to-end. `_ChannelListBody` below fetches
    // directly with `GroupChannelListQuery.next()` and re-fetches in its
    // own `didUpdateWidget` — no UIKit collection, no local cache, no
    // dependence on key-triggered remounting.
    return _ChannelListBody(
      archived: archived,
      customTypesFilter: customTypesFilter,
      onOpen: onOpen,
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
      // Native (`GroupChatViewModel.archiveChat`: `groupChannel.hide(false,
      // false)`) hides WITHOUT auto-unhide — the channel stays archived even
      // after a new message arrives, unlike the SDK's own default
      // (`allowAutoUnhide: true`, which un-archives on the next message).
      // The read side must filter for the same hidden mode (see below) or
      // the archived tab never finds what this just hid.
      await channel.hide(allowAutoUnhide: false);
    } else {
      await channel.unhide();
    }
    // The SDK's own `hide()` only flips the channel's cached `isHidden`
    // when the hide response carries a changed `ts_message_offset` — null
    // or unchanged (common for a quiet/freshly-created channel) silently
    // skips it, leaving the in-memory channel (and the details screen's
    // archive switch) stuck on the old state even though the server side
    // succeeded. A full refresh re-reads the channel directly from the
    // server, which has no such gap.
    await GroupChannel.refresh(channelUrl);
  }

  @override
  Future<bool> hasArchivedChannels({List<String>? customTypesFilter}) async {
    final query = GroupChannelListQuery()
      ..customTypesFilter = customTypesFilter ?? const []
      // Native queries `HiddenChannelFilter.HIDDEN` (any hidden state), not
      // the auto-unhide-specific subset — matched here.
      ..hiddenChannelFilter = HiddenChannelFilter.hidden
      ..limit = 1;
    final channels = await query.next();
    return channels.isNotEmpty;
  }

  ChatChannelInfo _toInfo(GroupChannel channel) {
    final myId = SendbirdChat.currentUser?.userId;
    String nameOf(User user) =>
        user.nickname.isNotEmpty ? user.nickname : user.userId;
    final display = resolveChannelDisplay(channel, myUserId: myId);
    // Native's own resolution leaves the title empty when `channel.data`
    // is missing/unreadable; fall back to the channel's own name, else
    // the other members' nicknames, rather than show nothing.
    final title = display.title.isNotEmpty
        ? display.title
        : (channel.name.isNotEmpty
              ? channel.name
              : channel.members
                    .where((m) => m.userId != myId)
                    .map(nameOf)
                    .join(', '));
    return ChatChannelInfo(
      title: title.isNotEmpty ? title : channel.channelUrl,
      avatarUrl: display.avatarUrl,
      iconAsset: display.iconAsset,
      iconBackground: display.iconBackground,
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

/// The channel list's own fetch and pagination, built directly on
/// `GroupChannelListQuery` (see the comment on `channelList` for why this
/// replaced `SBUGroupChannelListScreen`). Re-fetches from scratch whenever
/// [archived] or [customTypesFilter] change.
class _ChannelListBody extends StatefulWidget {
  const _ChannelListBody({
    required this.archived,
    required this.customTypesFilter,
    required this.onOpen,
  });

  final bool archived;
  final List<String>? customTypesFilter;
  final void Function(String url) onOpen;

  @override
  State<_ChannelListBody> createState() => _ChannelListBodyState();
}

class _ChannelListBodyState extends State<_ChannelListBody> {
  final _scrollController = ScrollController();
  GroupChannelListQuery? _query;
  List<GroupChannel> _channels = [];
  bool _loading = true;
  bool _error = false;
  // Bumped on every reload so a slow, now-superseded fetch can't overwrite
  // a newer one's result when it finally completes.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    _reload();
  }

  @override
  void didUpdateWidget(covariant _ChannelListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameFilter = _listEquals(
      oldWidget.customTypesFilter,
      widget.customTypesFilter,
    );
    if (oldWidget.archived != widget.archived || !sameFilter) {
      _reload();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _reload() {
    final requestId = ++_requestId;
    setState(() {
      _channels = [];
      _loading = true;
      _error = false;
    });
    _query = GroupChannelListQuery()
      ..customTypesFilter = widget.customTypesFilter ?? const []
      ..hiddenChannelFilter = widget.archived
          ? HiddenChannelFilter.hidden
          : HiddenChannelFilter.unhidden;
    _loadMore(requestId);
  }

  Future<void> _loadMore(int requestId) async {
    final query = _query;
    if (query == null || query.isLoading || !query.hasNext) return;
    try {
      final channels = await query.next();
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _channels = [..._channels, ...channels];
        _loading = false;
      });
    } on Object {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _error = _channels.isEmpty;
      });
    }
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadMore(_requestId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;

    if (_loading && _channels.isEmpty) {
      return Center(
        child: TestId(
          ChatTestIds.listLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_error && _channels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TestId(
                ChatTestIds.listError,
                child: Text(
                  l10n.chatListLoadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: n.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              TestId(
                ChatTestIds.listRetry,
                child: FilledButton(
                  onPressed: _reload,
                  child: Text(l10n.retryAction),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_channels.isEmpty) {
      return Center(
        child: TestId(
          ChatTestIds.empty,
          child: Consumer(
            builder: (context, ref, _) => Text(
              ref.msg(MessageKeys.chatNoRoomsText, l10n.chatNoRoomsText),
              textAlign: TextAlign.center,
              style: TextStyle(color: n.textSecondary),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _channels.length,
        itemBuilder: (context, index) {
          final channel = _channels[index];
          return _ChannelRow(
            channel: channel,
            onTap: () => widget.onOpen(channel.channelUrl),
          );
        },
      ),
    );
  }
}

bool _listEquals(List<String>? a, List<String>? b) {
  final aa = a ?? const <String>[];
  final bb = b ?? const <String>[];
  if (aa.length != bb.length) return false;
  for (var i = 0; i < aa.length; i++) {
    if (aa[i] != bb[i]) return false;
  }
  return true;
}

/// One row of the channel list (native `CustomChannelListAdapter`): the
/// resolved avatar/icon, the resolved title (falling back to "Unknown" —
/// native's own fallback for this exact row, unlike the header's richer
/// fallback chain), the last message preview and its time, and an unread
/// badge.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.onTap});

  final GroupChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final myId = SendbirdChat.currentUser?.userId;
    final display = resolveChannelDisplay(channel, myUserId: myId);
    final lastMessage = channel.lastMessage?.message ?? '';
    final time = channel.lastMessage != null
        ? DateFormat.jm().format(
            DateTime.fromMillisecondsSinceEpoch(channel.lastMessage!.createdAt),
          )
        : null;
    final unread = channel.unreadMessageCount;
    return Consumer(
      builder: (context, ref, _) {
        final l10n = AppLocalizations.of(context);
        return TestId(
          ChatTestIds.row(channel.channelUrl),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ChatAvatar(
                    avatarUrl: display.avatarUrl,
                    iconAsset: display.iconAsset,
                    iconBackground: display.iconBackground,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          display.title.isNotEmpty
                              ? display.title
                              : ref.msg(
                                  MessageKeys.globalUnknown,
                                  l10n.chatUnknownChannel,
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: n.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (lastMessage.isNotEmpty)
                          Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: n.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (time != null)
                        Text(
                          time,
                          style: TextStyle(
                            color: n.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      if (unread > 0) ...[
                        const SizedBox(height: 4),
                        Badge(label: Text(unread > 99 ? '99+' : '$unread')),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
