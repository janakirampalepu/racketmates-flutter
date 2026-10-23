import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/create_event/scoring.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/event_match_models.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';

// --- Settings -------------------------------------------------------------

/// What the manage settings screen edits (native `ManageGeneralSettings`).
class EventSettingsEdit {
  const EventSettingsEdit({
    required this.attendanceUnit,
    required this.attendanceUnitType,
    required this.allowManagePlayers,
    required this.allowLogResults,
    required this.considerForTeamRanking,
    required this.playersLimit,
    required this.rsvpLimit,
    required this.acceptanceType,
    this.scoring,
  });

  final int attendanceUnit;
  final String attendanceUnitType;
  final bool allowManagePlayers;
  final bool allowLogResults;
  final bool considerForTeamRanking;
  final int playersLimit;
  final int rsvpLimit;
  final String acceptanceType;
  final ScoringChoice? scoring;

  int get maxAttendanceUnit => attendanceUnitType == attendanceUnitDays
      ? maxAttendanceDays
      : maxAttendanceHours;

  EventSettingsEdit copyWith({
    int? attendanceUnit,
    String? attendanceUnitType,
    bool? allowManagePlayers,
    bool? allowLogResults,
    bool? considerForTeamRanking,
    int? playersLimit,
    int? rsvpLimit,
    String? acceptanceType,
    ScoringChoice? scoring,
  }) => EventSettingsEdit(
    attendanceUnit: attendanceUnit ?? this.attendanceUnit,
    attendanceUnitType: attendanceUnitType ?? this.attendanceUnitType,
    allowManagePlayers: allowManagePlayers ?? this.allowManagePlayers,
    allowLogResults: allowLogResults ?? this.allowLogResults,
    considerForTeamRanking:
        considerForTeamRanking ?? this.considerForTeamRanking,
    playersLimit: playersLimit ?? this.playersLimit,
    rsvpLimit: rsvpLimit ?? this.rsvpLimit,
    acceptanceType: acceptanceType ?? this.acceptanceType,
    scoring: scoring ?? this.scoring,
  );

  /// Changing the unit type resets the value to 1 (native number picker).
  EventSettingsEdit withAttendanceType(String type) =>
      copyWith(attendanceUnitType: type, attendanceUnit: 1);

  EventSettingsEdit withAttendanceUnit(int unit) =>
      copyWith(attendanceUnit: unit.clamp(1, maxAttendanceUnit));

  /// Players limit >= 1; the RSVP limit never drops below it.
  EventSettingsEdit withPlayersLimit(int limit) {
    final players = limit < 1 ? 1 : limit;
    return copyWith(
      playersLimit: players,
      rsvpLimit: rsvpLimit < players ? players : rsvpLimit,
    );
  }

  EventSettingsEdit withRsvpLimit(int limit) =>
      copyWith(rsvpLimit: limit < playersLimit ? playersLimit : limit);
}

/// The current settings of [event], ready to edit.
EventSettingsEdit settingsEditFor(EventDetails event) {
  final format = event.scoringFormat;
  return EventSettingsEdit(
    attendanceUnit: event.attendanceDeadlineUnit ?? 1,
    attendanceUnitType: event.attendanceDeadlineUnitType ?? attendanceUnitHours,
    allowManagePlayers: event.allowParticipantsManagePlayers ?? false,
    allowLogResults: event.allowParticipantsToLogResults ?? false,
    considerForTeamRanking: event.considerForTeamRanking ?? true,
    playersLimit: event.playersLimit ?? 1,
    rsvpLimit: event.rsvpLimit ?? event.playersLimit ?? 1,
    acceptanceType: event.playerAcceptanceType ?? acceptOrderOfResponse,
    scoring: format == null
        ? null
        : ScoringChoice(
            format: format,
            minimumScore: event.minimumScoreToWin ?? 0,
            decidingSetType: event.decidingSetType ?? ScoringKeys.decideLater,
          ),
  );
}

/// Games and round robins are scored (native `isNonPracticeMatch`).
bool eventIsScored(EventDetails event) => event.isGame || event.isRoundRobin;

