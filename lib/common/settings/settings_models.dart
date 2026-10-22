import 'package:json_annotation/json_annotation.dart';

part 'settings_models.g.dart';

/// Units of an event reminder (native `AppConstants.REMAINDER_UNIT_*`).
abstract final class ReminderUnits {
  static const minute = 'rut_minute';
  static const hour = 'rut_hour';
  static const day = 'rut_day';
  static const all = [minute, hour, day];
}

/// One "remind me X before an event" preference.
@JsonSerializable(fieldRename: FieldRename.snake)
class ReminderPreference {
  const ReminderPreference({
    this.id,
    this.reminderUnit,
    this.reminderUnitType,
    this.reminderDuration,
  });

  factory ReminderPreference.fromJson(Map<String, dynamic> json) =>
      _$ReminderPreferenceFromJson(json);

  final int? id;
  final int? reminderUnit;

  /// `rut_minute`, `rut_hour` or `rut_day`.
  final String? reminderUnitType;
  final int? reminderDuration;

  Map<String, dynamic> toJson() => _$ReminderPreferenceToJson(this);
}

/// `GET users/{id}/user_reminder_preferences`.
@JsonSerializable(fieldRename: FieldRename.snake)
class RemindersResponse {
  const RemindersResponse({this.userReminderPreferences});

  factory RemindersResponse.fromJson(Map<String, dynamic> json) =>
      _$RemindersResponseFromJson(json);

  final List<ReminderPreference?>? userReminderPreferences;

  Map<String, dynamic> toJson() => _$RemindersResponseToJson(this);
}
