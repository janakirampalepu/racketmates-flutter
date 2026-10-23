abstract final class EventManageRoundsTestIds {
  static const root = 'event_manage_rounds_screen';
  static const title = 'event_manage_rounds_title';
  static const empty = 'event_manage_rounds_empty';
  static const error = 'event_manage_rounds_error';
  static const add = 'event_manage_rounds_add_button';
  static const remove = 'event_manage_rounds_remove_button';
  static const confirmYes = 'event_manage_rounds_confirm_yes_button';
  static const confirmNo = 'event_manage_rounds_confirm_no_button';
  static const courtNone = 'event_manage_rounds_court_none';
  static const waitingOk = 'event_manage_rounds_waiting_ok_button';

  /// `event_manage_round_<id>` (the round chip).
  static String round(int id) => 'event_manage_round_$id';

  /// `event_manage_round_match_<id>` and its menu entries.
  static String match(int id) => 'event_manage_round_match_$id';
  static String matchMenu(int id) => 'event_manage_round_match_${id}_menu';
  static String matchCourt(int id) => 'event_manage_round_match_${id}_court';
  static String matchRemove(int id) => 'event_manage_round_match_${id}_remove';

  static const assignSearch = 'event_manage_rounds_assign_search';
  static const assignSave = 'event_manage_rounds_assign_save_button';
  static const assignNone = 'event_manage_rounds_assign_none';
  static const assignError = 'event_manage_rounds_assign_error';

  /// `event_manage_rounds_side_<sideId>` (tap to assign players).
  static String side(int id) => 'event_manage_rounds_side_$id';

  /// `event_manage_rounds_assign_player_<userId>`.
  static String assignPlayer(int id) => 'event_manage_rounds_assign_player_$id';

  /// `event_manage_rounds_court_<placeCourtId>` (court picker).
  static String court(int id) => 'event_manage_rounds_court_$id';
}