/// Body of `PUT update_settings` (native `UpdateGeneralSettings`): the
/// deadline and players-manage switch for every event, results and scoring
/// for scored ones, the ranking switch for team round robins.
Map<String, dynamic> buildUpdateSettingsBody(
  EventDetails event,
  EventSettingsEdit edit,
) {
  final scoring = edit.scoring;
  return {
    'event': {
      'attendance_deadline_unit': edit.attendanceUnit,
      'attendance_deadline_unit_type': edit.attendanceUnitType,
      'allow_participants_manage_players': edit.allowManagePlayers,
      'players_limit': edit.playersLimit,
      'rsvp_limit': edit.rsvpLimit,
      'player_acceptance_type': edit.acceptanceType,
      if (eventIsScored(event)) ...{
        'allow_participants_to_log_results': edit.allowLogResults,
        if (scoring != null) ...{
          'scoring_format': scoring.format,
          'deciding_set_type': scoring.decidingSetType,
          'minimum_score_to_win': scoring.minimumScore,
        },
      },
      if (event.isRoundRobin && event.isTeamEvent)
        'consider_for_team_ranking': edit.considerForTeamRanking,
    },
  };
}

// --- Reschedule -------------------------------------------------------------

/// A create-wizard draft holding the event's current venue, time, courts and
/// notes, so the venue screen can be reused to change them.
EventDraft rescheduleDraftFor(EventDetails event) {
  final option = event.eventScheduleOptions!.first;
  final place = option.place;
  final courts = [...?event.eventVenueCourts]
    ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
  final courtIds = [
    for (final c in courts)
      if (c.placeCourtId != null) c.placeCourtId!,
  ];
  return EventDraft(
    eventType: event.eventType,
    sport: SportKey.fromKey(event.sportType),
    place: PlaceItem(
      id: option.placeId ?? place?.id,
      name: place?.name,
      address: place?.address,
    ),
    courtCount: (event.noOfCourts ?? courtIds.length).clamp(1, 99),
    courtIds: courtIds,
    start: option.venueStart,
    durationMinutes: option.duration ?? 60,
    timezoneInfoId: option.timezoneInfoId ?? option.timezoneInfo?.id,
    notes: event.notesForEvent ?? '',
  );
}

/// Body of `PUT reschedule_event` for one time option (native
/// `rescheduleEvent`): the option, the courts and the notes.
Map<String, dynamic> buildRescheduleBody(EventDraft draft) {
  final start = draft.start;
  final placeId = draft.place?.id;
  if (start == null || placeId == null) {
    throw StateError('incomplete reschedule draft');
  }
  final courts = draft.courtIds.take(draft.courtCap).toList();
  return {
    'event': {
      'event_schedule_options_attributes': [
        {
          'place_id': placeId,
          'start_time': formatStartTime(start),
          'duration': draft.durationMinutes,
          if (draft.timezoneInfoId != null)
            'timezone_info_id': draft.timezoneInfoId,
        },
      ],
      'event_venue_courts_attributes': [
        for (var i = 0; i < courts.length; i++)
          {'place_court_id': courts[i], 'order': i + 1},
      ],
      'notes_for_event': draft.notes.trim(),
    },
  };
}

/// Games are made of matches that are moved one at a time.
bool canRescheduleMatches(EventDetails event) =>
    event.isGame && (event.eventMatches?.isNotEmpty ?? false);

/// A create-wizard draft holding the venue, time, court and notes of one
/// match of [event], so the venue screen can be reused to change them. A
/// match without its own time option starts from the event's.
EventDraft rescheduleDraftForMatch(EventDetails event, EventMatch match) {
  final option =
      match.eventMatchScheduleOptions?.firstOrNull?.eventScheduleOption ??
      event.eventScheduleOptions?.firstOrNull;
  final place = option?.place;
  final court = match.placeCourt?.id;
  return EventDraft(
    eventType: event.eventType,
    sport: SportKey.fromKey(event.sportType),
    place: PlaceItem(
      id: option?.placeId ?? place?.id,
      name: place?.name,
      address: place?.address,
    ),
    matches: [MatchDraft(matchType: match.matchType ?? MatchKeys.singles)],
    courtIds: [?court],
    start: option?.venueStart,
    durationMinutes: option?.duration ?? 60,
    timezoneInfoId: option?.timezoneInfoId ?? option?.timezoneInfo?.id,
    notes: match.notesForMatch ?? '',
  );
}

