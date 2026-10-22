import 'package:racketmates/common/settings/settings_models.dart';

/// Values a reminder can take per unit (native `RemainderAddPicker`): 5 to 55
/// minutes in steps of five, 1 to 23 hours, 1 to 28 days.
List<int> reminderValuesFor(String unit) => switch (unit) {
  ReminderUnits.minute => [for (var i = 5; i <= 55; i += 5) i],
  ReminderUnits.hour => [for (var i = 1; i <= 23; i++) i],
  ReminderUnits.day => [for (var i = 1; i <= 28; i++) i],
  _ => const [],
};

/// Body of `POST user_reminder_preferences` (native `CreateRrmainderRequest`).
Map<String, dynamic> buildReminderBody({
  required int value,
  required String unit,
}) {
  if (!reminderValuesFor(unit).contains(value)) {
    throw ArgumentError('$value is not a valid number of $unit');
  }
  return {
    'user_reminder_preference': {
      'reminder_unit': value,
      'reminder_unit_type': unit,
    },
  };
}
