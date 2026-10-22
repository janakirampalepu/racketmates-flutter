// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventDetailsResponse _$EventDetailsResponseFromJson(
  Map<String, dynamic> json,
) => EventDetailsResponse(
  message: json['message'] as String?,
  result: json['result'] as String?,
  event: json['event'] == null
      ? null
      : EventDetails.fromJson(json['event'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EventDetailsResponseToJson(
  EventDetailsResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'result': instance.result,
  'event': instance.event,
};

EventDetails _$EventDetailsFromJson(Map<String, dynamic> json) => EventDetails(
  id: (json['id'] as num?)?.toInt(),
  eventType: json['event_type'] as String?,
  sportType: json['sport_type'] as String?,
  status: json['status'] as String?,
  notesForEvent: json['notes_for_event'] as String?,
  rsvpStatus: json['rsvp_status'] as String?,
  playersLimit: (json['players_limit'] as num?)?.toInt(),
  regularSpotsLeft: (json['regular_spots_left'] as num?)?.toInt(),
  waitingListSpotsLeft: (json['waiting_list_spots_left'] as num?)?.toInt(),
  eventParticipantsCount: (json['event_participants_count'] as num?)?.toInt(),
  withCoach: json['with_coach'] as bool?,
  gameType: json['game_type'] as String?,
  partnershipType: json['partnership_type'] as String?,
  userPermissions: (json['user_permissions'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, AccessInfo.fromJson(e as Map<String, dynamic>)),
  ),
  eventScheduleOptions: (json['event_schedule_options'] as List<dynamic>?)
      ?.map((e) => EventScheduleOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  eventParticipants: (json['event_participants'] as List<dynamic>?)
      ?.map((e) => EventParticipant.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentUserEventDetails:
      (json['current_user_event_details'] as List<dynamic>?)
          ?.map(
            (e) => CurrentUserEventDetail.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
);

Map<String, dynamic> _$EventDetailsToJson(EventDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_type': instance.eventType,
      'sport_type': instance.sportType,
      'status': instance.status,
      'notes_for_event': instance.notesForEvent,
      'rsvp_status': instance.rsvpStatus,
      'players_limit': instance.playersLimit,
      'regular_spots_left': instance.regularSpotsLeft,
      'waiting_list_spots_left': instance.waitingListSpotsLeft,
      'event_participants_count': instance.eventParticipantsCount,
      'with_coach': instance.withCoach,
      'game_type': instance.gameType,
      'partnership_type': instance.partnershipType,
      'user_permissions': instance.userPermissions,
      'event_schedule_options': instance.eventScheduleOptions,
      'event_participants': instance.eventParticipants,
      'current_user_event_details': instance.currentUserEventDetails,
    };

EventScheduleOption _$EventScheduleOptionFromJson(Map<String, dynamic> json) =>
    EventScheduleOption(
      id: (json['id'] as num?)?.toInt(),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      placeId: (json['place_id'] as num?)?.toInt(),
      place: json['place'] == null
          ? null
          : EventPlace.fromJson(json['place'] as Map<String, dynamic>),
      optionNumber: (json['option_number'] as num?)?.toInt(),
      status: json['status'] as String?,
    );

Map<String, dynamic> _$EventScheduleOptionToJson(
  EventScheduleOption instance,
) => <String, dynamic>{
  'id': instance.id,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'duration': instance.duration,
  'place_id': instance.placeId,
  'place': instance.place,
  'option_number': instance.optionNumber,
  'status': instance.status,
};

EventPlace _$EventPlaceFromJson(Map<String, dynamic> json) => EventPlace(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  address: json['address'] as String?,
);

Map<String, dynamic> _$EventPlaceToJson(EventPlace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
    };

EventParticipant _$EventParticipantFromJson(Map<String, dynamic> json) =>
    EventParticipant(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      user: json['user'] == null
          ? null
          : AppUser.fromJson(json['user'] as Map<String, dynamic>),
      isOrganizer: json['is_organizer'] as bool?,
      isPlayer: json['is_player'] as bool?,
      isCoach: json['is_coach'] as bool?,
      status: json['status'] as String?,
      waitlistNumber: (json['waitlist_number'] as num?)?.toInt(),
      participantLabel: json['participant_label'] as String?,
    );

Map<String, dynamic> _$EventParticipantToJson(EventParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'user': instance.user,
      'is_organizer': instance.isOrganizer,
      'is_player': instance.isPlayer,
      'is_coach': instance.isCoach,
      'status': instance.status,
      'waitlist_number': instance.waitlistNumber,
      'participant_label': instance.participantLabel,
    };

CurrentUserEventDetail _$CurrentUserEventDetailFromJson(
  Map<String, dynamic> json,
) => CurrentUserEventDetail(
  eventParticipantId: (json['event_participant_id'] as num?)?.toInt(),
  isPlayer: json['is_player'] as bool?,
  isCoach: json['is_coach'] as bool?,
  isManager: json['is_manager'] as bool?,
  status: json['status'] as String?,
  statusTitle: json['status_title'] as String?,
  statusSubText: json['status_sub_text'] as String?,
  user: json['user'] == null
      ? null
      : AppUser.fromJson(json['user'] as Map<String, dynamic>),
  primaryAction: json['primary_action'] == null
      ? null
      : EventAction.fromJson(json['primary_action'] as Map<String, dynamic>),
  secondaryAction: json['secondary_action'] == null
      ? null
      : EventAction.fromJson(json['secondary_action'] as Map<String, dynamic>),
  groupedEventScheduleOptions:
      (json['grouped_event_schedule_options'] as List<dynamic>?)
          ?.map(
            (e) => GroupedScheduleOption.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  selectedScheduleOptionIds:
      (json['selected_schedule_option_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
  showRsvpStatus: json['show_rsvp_status'] as bool?,
);

Map<String, dynamic> _$CurrentUserEventDetailToJson(
  CurrentUserEventDetail instance,
) => <String, dynamic>{
  'event_participant_id': instance.eventParticipantId,
  'is_player': instance.isPlayer,
  'is_coach': instance.isCoach,
  'is_manager': instance.isManager,
  'status': instance.status,
  'status_title': instance.statusTitle,
  'status_sub_text': instance.statusSubText,
  'user': instance.user,
  'primary_action': instance.primaryAction,
  'secondary_action': instance.secondaryAction,
  'grouped_event_schedule_options': instance.groupedEventScheduleOptions,
  'selected_schedule_option_ids': instance.selectedScheduleOptionIds,
  'show_rsvp_status': instance.showRsvpStatus,
};

AccessInfo _$AccessInfoFromJson(Map<String, dynamic> json) => AccessInfo(
  access: json['access'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$AccessInfoToJson(AccessInfo instance) =>
    <String, dynamic>{'access': instance.access, 'message': instance.message};

EventAction _$EventActionFromJson(Map<String, dynamic> json) => EventAction(
  action: json['action'] as String?,
  access: json['access'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$EventActionToJson(EventAction instance) =>
    <String, dynamic>{
      'action': instance.action,
      'access': instance.access,
      'message': instance.message,
    };

GroupedScheduleOption _$GroupedScheduleOptionFromJson(
  Map<String, dynamic> json,
) => GroupedScheduleOption(
  id: (json['id'] as num?)?.toInt(),
  duration: (json['duration'] as num?)?.toInt(),
  startTime: json['start_time'] as String?,
  placeId: (json['place_id'] as num?)?.toInt(),
  cancelled: json['cancelled'] as bool?,
  toBeScheduled: json['to_be_scheduled'] as bool?,
);

Map<String, dynamic> _$GroupedScheduleOptionToJson(
  GroupedScheduleOption instance,
) => <String, dynamic>{
  'id': instance.id,
  'duration': instance.duration,
  'start_time': instance.startTime,
  'place_id': instance.placeId,
  'cancelled': instance.cancelled,
  'to_be_scheduled': instance.toBeScheduled,
};