/// Body of `PUT reschedule_matches` for one match (native `rescheduleMatches`):
/// the new time option, the court and the notes. The venue's zone is not sent
/// (native leaves `timezone_info_id` out for matches).
Map<String, dynamic> buildRescheduleMatchBody(int matchId, EventDraft draft) {
  final start = draft.start;
  final placeId = draft.place?.id;
  if (start == null || placeId == null) {
    throw StateError('incomplete reschedule draft');
  }
  return {
    'event': {
      'event_matches_attributes': [
        {
          'id': matchId,
          'request_schedule_options': [
            {
              'place_id': placeId,
              'start_time': formatStartTime(start),
              'duration': draft.durationMinutes,
            },
          ],
          'place_court_id': ?draft.courtIds.firstOrNull,
          'notes_for_match': draft.notes.trim(),
        },
      ],
    },
  };
}

// --- Scores -----------------------------------------------------------------

/// Sets a scoring format is played in (native `getHeighestSetNumber` without
/// the tie-break variants): single games and points formats are one "set".
int scoreSetCount(String? format) => switch (format) {
  ScoringKeys.bestOf3Sets ||
  ScoringKeys.bestOf3Games ||
  ScoringKeys.fast4Tennis => 3,
  ScoringKeys.bestOf5Sets => 5,
  _ => 1,
};

/// The score typed for one set: the top side and the bottom side.
typedef SetScore = ({String top, String bottom});

/// Set tie-break scores typed by set number (1-based).
typedef TieBreaks = Map<int, SetScore>;

enum ScoreError { noScores, incompleteSet, notANumber, tieBreakDrawn }

final _digits = RegExp(r'^\d{1,3}$');

/// Tie-break sets are played in tennis and padel only (native
/// `canAllowTieBreakSets`).
bool allowsTieBreak(String? sportType) =>
    sportType == 'st_tennis' || sportType == 'st_padel';

/// A set is either empty or has a whole-number score for both sides; at least
/// one set must be filled. (The server applies the sport's own rules.)
List<ScoreError> validateSetScores(List<SetScore> sets) {
  final errors = <ScoreError>{};
  var filled = 0;
  for (final s in sets) {
    final top = s.top.trim();
    final bottom = s.bottom.trim();
    if (top.isEmpty && bottom.isEmpty) continue;
    if (top.isEmpty || bottom.isEmpty) {
      errors.add(ScoreError.incompleteSet);
      continue;
    }
    if (!_digits.hasMatch(top) || !_digits.hasMatch(bottom)) {
      errors.add(ScoreError.notANumber);
      continue;
    }
    filled++;
  }
  if (filled == 0 && errors.isEmpty) errors.add(ScoreError.noScores);
  return errors.toList();
}

({int? top, int? bottom}) _numbers(SetScore s) =>
    (top: int.tryParse(s.top.trim()), bottom: int.tryParse(s.bottom.trim()));

/// Whether a set tie-break is played: both sides reached the minimum score
/// (native: at least [minimum] each, equal) in a sport that has them.
bool needsSetTieBreak(
  SetScore set, {
  required bool allow,
  required int minimum,
}) {
  if (!allow) return false;
  final n = _numbers(set);
  if (n.top == null || n.bottom == null) return false;
  return n.top == n.bottom && n.top! >= (minimum < 1 ? 1 : minimum);
}

/// +1 when the top side won the set, -1 for the bottom side, 0 when it is
/// open or drawn. A tied set is decided by its tie-break when there is one.
int setWinner(SetScore set, [SetScore? tieBreak]) {
  final n = _numbers(set);
  if (n.top == null || n.bottom == null) return 0;
  if (n.top! != n.bottom!) return n.top! > n.bottom! ? 1 : -1;
  if (tieBreak == null) return 0;
  final t = _numbers(tieBreak);
  if (t.top == null || t.bottom == null || t.top == t.bottom) return 0;
  return t.top! > t.bottom! ? 1 : -1;
}

