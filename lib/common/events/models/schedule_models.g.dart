// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleListResponse _$ScheduleListResponseFromJson(
  Map<String, dynamic> json,
) => ScheduleListResponse(
  scheduleItems: (json['schedule_items'] as List<dynamic>?)
      ?.map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : ScheduleMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ScheduleListResponseToJson(
  ScheduleListResponse instance,
) => <String, dynamic>{
  'schedule_items': instance.scheduleItems,
  'meta': instance.meta,
};

ScheduleMeta _$ScheduleMetaFromJson(Map<String, dynamic> json) => ScheduleMeta(
  otherEvents: json['other_events'] == null
      ? null
      : OtherEvents.fromJson(json['other_events'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ScheduleMetaToJson(ScheduleMeta instance) =>
    <String, dynamic>{'other_events': instance.otherEvents};

OtherEvents _$OtherEventsFromJson(Map<String, dynamic> json) => OtherEvents(
  draftsLabel: json['drafts_label'] as String?,
  toBeRescheduledLabel: json['to_be_rescheduled_label'] as String?,
);

Map<String, dynamic> _$OtherEventsToJson(OtherEvents instance) =>
    <String, dynamic>{
      'drafts_label': instance.draftsLabel,
      'to_be_rescheduled_label': instance.toBeRescheduledLabel,
    };

ScheduleItem _$ScheduleItemFromJson(Map<String, dynamic> json) => ScheduleItem(
  eventId: (json['event_id'] as num?)?.toInt(),
  eventDate: json['event_date'] as String?,
  eventStatus: json['event_status'] as String?,
  eventStatusLabel: json['event_status_label'] as String?,
  eventType: json['event_type'] as String?,
  sportType: json['sport_type'] as String?,
  participantStatus: json['participant_status'] as String?,
  participantStatusLabel: json['participant_status_label'] as String?,
  pastEventStatus: json['past_event_status'] as String?,
  pastEventStatusLabel: json['past_event_status_label'] as String?,
  placeId: (json['place_id'] as num?)?.toInt(),
  placeName: json['place_name'] as String?,
  teamId: (json['team_id'] as num?)?.toInt(),
  notes: json['notes'] as String?,
  courtsLabel: json['courts_label'] as String?,
  timeSlot: json['time_slot'] as String?,
  coachLabel: json['coach_label'] as String?,
  startTimeText: json['start_time_text'] as String?,
  endTimeText: json['end_time_text'] as String?,
  userParticipantCount: (json['user_participant_count'] as num?)?.toInt(),
  waitlistNumber: (json['waitlist_number'] as num?)?.toInt(),
  additionalTimings: (json['additional_timings'] as num?)?.toInt(),
  additionalVenues: (json['additional_venues'] as num?)?.toInt(),
  additionalParticipants: (json['additional_participants'] as num?)?.toInt(),
  onMultipleDates: json['on_multiple_dates'] as bool?,
  eventUsers: (json['event_users'] as List<dynamic>?)
      ?.map((e) => AppUser.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ScheduleItemToJson(ScheduleItem instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'event_date': instance.eventDate,
      'event_status': instance.eventStatus,
      'event_status_label': instance.eventStatusLabel,
      'event_type': instance.eventType,
      'sport_type': instance.sportType,
      'participant_status': instance.participantStatus,
      'participant_status_label': instance.participantStatusLabel,
      'past_event_status': instance.pastEventStatus,
      'past_event_status_label': instance.pastEventStatusLabel,
      'place_id': instance.placeId,
      'place_name': instance.placeName,
      'team_id': instance.teamId,
      'notes': instance.notes,
      'courts_label': instance.courtsLabel,
      'time_slot': instance.timeSlot,
      'coach_label': instance.coachLabel,
      'start_time_text': instance.startTimeText,
      'end_time_text': instance.endTimeText,
      'user_participant_count': instance.userParticipantCount,
      'waitlist_number': instance.waitlistNumber,
      'additional_timings': instance.additionalTimings,
      'additional_venues': instance.additionalVenues,
      'additional_participants': instance.additionalParticipants,
      'on_multiple_dates': instance.onMultipleDates,
      'event_users': instance.eventUsers,
    };
