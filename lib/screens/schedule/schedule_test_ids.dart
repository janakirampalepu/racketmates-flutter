abstract final class ScheduleTestIds {
  static const root = 'schedule_screen';
  static const createEvent = 'schedule_create_event_fab';
  static const filterButton = 'schedule_filter_button';
  static const toBeScheduledButton = 'schedule_to_be_scheduled_button';
  static String tab(String name) => 'schedule_tab_$name';
  static String list(String name) => 'schedule_list_$name';
  static String empty(String name) => 'schedule_empty_$name';
  static String retry(String name) => 'schedule_retry_$name';
  static String loadingMore(String name) => 'schedule_loading_more_$name';
  static String event(String tab, int id) => 'schedule_${tab}_event_$id';
}

/// The owner/sport filter sheet shared by the global Schedule and the Team
/// Schedule tab (native `EventFilterPicker`).
abstract final class ScheduleFilterTestIds {
  static const sheet = 'schedule_filter_sheet';
  static const ownerManaging = 'schedule_filter_owner_managing';
  static const ownerParticipant = 'schedule_filter_owner_participant';
  static const apply = 'schedule_filter_apply';
  static String sport(String key) => 'schedule_filter_sport_$key';
}

/// The "events to be rescheduled" screen (native's `btnToBeScheduledEvent`
/// destination).
abstract final class ToBeScheduledTestIds {
  static const root = 'to_be_scheduled_screen';
  static const empty = 'to_be_scheduled_empty';
  static const error = 'to_be_scheduled_error';
  static const retry = 'to_be_scheduled_retry';
  static String event(int id) => 'to_be_scheduled_event_$id';
}