/// Sets won by each side (a drawn set counts for neither). Tie-breaks decide
/// tied sets; a match tie-break counts as one set.
({int top, int bottom}) setsWon(
  List<SetScore> sets, {
  TieBreaks tieBreaks = const {},
  SetScore? matchTieBreak,
}) {
  var top = 0;
  var bottom = 0;
  for (var i = 0; i < sets.length; i++) {
    final w = setWinner(sets[i], tieBreaks[i + 1]);
    if (w > 0) top++;
    if (w < 0) bottom++;
  }
  if (matchTieBreak != null) {
    final w = setWinner(matchTieBreak);
    if (w > 0) top++;
    if (w < 0) bottom++;
  }
  return (top: top, bottom: bottom);
}

/// Which rows the score screen shows.
class ScoreLayout {
  const ScoreLayout({
    required this.setRows,
    required this.matchTieBreakRow,
    required this.askDecidingSet,
  });

  /// Regular set rows shown.
  final int setRows;

  /// A match tie-break row replaces the last set.
  final bool matchTieBreakRow;

  /// The sets are level before the last one and nobody decided yet how the
  /// last one is played: ask (native `MatchTieBreakerPicker`).
  final bool askDecidingSet;
}

/// Rows for [format]: the last set of a best-of-3/5 is a match tie-break when
/// the deciding set type says so (tennis and padel only).
ScoreLayout scoreLayout({
  required String? format,
  required String? sportType,
  required String? decidingSetType,
  required List<SetScore> sets,
  TieBreaks tieBreaks = const {},
}) {
  final base = scoreSetCount(format);
  final allow = allowsTieBreak(sportType) && base >= 3;
  if (!allow) {
    return ScoreLayout(
      setRows: base,
      matchTieBreakRow: false,
      askDecidingSet: false,
    );
  }
  final tieBreakDecides = decidingSetType == ScoringKeys.tieBreak;
  final undecided =
      decidingSetType == null || decidingSetType == ScoringKeys.decideLater;
  final earlier = sets.take(base - 1).toList();
  final won = setsWon(earlier, tieBreaks: tieBreaks);
  final level =
      earlier.length == base - 1 &&
      won.top == won.bottom &&
      won.top == (base - 1) ~/ 2;
  return ScoreLayout(
    setRows: tieBreakDecides ? base - 1 : base,
    matchTieBreakRow: tieBreakDecides,
    askDecidingSet: undecided && level,
  );
}

/// Errors in the tie-break fields of the visible rows. [sets] are the visible
/// regular sets.
List<ScoreError> validateTieBreaks(
  List<SetScore> sets, {
  required TieBreaks tieBreaks,
  required SetScore? matchTieBreak,
  required bool allow,
  required int minimum,
  required bool matchTieBreakNeeded,
}) {
  final errors = <ScoreError>{};
  void check(SetScore s, {required bool required}) {
    final top = s.top.trim();
    final bottom = s.bottom.trim();
    if (top.isEmpty && bottom.isEmpty) {
      if (required) errors.add(ScoreError.incompleteSet);
      return;
    }
    if (top.isEmpty || bottom.isEmpty) {
      errors.add(ScoreError.incompleteSet);
    } else if (!_digits.hasMatch(top) || !_digits.hasMatch(bottom)) {
      errors.add(ScoreError.notANumber);
    } else if (top == bottom) {
      errors.add(ScoreError.tieBreakDrawn);
    }
  }

  for (var i = 0; i < sets.length; i++) {
    final needed = needsSetTieBreak(sets[i], allow: allow, minimum: minimum);
    final entered = tieBreaks[i + 1];
    if (needed || entered != null) {
      check(entered ?? (top: '', bottom: ''), required: needed);
    }
  }
  if (matchTieBreak != null) {
    check(matchTieBreak, required: matchTieBreakNeeded);
  }
  return errors.toList();
}

/// The scores already entered for [match], one entry per set.
List<SetScore> prefillSets(EventMatch match) {
  final count = scoreSetCount(match.scoringFormat);
  return [
    for (var i = 1; i <= count; i++)
      (
        top: match.top?.scoreOfSet('$i') ?? '',
        bottom: match.bottom?.scoreOfSet('$i') ?? '',
      ),
  ];
}

/// Set tie-break scores already on [match].
TieBreaks prefillTieBreaks(EventMatch match) {
  final result = <int, SetScore>{};
  for (var i = 1; i <= 5; i++) {
    final top = match.top?.tieBreakOfSet('$i');
    final bottom = match.bottom?.tieBreakOfSet('$i');
    if (top != null || bottom != null) {
      result[i] = (top: top ?? '', bottom: bottom ?? '');
    }
  }
  return result;
}

