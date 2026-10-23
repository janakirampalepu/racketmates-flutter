import 'package:json_annotation/json_annotation.dart';
import 'package:racketmates/common/events/models/event_match_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';

part 'event_details.g.dart';

/// `GET events/{id}`. Only the fields the details and manage screens use are
/// modelled; the rest of the (large) event payload is ignored.
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

/// One round of a round robin (`event_rounds`).
@JsonSerializable(fieldRename: FieldRename.snake)
class EventRound {
  const EventRound({this.id, this.order, this.status, this.eventMatches});

  factory EventRound.fromJson(Map<String, dynamic> json) =>
      _$EventRoundFromJson(json);

  final int? id;
  final int? order;

  /// `eros_setup_pending`, `eros_setup_completed`, `eros_in_progress`,
  /// `eros_completed` or `eros_cancelled`.
  final String? status;
  final List<EventMatch>? eventMatches;

  Map<String, dynamic> toJson() => _$EventRoundToJson(this);
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
    this.gameType,
    this.partnershipType,
    this.userPermissions,
    this.eventScheduleOptions,
    this.eventParticipants,
    this.currentUserEventDetails,
    this.attendanceDeadlineUnit,
    this.attendanceDeadlineUnitType,
    this.allowParticipantsManagePlayers,
    this.allowParticipantsToLogResults,
    this.considerForTeamRanking,
    this.playerPool,
    this.rsvpLimit,
    this.playerAcceptanceType,
    this.assignType,
    this.scoringFormat,
    this.decidingSetType,
    this.minimumScoreToWin,
    this.noOfCourts,
    this.originatorType,
    this.originatorId,
    this.settingsLocked,
    this.eventVenueCourts,
    this.eventMatches,
    this.eventRounds,
    this.eventSubType,
    this.playerChatRoom,
    this.captainsChatRoom,
    this.eventTeams,
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
  final String? gameType;
  final String? partnershipType;

  /// Event-level permissions keyed like the backend (`event.manage`, ...).
  final Map<String, AccessInfo>? userPermissions;
  final List<EventScheduleOption>? eventScheduleOptions;
  final List<EventParticipant>? eventParticipants;
  final List<CurrentUserEventDetail>? currentUserEventDetails;

  /// Settings the manage screen edits.
  final int? attendanceDeadlineUnit;
  final String? attendanceDeadlineUnitType;
  final bool? allowParticipantsManagePlayers;
  final bool? allowParticipantsToLogResults;
  final bool? considerForTeamRanking;
  final String? playerPool;
  final int? rsvpLimit;
  final String? playerAcceptanceType;
  final String? assignType;
  final String? scoringFormat;
  final String? decidingSetType;
  final int? minimumScoreToWin;
  final int? noOfCourts;
  final String? originatorType;
  final int? originatorId;

  /// True once the event can no longer be changed (e.g. it has been played).
  final bool? settingsLocked;
  final List<EventVenueCourt>? eventVenueCourts;
  final List<EventMatch>? eventMatches;

  /// Rounds of a round robin, each with its matches.
  final List<EventRound>? eventRounds;

  /// Round robin format (`est_manual`, ...).
  final String? eventSubType;

  /// The players' and the captains' chat rooms, once created.
  final ChatRoomRef? playerChatRoom;
  final ChatRoomRef? captainsChatRoom;

  /// The teams of a team event, each with its players' chat room.
  final List<EventTeamRef>? eventTeams;

  Map<String, dynamic> toJson() => _$EventDetailsToJson(this);

  AccessInfo? permission(String key) => userPermissions?[key];

  bool get isRoundRobin => eventType == 'et_round_robin';

  /// Competitive and casual games are a list of scored matches.
  bool get isGame => eventType == 'et_competitive' || eventType == 'et_casual';

  bool get isTeamEvent => (originatorType ?? '').isNotEmpty;

  /// Events whose single time/venue can be changed here: not the ones made of
  /// matches (games, ball machine), which are rescheduled per match.
  bool get hasSingleSchedule =>
      !isGame &&
      eventType != 'et_practice_ball' &&
      (eventScheduleOptions?.length ?? 0) == 1;

