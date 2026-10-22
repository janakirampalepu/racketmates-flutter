abstract final class EventManagePlayersTestIds {
  static const root = 'event_manage_people_screen';
  static const title = 'event_manage_people_title';
  static const addPlayers = 'event_manage_add_players_button';
  static const addCoaches = 'event_manage_add_coaches_button';
  static const remove = 'event_manage_remove_button';
  static const confirm = 'event_manage_confirm_button';
  static const error = 'event_manage_people_error';
  static const empty = 'event_manage_people_empty';
  static const dialogConfirm = 'event_manage_remove_confirm';
  static const dialogDismiss = 'event_manage_remove_dismiss';

  /// `event_manage_participant_<userId>`.
  static String participant(int userId) => 'event_manage_participant_$userId';

  /// `event_manage_group_<confirmed|to_be_confirmed|...>`.
  static String group(String name) => 'event_manage_group_$name';
}
