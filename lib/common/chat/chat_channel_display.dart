import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';

/// `chat_room_type` values the backend writes into a channel's `data`
/// JSON blob (native `SendbirdDataResponse.chatRoomType`).
abstract final class ChatRoomTypes {
  static const direct = 'crt_direct';
  static const support = 'crt_support';
  static const event = 'crt_event';
  static const teamEvent = 'crt_team_event';
  static const announcements = 'crt_announcements';
  static const announcementsInternal = 'crt_announcements_internal';
}

/// Where a fallback icon's circle color comes from — resolved against
/// [NativePalette] by the caller, since this file has no `BuildContext`.
enum ChatIconBackground {
  /// 1:1/support without a photo, and the "unknown"/no-data case: the icon
  /// asset already bakes in its own neutral gray circle, no wrapper needed.
  none,

  /// Group/team/announcement/casual-meeting channels (native `chat_room_
  /// background`).
  chatRoom,

  /// A named-sport event channel (native `background_solid_green_5`).
  sportGreen,
}

/// What a channel list row or header should show: a title and either a
/// real photo URL or a fallback icon (native `getGroupChannelItemTitle`/
/// `getGroupChannelProfileURL`/`getEventChatIconRes` in `TextUtils.kt`,
/// confirmed to match iOS's `GroupChannel+Extensions.swift` exactly).
class ChatChannelDisplay {
  const ChatChannelDisplay({
    required this.title,
    required this.iconAsset,
    required this.iconBackground,
    this.avatarUrl,
  });

  /// Empty when `channel.data` is missing/unreadable — native leaves this
  /// to each call site's own fallback (the list row shows "Unknown", the
  /// header falls back to the channel name/member list).
  final String title;
  final String? avatarUrl;
  final String iconAsset;
  final ChatIconBackground iconBackground;
}

class _ChannelData {
  const _ChannelData({this.chatRoomType, this.startTime, this.sportType});

  final String? chatRoomType;
  final DateTime? startTime;
  final String? sportType;
}

/// `channel.data` is sometimes wrapped in an extra layer of JSON-string
/// quoting/escaping (native strips this the same way before decoding).
_ChannelData? _parse(String raw) {
  var s = raw.trim();
  if (s.isEmpty || s == 'null') return null;
  if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
    s = s.substring(1, s.length - 1).replaceAll(r'\"', '"');
  }
  try {
    final json = jsonDecode(s);
    if (json is! Map) return null;
    final rawStart = json['start_time'];
    DateTime? start;
    if (rawStart is num) {
      start = DateTime.fromMillisecondsSinceEpoch(rawStart.toInt());
    } else if (rawStart is String && rawStart.isNotEmpty) {
      start = DateTime.tryParse(rawStart);
    }
    return _ChannelData(
      chatRoomType: json['chat_room_type'] as String?,
      startTime: start,
      sportType: json['sport_type'] as String?,
    );
  } on FormatException {
    return null;
  }
}

String _nameOf(User user) =>
    user.nickname.isNotEmpty ? user.nickname : user.userId;

/// The title native computes for [channel] (`getGroupChannelItemTitle`):
/// the other member's name for a 1:1/support chat, "{date} (name)" for an
/// event with a start time, else the channel's own name. Empty when
/// `channel.data` is missing or unreadable.
String _resolveTitle(
  GroupChannel channel,
  _ChannelData? data,
  String? myUserId,
) {
  if (data == null) return '';
  switch (data.chatRoomType) {
    case ChatRoomTypes.direct:
    case ChatRoomTypes.support:
      if (channel.members.length != 2) return '';
      final other = channel.members.firstWhere(
        (m) => m.userId != myUserId,
        orElse: () => channel.members.first,
      );
      final first = other.metaData['first_name'] ?? '';
      final last = other.metaData['last_name'] ?? '';
      final name = '$first $last'.trim();
      return name.isNotEmpty ? name : _nameOf(other);
    case ChatRoomTypes.event:
    case ChatRoomTypes.teamEvent:
      final startTime = data.startTime;
      if (startTime == null) return channel.name;
      final day = DateFormat('MMM dd').format(startTime);
      return '$day (${channel.name})';
    default:
      return channel.name;
  }
}

String? _resolveAvatarUrl(
  GroupChannel channel,
  _ChannelData? data,
  String? myUserId,
) {
  final type = data?.chatRoomType;
  if (type != ChatRoomTypes.direct && type != ChatRoomTypes.support) {
    return null;
  }
  for (final m in channel.members) {
    if (m.userId != myUserId && m.profileUrl.isNotEmpty) return m.profileUrl;
  }
  return null;
}

({String asset, ChatIconBackground background}) _resolveIcon(
  _ChannelData? data,
) {
  if (data == null) {
    return (asset: 'ic_chat_unknown', background: ChatIconBackground.none);
  }
  switch (data.chatRoomType) {
    case ChatRoomTypes.direct:
    case ChatRoomTypes.support:
      return (asset: 'ic_profile_picture', background: ChatIconBackground.none);
    case ChatRoomTypes.event:
    case ChatRoomTypes.teamEvent:
      final sport = SportKey.fromKey(data.sportType ?? '');
      final asset = switch (sport) {
        SportKey.tennis => 'ic_chat_tennis',
        SportKey.pickleball => 'ic_chat_pickleball',
        SportKey.padel => 'ic_chat_padel',
        SportKey.badminton => 'ic_chat_badminton',
        null => 'ic_chat_casual_meeting',
      };
      return (
        asset: asset,
        background: sport == null
            ? ChatIconBackground.chatRoom
            : ChatIconBackground.sportGreen,
      );
    case ChatRoomTypes.announcements:
    case ChatRoomTypes.announcementsInternal:
      return (
        asset: 'ic_announcements_icon',
        background: ChatIconBackground.chatRoom,
      );
    default:
      return (asset: 'ic_group_chat', background: ChatIconBackground.chatRoom);
  }
}

/// Resolves [channel]'s title, photo and fallback icon the same way native
/// does, instead of the Sendbird UIKit's own generic rule (channel name,
/// else member nicknames; a photo or nothing).
ChatChannelDisplay resolveChannelDisplay(
  GroupChannel channel, {
  String? myUserId,
}) {
  final data = _parse(channel.data);
  final icon = _resolveIcon(data);
  return ChatChannelDisplay(
    title: _resolveTitle(channel, data, myUserId),
    avatarUrl: _resolveAvatarUrl(channel, data, myUserId),
    iconAsset: icon.asset,
    iconBackground: icon.background,
  );
}
