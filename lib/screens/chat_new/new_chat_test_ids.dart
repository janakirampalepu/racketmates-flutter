abstract final class NewChatTestIds {
  static const root = 'new_chat_screen';
  static const title = 'new_chat_title';
  static const close = 'new_chat_close_button';
  static const search = 'new_chat_search_field';
  static const loading = 'new_chat_loading';
  static const empty = 'new_chat_empty';
  static const error = 'new_chat_error';
  static const retry = 'new_chat_retry_button';
  static const failed = 'new_chat_failed';
  static const starting = 'new_chat_starting';

  /// `new_chat_player_<id>`.
  static String player(int id) => 'new_chat_player_$id';
}

abstract final class EventChatTestIds {
  static const button = 'event_chat_button';
  static const sheet = 'event_chat_sheet';
  static const players = 'event_chat_players_option';
  static const captains = 'event_chat_captains_option';
  static const blockedDialog = 'event_chat_blocked_dialog';
  static const blockedClose = 'event_chat_blocked_close';
  static const opening = 'event_chat_opening';
}
