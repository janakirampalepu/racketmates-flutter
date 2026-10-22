import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/create_event/scoring.dart';
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
    this.hasMatches = false,
    this.isRoundRobin = false,
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

  /// Competitive and casual games are a list of matches (native
  /// `eventTypeHasMatches`).
  final bool hasMatches;

  /// Round robins book courts and a format; the rounds are generated later.
  final bool isRoundRobin;

  /// Games and round robins are scored (native `isNonPracticeMatch` /
  /// `isRoundRobinEvent`).
  bool get usesScoring => hasMatches || isRoundRobin;

  /// Practice and lessons choose how many courts to book on the venue step;
  /// games take one court per match and round robins choose on their own step.
  bool get courtCountOnWhenWhere => usesCourts && !hasMatches && !isRoundRobin;
}

/// Event types the wizard can create in this build. Individual lessons, ball
/// machines and team events are later work.
const eventTypeSpecs = {
  'et_practice_drill': EventTypeSpec(key: 'et_practice_drill'),
  'et_group_lesson': EventTypeSpec(key: 'et_group_lesson', needsCoaches: true),
  'et_casual_meeting': EventTypeSpec(
    key: 'et_casual_meeting',
    needsSport: false,
    usesCourts: false,
    participantsAreAudience: true,
  ),
  'et_competitive': EventTypeSpec(key: 'et_competitive', hasMatches: true),
  'et_casual': EventTypeSpec(key: 'et_casual', hasMatches: true),
  'et_round_robin': EventTypeSpec(key: 'et_round_robin', isRoundRobin: true),
};

final supportedEventTypes = eventTypeSpecs.keys.toSet();

/// Wizard screens. The order depends on the event type (see
/// [createEventStepsFor]); [CreateEventStep.sport], [CreateEventStep.coaches]
/// and the match/round-robin screens only exist for the types that need them.
enum CreateEventStep {
  type,
  sport,
  settings,
  coaches,
  players,
  matches,
  roundRobinFormat,
  assignType,
  assignPlayers,
  whenWhere,
  inviteSettings,
  review,
}

/// Screens of an event type in order. [assignNow] is the games choice to put
/// players into matches now (no invite settings or invite list afterwards)
/// rather than inviting players and assigning later.
List<CreateEventStep> createEventStepsFor(
  String? eventType, {
  bool assignNow = false,
}) {
  final spec = eventTypeSpecs[eventType];
  if (spec != null && spec.hasMatches) {
    return [
      CreateEventStep.type,
      CreateEventStep.sport,
      CreateEventStep.settings,
      CreateEventStep.matches,
      CreateEventStep.whenWhere,
      CreateEventStep.assignType,
      if (assignNow)
        CreateEventStep.assignPlayers
      else ...[
        CreateEventStep.inviteSettings,
        CreateEventStep.players,
      ],
      CreateEventStep.review,
    ];
  }
  if (spec != null && spec.isRoundRobin) {
    return [
      CreateEventStep.type,
      CreateEventStep.sport,
      CreateEventStep.settings,
      CreateEventStep.matches,
      CreateEventStep.roundRobinFormat,
      CreateEventStep.whenWhere,
      CreateEventStep.inviteSettings,
      CreateEventStep.players,
      CreateEventStep.review,
    ];
  }
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
  CreateEventStep current, {
  bool assignNow = false,
}) {
  final steps = createEventStepsFor(eventType, assignNow: assignNow);
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
    this.matches = const [],
    this.assignNow = false,
    this.scoring,
    this.allowParticipantsToLogResults = false,
    this.gameType = MatchKeys.gameDoubles,
    this.partnershipType = MatchKeys.partnersRotating,
    this.eventSubType,
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

  /// Matches of a competitive/casual game.
  final List<MatchDraft> matches;

  /// Games: put players into matches now instead of inviting and assigning
  /// later (`assign_type`).
  final bool assignNow;

  /// Scoring of games and round robins.
  final ScoringChoice? scoring;
  final bool allowParticipantsToLogResults;

  /// Round robin: singles, doubles or both, and how doubles partners work.
  final String gameType;
  final String? partnershipType;

  /// Round robin format (`est_classic`, `est_king_of_the_court`,
  /// `est_manual`).
  final String? eventSubType;

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
    List<MatchDraft>? matches,
    bool? assignNow,
    ScoringChoice? scoring,
    bool? allowParticipantsToLogResults,
    String? gameType,
    String? Function()? partnershipType,
    String? Function()? eventSubType,
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
    matches: matches ?? this.matches,
    assignNow: assignNow ?? this.assignNow,
    scoring: scoring ?? this.scoring,
    allowParticipantsToLogResults:
        allowParticipantsToLogResults ?? this.allowParticipantsToLogResults,
    gameType: gameType ?? this.gameType,
    partnershipType: partnershipType != null
        ? partnershipType()
        : this.partnershipType,
    eventSubType: eventSubType != null ? eventSubType() : this.eventSubType,
  );

  EventTypeSpec? get spec => eventTypeSpecs[eventType];

  /// Most courts that can be picked: one per match for games, else the chosen
  /// court count.
  int get courtCap => (spec?.hasMatches ?? false) ? matches.length : courtCount;

  /// Players the courts hold, from native `setRSVPandPlayerLimit` (non-team):
  /// singles 2 and doubles 4 per match or court; null for other event types.
  int? get courtPlayerCapacity {
    final spec = this.spec;
    if (spec == null) return null;
    final total = spec.hasMatches
        ? matches.fold(0, (sum, m) => sum + m.playerCount)
        : spec.isRoundRobin
        ? courtCount * (gameType == MatchKeys.gameSingles ? 2 : 4)
        : null;
    if (total == null) return null;
    return total == 0 ? 1 : total;
  }

  /// Players assigned to matches, once each.
  List<AppUser> get assignedPlayers {
    final byId = <int?, AppUser>{};
    for (final m in matches) {
      for (final u in m.players.values) {
        byId[u.id] = u;
      }
    }
    return byId.values.toList();
  }

  int get maxAttendanceUnit => attendanceUnitType == attendanceUnitDays
      ? maxAttendanceDays
      : maxAttendanceHours;
}
