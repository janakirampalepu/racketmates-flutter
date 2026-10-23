abstract final class EventDetailsTestIds {
  static const root = 'event_details_screen';
  static const title = 'event_details_title';
  static const status = 'event_details_status';
  static const when = 'event_details_when';
  static const where = 'event_details_where';
  static const yourStatus = 'event_details_your_status';
  static const spots = 'event_details_spots';
  static const notes = 'event_details_notes';
  static const players = 'event_details_players';
  static const retry = 'event_details_retry';
  static const back = 'event_details_back_button';
  static const actionBar = 'event_details_action_bar';
  static const menu = 'event_details_menu';
  static const menuManageEvent = 'event_details_menu_manage_event';
  static const menuCancelEvent = 'event_details_menu_cancel_event';
  static const confirmButton = 'event_details_confirm_button';
  static const confirmDismissButton = 'event_details_confirm_dismiss_button';
  static const unsupportedNote = 'event_details_unsupported_note';
  static const cancelReason = 'event_cancel_reason_field';
  static const cancelRemoveSwitch = 'event_cancel_remove_switch';
  static const cancelConfirm = 'event_cancel_confirm_button';
  static const cancelKeep = 'event_cancel_keep_button';
  static const confirmScores = 'event_details_confirm_scores_button';
  static const prefsSheet = 'event_prefs_sheet';
  static const prefsSubmit = 'event_prefs_submit_button';
  static const prefsNotes = 'event_prefs_notes_field';
  static const prefsSelectPartner = 'event_prefs_select_partner_button';
  static const prefsChangePartner = 'event_prefs_change_partner_button';
  static const prefsPartner = 'event_prefs_partner';
  static const partnerSearch = 'event_partner_search_field';
  static const partnerNone = 'event_partner_none';
  static const partnerSelect = 'event_partner_select_button';
  static const partnerError = 'event_partner_error';
  static const partnerSection = 'event_details_partner_section';
  static const partnerEdit = 'event_details_partner_edit_button';
  static const partnerChoose = 'event_details_partner_choose_button';

  /// `event_prefs_match_<key>` and `event_prefs_partner_type_<key>`.
  static String prefsMatch(String key) => 'event_prefs_match_$key';
  static String prefsPartnerType(String key) => 'event_prefs_partner_type_$key';

  /// `event_partner_option_<participantId>`.
  static String partnerOption(int id) => 'event_partner_option_$id';
  static String player(int id) => 'event_details_player_$id';
  static String action(String name) => 'event_details_action_$name';
}
