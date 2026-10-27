import 'package:json_annotation/json_annotation.dart';
import 'package:racketmates/common/users/models/app_user.dart';

part 'schedule_models.g.dart';

/// `GET schedule/scheduled_events` response (native `CurrentScheduleListResponse`).
@JsonSerializable(fieldRename: FieldRename.snake)
class ScheduleListResponse {
  const ScheduleListResponse({this.scheduleItems, this.meta});

  factory ScheduleListResponse.fromJson(Map<String, dynamic> json) =>
      _$ScheduleListResponseFromJson(json);

  final List<ScheduleItem>? scheduleItems;
  final ScheduleMeta? meta;

  Map<String, dynamic> toJson() => _$ScheduleListResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ScheduleMeta {
  const ScheduleMeta({this.otherEvents});

  factory ScheduleMeta.fromJson(Map<String, dynamic> json) =>
      _$ScheduleMetaFromJson(json);

  final OtherEvents? otherEvents;

  Map<String, dynamic> toJson() => _$ScheduleMetaToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class OtherEvents {
  const OtherEvents({this.draftsLabel, this.toBeRescheduledLabel});

  factory OtherEvents.fromJson(Map<String, dynamic> json) =>
      _$OtherEventsFromJson(json);

  final String? draftsLabel;
  final String? toBeRescheduledLabel;

  Map<String, dynamic> toJson() => _$OtherEventsToJson(this);
}

/// One row of a schedule list. Status and sport values are kept as the
/// backend's strings (`es_*`, `pes_*`, `st_*`); labels are server-provided.
@JsonSerializable(fieldRename: FieldRename.snake)
class ScheduleItem {
  const ScheduleItem({
    this.eventId,
    this.eventDate,
    this.eventStatus,
    this.eventStatusLabel,
    this.eventType,
    this.sportType,
    this.participantStatus,
    this.participantStatusLabel,
    this.pastEventStatus,
    this.pastEventStatusLabel,
    this.placeId,
    this.placeName,
    this.teamId,
    this.notes,
    this.courtsLabel,
    this.timeSlot,
    this.coachLabel,
    this.startTimeText,
    this.endTimeText,
    this.userParticipantCount,
    this.waitlistNumber,
    this.additionalTimings,
    this.additionalVenues,
    this.additionalParticipants,
    this.onMultipleDates,
    this.eventUsers,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) =>
      _$ScheduleItemFromJson(json);

  final int? eventId;

  /// `yyyy-MM-dd`.
  final String? eventDate;
  final String? eventStatus;
  final String? eventStatusLabel;
  final String? eventType;
  final String? sportType;
  final String? participantStatus;
  final String? participantStatusLabel;
  final String? pastEventStatus;
  final String? pastEventStatusLabel;
  final int? placeId;
  final String? placeName;
  final int? teamId;
  final String? notes;
  final String? courtsLabel;
  final String? timeSlot;
  final String? coachLabel;
  final String? startTimeText;
  final String? endTimeText;

  /// `int?` (not `String?` — Android's `CurrentScheduleItem.kt` types it
  /// `String?`, same mistake as `waitlistNumber` below, confirmed live:
  /// `type 'int' is not a subtype of type 'String?' in type cast` was the
  /// actual parse failure left after fixing `waitlistNumber` alone).
  final int? userParticipantCount;

  /// `int?` here (not `String?`, Android's own `CurrentScheduleItem.kt`
  /// typing): iOS's `ScheduleItems.waitlistNumber` for this same endpoint,
  /// and this app's own `EventParticipant.waitlistNumber` for the related
  /// `event_participants` endpoint, both type it `Int?`/`int?` — the
  /// backend sends a JSON number. Android's Gson silently coerces a number
  /// token into a Kotlin `String` when read as one (`JsonReader.nextString`
  /// accepts a NUMBER token), so Android never saw a problem; Dart's
  /// `as String?` cast is strict and throws for a non-string JSON value,
  /// which is why this specific field broke parsing the whole response.
  final int? waitlistNumber;
  final int? additionalTimings;
  final int? additionalVenues;
  final int? additionalParticipants;
  final bool? onMultipleDates;
  final List<AppUser>? eventUsers;

  Map<String, dynamic> toJson() => _$ScheduleItemToJson(this);

  DateTime? get date =>
      eventDate == null ? null : DateTime.tryParse(eventDate!);
}
