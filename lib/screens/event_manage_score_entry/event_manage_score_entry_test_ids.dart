abstract final class EventManageScoreEntryTestIds {
  static const root = 'event_manage_score_entry_screen';
  static const title = 'event_manage_score_entry_title';
  static const save = 'event_manage_score_save_button';
  static const unfinished = 'event_manage_score_unfinished_switch';
  static const clearUnfinished = 'event_manage_clear_unfinished';
  static const winning = 'event_manage_score_winning';
  static const error = 'event_manage_score_error';

  static const matchTieBreakTop = 'event_manage_score_mtb_top';
  static const matchTieBreakBottom = 'event_manage_score_mtb_bottom';
  static const decidingPrompt = 'event_manage_score_deciding_prompt';

  /// `event_manage_score_deciding_<dst_key>`.
  static String deciding(String key) => 'event_manage_score_deciding_$key';

  /// `event_manage_score_<set>_tb_top` / `_tb_bottom`.
  static String tieBreakTop(int set) => 'event_manage_score_${set}_tb_top';
  static String tieBreakBottom(int set) =>
      'event_manage_score_${set}_tb_bottom';

  /// `event_manage_score_<set>_top` / `_bottom` (set 1-based).
  static String top(int set) => 'event_manage_score_${set}_top';
  static String bottom(int set) => 'event_manage_score_${set}_bottom';
}
