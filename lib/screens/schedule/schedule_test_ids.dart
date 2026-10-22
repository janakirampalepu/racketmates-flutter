abstract final class ScheduleTestIds {
  static const root = 'schedule_screen';
  static String tab(String name) => 'schedule_tab_$name';
  static String list(String name) => 'schedule_list_$name';
  static String empty(String name) => 'schedule_empty_$name';
  static String retry(String name) => 'schedule_retry_$name';
  static String loadingMore(String name) => 'schedule_loading_more_$name';
  static String event(String tab, int id) => 'schedule_${tab}_event_$id';
}
