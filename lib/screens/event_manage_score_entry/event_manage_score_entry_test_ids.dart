abstract final class EventManageScoreEntryTestIds {
  static const root = 'event_manage_score_entry_screen';
  static const title = 'event_manage_score_entry_title';
  static const save = 'event_manage_score_save_button';
  static const unfinished = 'event_manage_score_unfinished_switch';
  static const clearUnfinished = 'event_manage_clear_unfinished';
  static const winning = 'event_manage_score_winning';
  static const error = 'event_manage_score_error';

  /// `event_manage_score_<set>_top` / `_bottom` (set 1-based).
  static String top(int set) => 'event_manage_score_${set}_top';
  static String bottom(int set) => 'event_manage_score_${set}_bottom';
}
