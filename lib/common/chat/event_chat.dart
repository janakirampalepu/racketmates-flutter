import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/session/access.dart';

enum EventChatKind { players, captains }

/// A chat room the user can open from an event, with what access rule applies
/// (native `ViewEventDetailsFragment.getPlayersChatRoom` / `getCaptainsChatRoom`).
class EventChatOption {
  const EventChatOption({
    required this.kind,
    required this.decision,
    this.message,
    this.channelUrl,
  });

  final EventChatKind kind;

  /// Go ahead, offer the subscription, or explain why not.
  final AccessDecision decision;

  /// The server's explanation for a disabled room.
  final String? message;

  /// The room's channel when it already exists; null means it is created on
  /// first use.
  final String? channelUrl;
}

const _playersKey = 'event.show_players_chat_room';
const _captainsKey = 'event.show_captains_chat_room';

/// The team of [userId] in a team event: their own participation, else their
/// entry in the participant list, else the event's first team (native
/// `getLoginUserEventTeam`). Null for events without teams.
int? loginTeamId(EventDetails event, int? userId) {
  final own = event.currentUserEventDetails
      ?.map((d) => d.teamId)
      .whereType<int>()
      .firstOrNull;
  if (own != null) return own;
  final listed = event.eventParticipants
      ?.where((p) => p.userId == userId || p.user?.id == userId)
      .map((p) => p.teamId)
      .whereType<int>()
      .firstOrNull;
  if (listed != null) return listed;
  if (!event.isTeamEvent) return null;
  return event.eventTeams?.map((t) => t.team?.id).whereType<int>().firstOrNull;
}

/// The chat rooms the permissions allow, players first. A room whose
/// permission is missing or `up_not_available` is not offered.
List<EventChatOption> eventChatOptions(
  EventDetails event, {
  required bool subscribed,
  int? userId,
}) {
  EventChatOption? option(EventChatKind kind, String key, String? url) {
    final info = event.permission(key);
    if (info == null || info.access == 'up_not_available') return null;
    return EventChatOption(
      kind: kind,
      decision: decideAccess(info, subscribed: subscribed),
      message: info.message,
      channelUrl: url == null || url.isEmpty ? null : url,
    );
  }

  final teamId = loginTeamId(event, userId);
  final teamRoom = event.eventTeams
      ?.where((t) => t.team?.id == teamId)
      .map((t) => t.playersChatRoom?.channelUrl)
      .whereType<String>()
      .firstOrNull;
  return [
    ?option(
      EventChatKind.players,
      _playersKey,
      event.playerChatRoom?.channelUrl ?? teamRoom,
    ),
    ?option(
      EventChatKind.captains,
      _captainsKey,
      event.captainsChatRoom?.channelUrl,
    ),
  ];
}