/// The match tie-break already on [match], if any.
SetScore? prefillMatchTieBreak(EventMatch match) {
  final top = match.top?.matchTieBreakScore;
  final bottom = match.bottom?.matchTieBreakScore;
  if (top == null && bottom == null) return null;
  return (top: top ?? '', bottom: bottom ?? '');
}

/// The set number the server stores a match tie-break under (native
/// `SET_SIX`).
const matchTieBreakSet = '6';

/// Body of `POST update_scores` (native `updateScores`): the filled sets for
/// both sides, their tie-breaks, `request_unfinished_match`, and the match's
/// deciding set type ([decidingSetType], else the match's own). Tie-break
/// scores the server has that are no longer entered are sent blank with their
/// id so they are cleared.
Map<String, dynamic> buildUpdateScoresBody(
  EventMatch match,
  List<SetScore> sets, {
  required bool unfinished,
  TieBreaks tieBreaks = const {},
  SetScore? matchTieBreak,
  String? decidingSetType,
}) {
  final topId = match.top?.id;
  final bottomId = match.bottom?.id;
  if (topId == null || bottomId == null) {
    throw StateError('match without sides');
  }
  Map<String, dynamic> entry(
    int sideId,
    String set,
    String score, {
    bool setTieBreak = false,
    bool matchTieBreak = false,
  }) => {
    'event_match_side_id': sideId,
    'set': set,
    'score': score,
    'set_tie_breaker': setTieBreak,
    'match_tie_breaker': matchTieBreak,
  };

  bool filled(SetScore s) =>
      s.top.trim().isNotEmpty && s.bottom.trim().isNotEmpty;

  final scores = <Map<String, dynamic>>[
    for (var i = 0; i < sets.length; i++)
      if (filled(sets[i])) ...[
        entry(topId, '${i + 1}', sets[i].top.trim()),
        entry(bottomId, '${i + 1}', sets[i].bottom.trim()),
        if (tieBreaks[i + 1] case final tb? when filled(tb)) ...[
          entry(topId, '${i + 1}', tb.top.trim(), setTieBreak: true),
          entry(bottomId, '${i + 1}', tb.bottom.trim(), setTieBreak: true),
        ],
      ],
    if (matchTieBreak != null && filled(matchTieBreak)) ...[
      entry(
        topId,
        matchTieBreakSet,
        matchTieBreak.top.trim(),
        matchTieBreak: true,
      ),
      entry(
        bottomId,
        matchTieBreakSet,
        matchTieBreak.bottom.trim(),
        matchTieBreak: true,
      ),
    ],
  ];

  bool sent(int? sideId, String? set, bool stb, bool mtb) => scores.any(
    (e) =>
        e['event_match_side_id'] == sideId &&
        e['set'] == set &&
        e['set_tie_breaker'] == stb &&
        e['match_tie_breaker'] == mtb,
  );
  final cleared = [
    for (final side in match.eventMatchSides ?? const <EventMatchSide>[])
      for (final s in side.eventScores ?? const <EventScore>[])
        if (!s.isRegularSet &&
            s.id != null &&
            (s.score ?? '').isNotEmpty &&
            !sent(
              side.id,
              s.set,
              s.setTieBreaker ?? false,
              s.matchTieBreaker ?? false,
            ))
          {
            'id': s.id,
            ...entry(
              side.id!,
              s.set ?? '',
              '',
              setTieBreak: s.setTieBreaker ?? false,
              matchTieBreak: s.matchTieBreaker ?? false,
            ),
          },
  ];

  return {
    'event_match': {
      'deciding_set_type': decidingSetType ?? match.decidingSetType,
      'event_scores_attributes': [...scores, ...cleared],
      'request_unfinished_match': unfinished,
    },
  };
}