  /// Round-robin events with mixed games or fixed partners ask each player for
  /// partner / match-type preferences when responding (not migrated yet).
  bool get needsPartnerPreferences =>
      isRoundRobin &&
      (gameType == 'egt_both' || partnershipType == 'ept_fixed');

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
    this.timezoneInfoId,
    this.timezoneInfo,
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
  final int? timezoneInfoId;
  final EventTimezone? timezoneInfo;

  Map<String, dynamic> toJson() => _$EventScheduleOptionToJson(this);

  /// The start as the wall clock at the venue (the zone is not applied): the
  /// UTC start plus the venue's offset, which is how the create flow sends it.
  DateTime? get venueStart {
    final utc = start?.toUtc();
    if (utc == null) return null;
    final shifted = utc.add(
      Duration(seconds: timezoneInfo?.utcOffsetTime ?? 0),
    );
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
    );
  }

  DateTime? get start =>
      startTime == null ? null : DateTime.tryParse(startTime!);
  DateTime? get end => endTime == null ? null : DateTime.tryParse(endTime!);
}

/// Time zone of a schedule option; `utc_offset_time` is in seconds.
@JsonSerializable(fieldRename: FieldRename.snake)
class EventTimezone {
  const EventTimezone({this.id, this.utcOffsetTime});

  factory EventTimezone.fromJson(Map<String, dynamic> json) =>
      _$EventTimezoneFromJson(json);

  final int? id;
  final int? utcOffsetTime;

  Map<String, dynamic> toJson() => _$EventTimezoneToJson(this);
}

/// A court booked for the event (`event_venue_courts`).
@JsonSerializable(fieldRename: FieldRename.snake)
class EventVenueCourt {
  const EventVenueCourt({this.id, this.placeCourtId, this.order});

  factory EventVenueCourt.fromJson(Map<String, dynamic> json) =>
      _$EventVenueCourtFromJson(json);

  final int? id;
  final int? placeCourtId;
  final int? order;

  Map<String, dynamic> toJson() => _$EventVenueCourtToJson(this);
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
    this.teamId,
    this.preferredMatchType,
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

  /// The team the participant plays for in a team event.
  final int? teamId;

  /// `mt_singles`, `mt_doubles` or `mt_undecided` (round robins with both).
  final String? preferredMatchType;

  Map<String, dynamic> toJson() => _$EventParticipantToJson(this);

  /// The user id: the participant's own, else the user's.
  int? get person => userId ?? user?.id;

  /// "Alex Kim", falling back to the server label.
  String get name {
    final n = user?.displayName ?? '';
    return n.isNotEmpty ? n : (participantLabel ?? '');
  }
}

/// A group of participants from `GET event_participants` (`group_by`): the
/// pairs of a fixed-partner round robin come as [eventParticipantPairs].
@JsonSerializable(fieldRename: FieldRename.snake)
class EventParticipantGroup {
  const EventParticipantGroup({
    this.key,
    this.label,
    this.eventParticipants,
    this.eventParticipantPairs,
  });

  factory EventParticipantGroup.fromJson(Map<String, dynamic> json) =>
      _$EventParticipantGroupFromJson(json);

  final String? key;
  final String? label;
  final List<EventParticipant>? eventParticipants;
  final List<List<EventParticipant>>? eventParticipantPairs;

  Map<String, dynamic> toJson() => _$EventParticipantGroupToJson(this);
}

