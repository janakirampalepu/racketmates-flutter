import 'package:json_annotation/json_annotation.dart';
import 'package:racketmates/common/users/models/app_user.dart';

part 'event_details.g.dart';

/// `GET events/{id}`. Only the fields the read-only details screen uses are
/// modelled; the rest of the (large) event payload is ignored until the
/// create/manage milestones need it.
@JsonSerializable(fieldRename: FieldRename.snake)
class EventDetailsResponse {
  const EventDetailsResponse({this.message, this.result, this.event});

  factory EventDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$EventDetailsResponseFromJson(json);

  final String? message;
  final String? result;
  final EventDetails? event;

  Map<String, dynamic> toJson() => _$EventDetailsResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EventDetails {
  const EventDetails({
    this.id,
    this.eventType,
    this.sportType,
    this.status,
    this.notesForEvent,
    this.rsvpStatus,
    this.playersLimit,
    this.regularSpotsLeft,
    this.waitingListSpotsLeft,
    this.eventParticipantsCount,
    this.withCoach,
    this.eventScheduleOptions,
    this.eventParticipants,
    this.currentUserEventDetails,
  });

  factory EventDetails.fromJson(Map<String, dynamic> json) =>
      _$EventDetailsFromJson(json);

  final int? id;
  final String? eventType;
  final String? sportType;
  final String? status;
  final String? notesForEvent;
  final String? rsvpStatus;
  final int? playersLimit;
  final int? regularSpotsLeft;
  final int? waitingListSpotsLeft;
  final int? eventParticipantsCount;
  final bool? withCoach;
  final List<EventScheduleOption>? eventScheduleOptions;
  final List<EventParticipant>? eventParticipants;
  final List<CurrentUserEventDetail>? currentUserEventDetails;

  Map<String, dynamic> toJson() => _$EventDetailsToJson(this);

  /// Participants who are players (coaches, organizers and audience excluded).
  List<EventParticipant> get players => [
    for (final p in eventParticipants ?? const <EventParticipant>[])
      if (p.isPlayer ?? false) p,
  ];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EventScheduleOption {
  const EventScheduleOption({
    this.id,
    this.startTime,
    this.endTime,
    this.duration,
    this.placeId,
    this.place,
    this.optionNumber,
    this.status,
  });

  factory EventScheduleOption.fromJson(Map<String, dynamic> json) =>
      _$EventScheduleOptionFromJson(json);

  final int? id;

  /// ISO-8601 timestamps from the backend.
  final String? startTime;
  final String? endTime;

  /// Minutes.
  final int? duration;
  final int? placeId;
  final EventPlace? place;
  final int? optionNumber;
  final String? status;

  Map<String, dynamic> toJson() => _$EventScheduleOptionToJson(this);

  DateTime? get start =>
      startTime == null ? null : DateTime.tryParse(startTime!);
  DateTime? get end => endTime == null ? null : DateTime.tryParse(endTime!);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EventPlace {
  const EventPlace({this.id, this.name, this.address});

  factory EventPlace.fromJson(Map<String, dynamic> json) =>
      _$EventPlaceFromJson(json);

  final int? id;
  final String? name;
  final String? address;

  Map<String, dynamic> toJson() => _$EventPlaceToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EventParticipant {
  const EventParticipant({
    this.id,
    this.userId,
    this.user,
    this.isOrganizer,
    this.isPlayer,
    this.isCoach,
    this.status,
    this.waitlistNumber,
    this.participantLabel,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) =>
      _$EventParticipantFromJson(json);

  final int? id;
  final int? userId;
  final AppUser? user;
  final bool? isOrganizer;
  final bool? isPlayer;
  final bool? isCoach;

  /// `eus_*` participation status (kept as the backend string).
  final String? status;
  final int? waitlistNumber;
  final String? participantLabel;

  Map<String, dynamic> toJson() => _$EventParticipantToJson(this);
}

/// The signed-in user's own standing in the event (server-provided texts).
@JsonSerializable(fieldRename: FieldRename.snake)
class CurrentUserEventDetail {
  const CurrentUserEventDetail({
    this.eventParticipantId,
    this.isPlayer,
    this.isCoach,
    this.isManager,
    this.status,
    this.statusTitle,
    this.statusSubText,
    this.user,
  });

  factory CurrentUserEventDetail.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserEventDetailFromJson(json);

  final int? eventParticipantId;
  final bool? isPlayer;
  final bool? isCoach;
  final bool? isManager;
  final String? status;
  final String? statusTitle;
  final String? statusSubText;
  final AppUser? user;

  Map<String, dynamic> toJson() => _$CurrentUserEventDetailToJson(this);
}