/// "6-4, 7-6(5), [10-8]" for the sets with scores: a set tie-break shows the
/// loser's points in brackets, a match tie-break the whole score.
String scoreSummary(EventMatch match) {
  final tieBreaks = prefillTieBreaks(match);
  final parts = <String>[];
  final sets = prefillSets(match);
  for (var i = 0; i < sets.length; i++) {
    final s = sets[i];
    if (s.top.isEmpty || s.bottom.isEmpty) continue;
    final tb = tieBreaks[i + 1];
    final loser = tb == null
        ? null
        : [int.tryParse(tb.top), int.tryParse(tb.bottom)]
              .whereType<int>()
              .fold<int?>(null, (m, v) => m == null || v < m ? v : m);
    parts.add('${s.top}-${s.bottom}${loser == null ? '' : '($loser)'}');
  }
  final mtb = prefillMatchTieBreak(match);
  if (mtb != null && mtb.top.isNotEmpty && mtb.bottom.isNotEmpty) {
    parts.add('[${mtb.top}-${mtb.bottom}]');
  }
  return parts.join(', ');
}

// --- Rounds -------------------------------------------------------------------

/// What the round robin entry of the manage hub does.
enum RoundsEntry {
  /// No entry (not a round robin, or the user may do nothing with rounds).
  none,

  /// The rounds do not exist yet: generate them (native `event.setup_rounds`).
  setUp,

  /// Open the rounds (native `event.manage_rounds`).
  manage,
}

/// Native `performRoundRobinAction`: managing rounds wins over setting them up.
/// (`event.generate_rounds` does nothing in the native app either.)
RoundsEntry roundsEntryFor(EventDetails event) {
  if (!event.isRoundRobin) return RoundsEntry.none;
  if (event.permission('event.manage_rounds')?.enabled ?? false) {
    return RoundsEntry.manage;
  }
  if (event.permission('event.setup_rounds')?.enabled ?? false) {
    return RoundsEntry.setUp;
  }
  return RoundsEntry.none;
}

/// Fixed partners are chosen on their own screen before rounds exist.
bool needsFixedPartners(EventDetails event) =>
    event.partnershipType == 'ept_fixed';

/// `result` of the generate call when too few players confirmed.
const insufficientPlayersResult = 'egr_insufficient_confirmed_players';

/// Only the manual format has rounds the organizer builds by hand.
bool roundsAreManual(EventDetails event) => event.eventSubType == 'est_manual';

/// Add and remove rounds and matches: manual rounds, unless the server says
/// the event cannot be managed (native `isEnableForActions`).
bool canEditRounds(EventDetails event) =>
    roundsAreManual(event) &&
    event.permission('event.manage')?.access != 'up_not_available';

/// Only the last round can be removed, and never the only one.
bool canRemoveRound(List<EventRound> rounds, EventRound round) =>
    rounds.length > 1 && round.id != null && round.id == rounds.last.id;

/// Courts a match of [event] can be moved to: the event's own courts.
List<int> roundCourtIds(EventDetails event) => [
  for (final c in event.eventVenueCourts ?? const <EventVenueCourt>[])
    if (c.placeCourtId != null) c.placeCourtId!,
];

/// Body of `PUT update_matches` moving a match to a court.
Map<String, dynamic> buildMatchCourtBody(int matchId, int courtId) => {
  'event': {
    'event_matches_attributes': [
      {'id': matchId, 'place_court_id': courtId},
    ],
  },
};

// --- Players ------------------------------------------------------------------

enum ParticipantGroup {
  confirmed,
  toBeConfirmed,
  waitlisted,
  invited,
  declined,
  other,
}

/// Which group an `eus_*` status belongs to on the players screen.
ParticipantGroup groupOfStatus(String? status) => switch (status) {
  'eus_confirmed' ||
  'eus_confirmed_with_other_courts' ||
  'eus_accepted' => ParticipantGroup.confirmed,
  'eus_to_be_confirmed' => ParticipantGroup.toBeConfirmed,
  'eus_waitlisted' => ParticipantGroup.waitlisted,
  'eus_invited' => ParticipantGroup.invited,
  'eus_declined' ||
  'eus_declined_with_other_courts' => ParticipantGroup.declined,
  _ => ParticipantGroup.other,
};

/// The role a person is added with (native `updateEventParticipents`).
String addRoleFor(EventDetails event, {required bool coach}) => coach
    ? 'ur_coach'
    : event.eventType == 'et_casual_meeting'
    ? 'ur_audience'
    : 'ur_player';
