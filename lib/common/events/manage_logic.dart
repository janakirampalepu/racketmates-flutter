import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
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

enum ScoreError { noScores, incompleteSet, notANumber }

final _digits = RegExp(r'^\d{1,3}$');

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

/// Sets won by each side (a drawn set counts for neither).
({int top, int bottom}) setsWon(List<SetScore> sets) {
  var top = 0;
  var bottom = 0;
  for (final s in sets) {
    final a = int.tryParse(s.top.trim());
    final b = int.tryParse(s.bottom.trim());
    if (a == null || b == null) continue;
    if (a > b) top++;
    if (b > a) bottom++;
  }
  return (top: top, bottom: bottom);
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

/// Body of `POST update_scores` (native `updateScores`): the filled sets for
/// both sides, `request_unfinished_match`, and the match's deciding set type.
/// Tie-break scores already on the match are sent back unchanged so saving
/// does not drop them (they cannot be edited here).
Map<String, dynamic> buildUpdateScoresBody(
  EventMatch match,
  List<SetScore> sets, {
  required bool unfinished,
}) {
  final topId = match.top?.id;
  final bottomId = match.bottom?.id;
  if (topId == null || bottomId == null) {
    throw StateError('match without sides');
  }
  Map<String, dynamic> entry(int sideId, String set, String score) => {
    'event_match_side_id': sideId,
    'set': set,
    'score': score,
    'set_tie_breaker': false,
    'match_tie_breaker': false,
  };
  final kept = [
    for (final side in match.eventMatchSides ?? const <EventMatchSide>[])
      for (final s in side.eventScores ?? const <EventScore>[])
        if (!s.isRegularSet && (s.score ?? '').isNotEmpty)
          {
            'event_match_side_id': side.id,
            'set': s.set,
            'score': s.score,
            'set_tie_breaker': s.setTieBreaker ?? false,
            'match_tie_breaker': s.matchTieBreaker ?? false,
          },
  ];
  return {
    'event_match': {
      'deciding_set_type': match.decidingSetType,
      'event_scores_attributes': [
        for (var i = 0; i < sets.length; i++)
          if (sets[i].top.trim().isNotEmpty &&
              sets[i].bottom.trim().isNotEmpty) ...[
            entry(topId, '${i + 1}', sets[i].top.trim()),
            entry(bottomId, '${i + 1}', sets[i].bottom.trim()),
          ],
        ...kept,
      ],
      'request_unfinished_match': unfinished,
    },
  };
}

/// "6-4, 3-6, 7-5" for the sets with scores, else an empty string.
String scoreSummary(EventMatch match) => [
  for (final s in prefillSets(match))
    if (s.top.isNotEmpty && s.bottom.isNotEmpty) '${s.top}-${s.bottom}',
].join(', ');

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
