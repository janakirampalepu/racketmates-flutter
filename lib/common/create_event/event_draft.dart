import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';

/// How an event type is built in the wizard (native `eventTypeHasMatches`,
/// `isGroupOrPracticeEvent`, `withCoach` / audience rules).
class EventTypeSpec {
  const EventTypeSpec({
    required this.key,
    this.needsSport = true,
    this.needsCoaches = false,
    this.usesCourts = true,
    this.participantsAreAudience = false,
  });

  final String key;

  /// Meetups have no sport step.
  final bool needsSport;

  /// Lessons are run with coaches (`with_coach: true`, coach step required).
  final bool needsCoaches;

  /// Practice and lessons book a number of courts; meetups only a venue.
  final bool usesCourts;

  /// Meetup attendees are `is_audience` participants, not players.
  final bool participantsAreAudience;
}

/// Event types the wizard can create in this build: events without matches,
/// teams or scoring. Competitive/casual games, round robin, individual lessons,
/// ball machine and team events are later work.
const eventTypeSpecs = {
  'et_practice_drill': EventTypeSpec(key: 'et_practice_drill'),
  'et_group_lesson': EventTypeSpec(key: 'et_group_lesson', needsCoaches: true),
  'et_casual_meeting': EventTypeSpec(
    key: 'et_casual_meeting',
    needsSport: false,
    usesCourts: false,
    participantsAreAudience: true,
  ),
};

final supportedEventTypes = eventTypeSpecs.keys.toSet();

/// Wizard screens, in order. [CreateEventStep.sport] and
/// [CreateEventStep.coaches] are skipped for types that do not need them.
enum CreateEventStep {
  type,
  sport,
  settings,
  coaches,
  players,
  whenWhere,
  inviteSettings,
  review,
}

List<CreateEventStep> createEventStepsFor(String? eventType) {
  final spec = eventTypeSpecs[eventType];
  return [
    CreateEventStep.type,
    if (spec?.needsSport ?? true) CreateEventStep.sport,
    CreateEventStep.settings,
    if (spec?.needsCoaches ?? false) CreateEventStep.coaches,
    CreateEventStep.players,
    CreateEventStep.whenWhere,
    CreateEventStep.inviteSettings,
    CreateEventStep.review,
  ];
}

/// The step after [current] for this event type (null after the last).
CreateEventStep? nextCreateEventStep(
  String? eventType,
  CreateEventStep current,
) {
  final steps = createEventStepsFor(eventType);
  final i = steps.indexOf(current);
  return (i < 0 || i + 1 >= steps.length) ? null : steps[i + 1];
}

const attendanceUnitHours = 'adut_hour';
const attendanceUnitDays = 'adut_day';

const playerPoolInvitedOnly = 'pp_invited_only';
const acceptOrderOfResponse = 'pat_order_of_response';
const acceptPickManually = 'pat_pick_manually';

/// Native pickers: 1-23 hours or 1-7 days.
const maxAttendanceHours = 23;
const maxAttendanceDays = 7;

/// Durations offered for a session, in minutes.
const eventDurationOptions = [30, 45, 60, 75, 90, 105, 120, 150, 180, 240];

/// Everything collected by the create-event wizard (practice drills).
class EventDraft {
  const EventDraft({
    this.eventType,
    this.sport,
    this.attendanceUnit = 1,
    this.attendanceUnitType = attendanceUnitHours,
    this.allowParticipantsManagePlayers = false,
    this.coaches = const [],
    this.invitees = const [],
    this.place,
    this.courtCount = 1,
    this.courtIds = const [],
    this.start,
    this.durationMinutes = 60,
    this.timezoneInfoId,
    this.notes = '',
    this.playersLimit = 1,
    this.rsvpLimit = 1,
    this.acceptanceType = acceptOrderOfResponse,
  });

  final String? eventType;
  final SportKey? sport;

  /// Response deadline before the event: [attendanceUnit] hours or days.
  final int attendanceUnit;
  final String attendanceUnitType;
  final bool allowParticipantsManagePlayers;

  /// Coaches (lessons).
  final List<AppUser> coaches;

  /// Invited players (or attendees for meetups).
  final List<AppUser> invitees;
  final PlaceItem? place;

  /// Number of courts to book (`no_of_courts`); [courtIds] holds at most this
  /// many chosen courts.
  final int courtCount;
  final List<int> courtIds;

  /// Wall-clock start at the venue (no timezone attached).
  final DateTime? start;
  final int durationMinutes;

  /// From `timezone_infos/lookup` for the venue and start time.
  final int? timezoneInfoId;
  final String notes;
  final int playersLimit;
  final int rsvpLimit;
  final String acceptanceType;

  EventDraft copyWith({
    String? eventType,
    SportKey? sport,
    int? attendanceUnit,
    String? attendanceUnitType,
    bool? allowParticipantsManagePlayers,
    List<AppUser>? coaches,
    List<AppUser>? invitees,
    PlaceItem? Function()? place,
    int? courtCount,
    List<int>? courtIds,
    DateTime? Function()? start,
    int? durationMinutes,
    int? Function()? timezoneInfoId,
    String? notes,
    int? playersLimit,
    int? rsvpLimit,
    String? acceptanceType,
  }) => EventDraft(
    eventType: eventType ?? this.eventType,
    sport: sport ?? this.sport,
    attendanceUnit: attendanceUnit ?? this.attendanceUnit,
    attendanceUnitType: attendanceUnitType ?? this.attendanceUnitType,
    allowParticipantsManagePlayers:
        allowParticipantsManagePlayers ?? this.allowParticipantsManagePlayers,
    coaches: coaches ?? this.coaches,
    invitees: invitees ?? this.invitees,
    place: place != null ? place() : this.place,
    courtCount: courtCount ?? this.courtCount,
    courtIds: courtIds ?? this.courtIds,
    start: start != null ? start() : this.start,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    timezoneInfoId: timezoneInfoId != null
        ? timezoneInfoId()
        : this.timezoneInfoId,
    notes: notes ?? this.notes,
    playersLimit: playersLimit ?? this.playersLimit,
    rsvpLimit: rsvpLimit ?? this.rsvpLimit,
    acceptanceType: acceptanceType ?? this.acceptanceType,
  );

  EventTypeSpec? get spec => eventTypeSpecs[eventType];

  int get maxAttendanceUnit => attendanceUnitType == attendanceUnitDays
      ? maxAttendanceDays
      : maxAttendanceHours;
}
