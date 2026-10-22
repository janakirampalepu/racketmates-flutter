abstract final class CreateEventSettingsTestIds {
  static const root = 'create_event_settings_screen';
  static const title = 'create_event_settings_title';
  static const next = 'create_event_settings_next_button';
  static const unitHours = 'create_event_deadline_hours';
  static const unitDays = 'create_event_deadline_days';
  static const deadlineValue = 'create_event_deadline_value';
  static const deadlineDecrease = 'create_event_deadline_decrease';
  static const deadlineIncrease = 'create_event_deadline_increase';
  static const allowManage = 'create_event_allow_manage_switch';
  static const allowLogResults = 'create_event_allow_log_results_switch';
  static const scoringError = 'create_event_scoring_error';
  static const scoringRetry = 'create_event_scoring_retry';
  static const scoringLoading = 'create_event_scoring_loading';
  static const scoreDecrease = 'create_event_score_decrease';
  static const scoreValue = 'create_event_score_value';
  static const scoreIncrease = 'create_event_score_increase';
  static const scoreMinutes = 'create_event_score_minutes';
  static const scoreIdPrefix = 'create_event_score';

  /// `create_event_scoring_format_<key>`.
  static String format(String key) => 'create_event_scoring_format_$key';

  /// `create_event_deciding_set_<key>`.
  static String decidingSet(String key) => 'create_event_deciding_set_$key';
  static const considerRanking = 'create_event_consider_ranking_switch';
}
