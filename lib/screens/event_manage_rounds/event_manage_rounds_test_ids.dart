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

  /// `event_manage_rounds_court_<placeCourtId>` (court picker).
  static String court(int id) => 'event_manage_rounds_court_$id';
}