/// Groups of an `event_participants` answer: several under
/// `event_participant_groups`, or one group at the top.
List<EventParticipantGroup> parseParticipantGroups(Object? data) {
  if (data is! Map<String, dynamic>) return const [];
  final groups = data['event_participant_groups'];
  if (groups is List) {
    return [
      for (final g in groups)
        if (g is Map<String, dynamic>) EventParticipantGroup.fromJson(g),
    ];
  }
  if (data['event_participants'] is List ||
      data['event_participant_pairs'] is List) {
    return [EventParticipantGroup.fromJson(data)];
  }
  return const [];
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
    this.primaryAction,
    this.secondaryAction,
    this.groupedEventScheduleOptions,
    this.selectedScheduleOptionIds,
    this.showRsvpStatus,
    this.teamId,
  });

  factory CurrentUserEventDetail.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserEventDetailFromJson(json);

  final int? eventParticipantId;
  final int? teamId;
  final bool? isPlayer;
  final bool? isCoach;
  final bool? isManager;
  final String? status;
  final String? statusTitle;
  final String? statusSubText;
  final AppUser? user;
  final EventAction? primaryAction;
  final EventAction? secondaryAction;

  /// The time/court options this user can respond to.
  final List<GroupedScheduleOption>? groupedEventScheduleOptions;
  final List<int>? selectedScheduleOptionIds;
  final bool? showRsvpStatus;

  Map<String, dynamic> toJson() => _$CurrentUserEventDetailToJson(this);

  /// Options still open for a response (native `confirmBtnAction`).
  List<GroupedScheduleOption> get assignedOptions => [
    for (final o
        in groupedEventScheduleOptions ?? const <GroupedScheduleOption>[])
      if (!(o.toBeScheduled ?? false) || !(o.cancelled ?? false)) o,
  ];
}

/// `access` of a permission or action: `up_enabled`, `up_disabled`,
/// `up_not_available` or `up_requires_subscription`.
@JsonSerializable(fieldRename: FieldRename.snake)
class AccessInfo {
  const AccessInfo({this.access, this.message});

  factory AccessInfo.fromJson(Map<String, dynamic> json) =>
      _$AccessInfoFromJson(json);

  final String? access;
  final String? message;

  Map<String, dynamic> toJson() => _$AccessInfoToJson(this);

  bool get enabled => access == 'up_enabled';
  bool get requiresSubscription => access == 'up_requires_subscription';
}

/// Backend-provided action for the signed-in user (`primary_action` /
/// `secondary_action`), e.g. `event_view_action_accept`.
@JsonSerializable(fieldRename: FieldRename.snake)
class EventAction {
  const EventAction({this.action, this.access, this.message});

  factory EventAction.fromJson(Map<String, dynamic> json) =>
      _$EventActionFromJson(json);

  final String? action;
  final String? access;
  final String? message;

  Map<String, dynamic> toJson() => _$EventActionToJson(this);

  bool get enabled => access == 'up_enabled';
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GroupedScheduleOption {
  const GroupedScheduleOption({
    this.id,
    this.duration,
    this.startTime,
    this.placeId,
    this.cancelled,
    this.toBeScheduled,
  });

  factory GroupedScheduleOption.fromJson(Map<String, dynamic> json) =>
      _$GroupedScheduleOptionFromJson(json);

  final int? id;
  final int? duration;
  final String? startTime;
  final int? placeId;
  final bool? cancelled;
  final bool? toBeScheduled;

  Map<String, dynamic> toJson() => _$GroupedScheduleOptionToJson(this);
}

/// A chat room the backend created (`{id, channel_url}`).
@JsonSerializable(fieldRename: FieldRename.snake)
class ChatRoomRef {
  const ChatRoomRef({this.id, this.channelUrl});

  factory ChatRoomRef.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomRefFromJson(json);

  final int? id;
  final String? channelUrl;

  Map<String, dynamic> toJson() => _$ChatRoomRefToJson(this);
}

/// One team of a team event.
@JsonSerializable(fieldRename: FieldRename.snake)
class EventTeamRef {
  const EventTeamRef({this.team, this.playersChatRoom});

  factory EventTeamRef.fromJson(Map<String, dynamic> json) =>
      _$EventTeamRefFromJson(json);

  final EventTeamIdRef? team;
  final ChatRoomRef? playersChatRoom;

  Map<String, dynamic> toJson() => _$EventTeamRefToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EventTeamIdRef {
  const EventTeamIdRef({this.id});

  factory EventTeamIdRef.fromJson(Map<String, dynamic> json) =>
      _$EventTeamIdRefFromJson(json);

  final int? id;

  Map<String, dynamic> toJson() => _$EventTeamIdRefToJson(this);
}
