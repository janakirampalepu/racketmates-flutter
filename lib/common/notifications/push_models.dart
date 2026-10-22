/// Notification permission as the platform reports it.
enum PushPermission { granted, denied, notDetermined }

/// A push notification: its title and text (the `notification` part) and the
/// data payload (`navigation_page`, `event_id`, ...). Values arrive as strings.
class PushMessage {
  const PushMessage({this.id, this.title, this.body, this.data = const {}});

  factory PushMessage.fromMap(Map<Object?, Object?> map) {
    final rawData = map['data'];
    return PushMessage(
      id: map['id']?.toString(),
      title: map['title'] as String?,
      body: map['body'] as String?,
      data: {
        if (rawData is Map)
          for (final e in rawData.entries)
            if (e.key != null && e.value != null)
              e.key.toString(): e.value.toString(),
      },
    );
  }

  /// Backend/FCM message id, used to show a notification only once.
  final String? id;
  final String? title;
  final String? body;
  final Map<String, String> data;
}

/// Where a notification takes the user (native `navigation_page` values).
sealed class NotificationRoute {
  const NotificationRoute();
}

class OpenHome extends NotificationRoute {
  const OpenHome();
}

class OpenEvent extends NotificationRoute {
  const OpenEvent(this.eventId);

  final int eventId;
}

class OpenTeam extends NotificationRoute {
  const OpenTeam(this.teamId);

  final int teamId;
}

class OpenTeams extends NotificationRoute {
  const OpenTeams();
}

/// A chat message (Sendbird payload): the chat tab until the chat milestone
/// can open the channel.
class OpenChat extends NotificationRoute {
  const OpenChat({this.channelUrl});

  final String? channelUrl;
}

/// Maps a payload to a destination. Never fails: anything unknown or
/// malformed opens home (native falls back to the home page too).
///
/// `navigation_page`: `nnp_event_details_page`, `nnp_event_updated_details_page`,
/// `nnp_update_availability_page` and `nnp_event_options_preference_page` open
/// the event (`event_id`); `nnp_team_details_page` the team (`team_id`);
/// `nnp_team_list_page` the teams tab; `nnp_home_page` and the league pages
/// (leagues are not part of this app yet) home.
NotificationRoute routeForNotification(Map<String, String> data) {
  if (data.containsKey('sendbird')) {
    return OpenChat(channelUrl: data['channel_url']);
  }
  switch (data['navigation_page']) {
    case 'nnp_event_details_page' ||
        'nnp_event_updated_details_page' ||
        'nnp_update_availability_page' ||
        'nnp_event_options_preference_page':
      final id = int.tryParse(data['event_id'] ?? '');
      return id == null ? const OpenHome() : OpenEvent(id);
    case 'nnp_team_details_page':
      final id = int.tryParse(data['team_id'] ?? '');
      return id == null ? const OpenTeams() : OpenTeam(id);
    case 'nnp_team_list_page':
      return const OpenTeams();
    default:
      return const OpenHome();
  }
}
