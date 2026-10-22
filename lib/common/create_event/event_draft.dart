import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';

/// Event types the wizard can create in this build. The native wizard has more
/// (competitive/casual games, round robin, lessons, ball machine, meetups) that
/// need teams, matches, coaches or scoring formats: later milestones.
const supportedEventTypes = {'et_practice_drill'};

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
    this.invitees = const [],
    this.place,
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
  final List<AppUser> invitees;
  final PlaceItem? place;
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
    List<AppUser>? invitees,
    PlaceItem? Function()? place,
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
    invitees: invitees ?? this.invitees,
    place: place != null ? place() : this.place,
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

  int get maxAttendanceUnit => attendanceUnitType == attendanceUnitDays
      ? maxAttendanceDays
      : maxAttendanceHours;
}
