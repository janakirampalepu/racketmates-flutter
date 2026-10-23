abstract final class EventManageScheduleTestIds {
  static const error = 'event_manage_schedule_error';
  static const matches = 'event_manage_schedule_matches';
  static const matchesTitle = 'event_manage_schedule_matches_title';

  /// `event_manage_schedule_match_<id>`.
  static String match(int id) => 'event_manage_schedule_match_$id';
}
