// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReminderPreference _$ReminderPreferenceFromJson(Map<String, dynamic> json) =>
    ReminderPreference(
      id: (json['id'] as num?)?.toInt(),
      reminderUnit: (json['reminder_unit'] as num?)?.toInt(),
      reminderUnitType: json['reminder_unit_type'] as String?,
      reminderDuration: (json['reminder_duration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ReminderPreferenceToJson(ReminderPreference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reminder_unit': instance.reminderUnit,
      'reminder_unit_type': instance.reminderUnitType,
      'reminder_duration': instance.reminderDuration,
    };

RemindersResponse _$RemindersResponseFromJson(Map<String, dynamic> json) =>
    RemindersResponse(
      userReminderPreferences:
          (json['user_reminder_preferences'] as List<dynamic>?)
              ?.map(
                (e) => e == null
                    ? null
                    : ReminderPreference.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );

Map<String, dynamic> _$RemindersResponseToJson(RemindersResponse instance) =>
    <String, dynamic>{
      'user_reminder_preferences': instance.userReminderPreferences,
    };
