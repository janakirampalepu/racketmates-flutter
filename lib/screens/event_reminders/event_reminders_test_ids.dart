abstract final class EventRemindersTestIds {
  static const root = 'reminders_screen';
  static const title = 'reminders_title';
  static const add = 'reminders_add_button';
  static const empty = 'reminders_empty';
  static const error = 'reminders_error';
  static const retry = 'reminders_retry';
  static const failed = 'reminders_failed';
  static const sheet = 'reminder_add_sheet';
  static const value = 'reminder_value_field';
  static const preview = 'reminder_preview';
  static const save = 'reminder_save_button';

  /// `reminder_<id>`.
  static String reminder(int id) => 'reminder_$id';

  /// `reminder_<id>_remove`.
  static String remove(int id) => 'reminder_${id}_remove';

  /// `reminder_unit_<rut_minute|rut_hour|rut_day>`.
  static String unit(String key) => 'reminder_unit_$key';
}
