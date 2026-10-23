import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/create_event/scoring.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';

class DraftNotResumable implements Exception {
  const DraftNotResumable([this.reason]);

  final String? reason;

  @override
  String toString() => 'DraftNotResumable($reason)';
}

/// One match as saved: who plays where, on which court.
class SavedMatch {
  const SavedMatch({
    required this.matchType,
    this.courtId,
    this.players = const [],
  });

  final String matchType;
  final int? courtId;
  final List<({int userId, String side, String position})> players;
}

/// A saved draft request read back, with the ids still to be turned into
/// people, a venue and teams.
class DraftSnapshot {
  const DraftSnapshot({
    required this.eventType,
    this.sport,
    this.forTeam = false,
    this.teamId,
    this.opponent,
    this.opponentTeamId,
    this.opponentName = '',
    this.opponentIsHome = false,
    this.homeTeamNotDecided = false,
    this.considerForTeamRanking = true,
    this.attendanceUnit = 1,
    this.attendanceUnitType = attendanceUnitHours,
    this.allowParticipantsManagePlayers = false,
    this.playersLimit,
    this.rsvpLimit,
    this.acceptanceType,
    this.notes = '',
    this.courtCount = 1,
    this.coachIds = const [],
    this.inviteeIds = const [],
    this.knownUsers = const {},
    this.placeId,
    this.start,
    this.durationMinutes = 60,
    this.timezoneInfoId,
    this.courtIds = const [],
    this.matches = const [],
    this.scoring,
    this.allowParticipantsToLogResults = false,
    this.assignNow = false,
    this.gameType,
    this.partnershipType,
    this.eventSubType,
    this.screen,
  });

  final String eventType;
  final SportKey? sport;
  final bool forTeam;
  final int? teamId;
  final OpponentKind? opponent;
  final int? opponentTeamId;
  final String opponentName;
  final bool opponentIsHome;
  final bool homeTeamNotDecided;
  final bool considerForTeamRanking;
  final int attendanceUnit;
  final String attendanceUnitType;
  final bool allowParticipantsManagePlayers;
  final int? playersLimit;
  final int? rsvpLimit;
  final String? acceptanceType;
  final String notes;
  final int courtCount;
  final List<int> coachIds;
  final List<int> inviteeIds;

  /// People the response described in full (the rest are looked up by id).
  final Map<int, AppUser> knownUsers;
  final int? placeId;
  final DateTime? start;
  final int durationMinutes;
  final int? timezoneInfoId;
  final List<int> courtIds;
  final List<SavedMatch> matches;
  final ScoringChoice? scoring;
  final bool allowParticipantsToLogResults;
  final bool assignNow;
  final String? gameType;
  final String? partnershipType;
  final String? eventSubType;

  /// `event_screen`: where the user left off.
  final String? screen;

  /// Every user the draft mentions.
  Set<int> get userIds => {
    ...coachIds,
    ...inviteeIds,
    for (final m in matches)
      for (final p in m.players) p.userId,
  };
}

T? _of<T>(Object? v) => v is T ? v : null;

List<Map<String, dynamic>> _maps(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
];

DateTime? _parseStart(String? text) {
  if (text == null) return null;
  // `yyyy-MM-dd'T'HH:mm'Z'` is wall-clock time with a literal Z: no zone.
  return DateTime.tryParse(text.replaceAll('Z', ''));
}

/// Reads a saved draft: `{event: {...}}` as `GET events/{id}` returns it, with
/// the keys of the create request (attribute lists named `..._attributes`).
DraftSnapshot parseDraftRequest(Map<String, dynamic> body) {
  final inner = body['event'];
  final e = inner is Map ? Map<String, dynamic>.from(inner) : body;
  final type = _of<String>(e['event_type']);
  if (type == null || !eventTypeSpecs.containsKey(type)) {
    throw DraftNotResumable('event type $type');
  }
  final teamIds = _maps(e['event_teams_attributes']);
  final own = teamIds.where((t) => t['logged_in_user_belongs_to_team'] == true);
  final other = teamIds.where(
    (t) => t['logged_in_user_belongs_to_team'] != true,
  );
  final opponentKey = _of<String>(e['opponent_team_type']);
  final opponent = OpponentKind.values
      .where((k) => k.key == opponentKey)
      .firstOrNull;
  final teamPresent = (_of<String>(e['originator_type']) ?? '').isNotEmpty;

  // Participants may be listed under either name.
  final participants = _maps(
    e['event_participants_attributes'] ?? e['event_participants'],
  );
  final known = <int, AppUser>{};
  final coaches = <int>[];
  final invitees = <int>[];
  for (final p in participants) {
    final id =
        _of<num>(p['user_id'])?.toInt() ?? _of<num>(p['user']?['id'])?.toInt();
    if (id == null) continue;
    if (p['user'] is Map) {
      known[id] = AppUser.fromJson(Map<String, dynamic>.from(p['user'] as Map));
    }
    ((p['is_coach'] == true) ? coaches : invitees).add(id);
  }

  final options = _maps(
    e['event_schedule_options_attributes'] ?? e['event_schedule_options'],
  );
  final option = options.firstOrNull;
  final courts = _maps(
    e['event_venue_courts_attributes'] ?? e['event_venue_courts'],
  );
  final matches = <SavedMatch>[
    for (final m in _maps(e['event_matches_attributes'] ?? e['event_matches']))
      SavedMatch(
        matchType: _of<String>(m['match_type']) ?? MatchKeys.undecided,
        courtId: _of<num>(m['place_court_id'])?.toInt(),
        players: [
          for (final side in _maps(m['event_match_sides_attributes']))
            for (final p in _maps(side['event_participants']))
              if (_of<num>(p['user_id']) != null)
                (
                  userId: (p['user_id'] as num).toInt(),
                  side: _of<String>(side['side']) ?? MatchKeys.sideTop,
                  position:
                      _of<String>(p['position']) ?? MatchKeys.positionCenter,
                ),
        ],
      ),
  ];
  final scoringFormat = _of<String>(e['scoring_format']);
  return DraftSnapshot(
    eventType: type,
    sport: SportKey.fromKey(_of<String>(e['sport_type'])),
    forTeam: teamPresent,
    teamId: _of<num>(e['originator_id'])?.toInt(),
    opponent: opponent,
    opponentTeamId: _of<num>(other.firstOrNull?['team_id'])?.toInt(),
    opponentName: _of<String>(e['opponent_team_name']) ?? '',
    opponentIsHome:
        other.firstOrNull?['event_team_type'] == 'ett_home' &&
        own.firstOrNull?['event_team_type'] != 'ett_home',
    homeTeamNotDecided: e['home_team_not_decided'] == true,
    considerForTeamRanking: e['consider_for_team_ranking'] != false,
    attendanceUnit: _of<num>(e['attendance_deadline_unit'])?.toInt() ?? 1,
    attendanceUnitType:
        _of<String>(e['attendance_deadline_unit_type']) ?? attendanceUnitHours,
    allowParticipantsManagePlayers:
        e['allow_participants_manage_players'] == true,
    playersLimit: _of<num>(e['players_limit'])?.toInt(),
    rsvpLimit: _of<num>(e['rsvp_limit'])?.toInt(),
    acceptanceType: _of<String>(e['player_acceptance_type']),
    notes: _of<String>(e['notes_for_event']) ?? '',
    courtCount: _of<num>(e['no_of_courts'])?.toInt() ?? 1,
    coachIds: coaches,
    inviteeIds: invitees,
    knownUsers: known,
    placeId:
        _of<num>(option?['place_id'])?.toInt() ??
        _of<num>(option?['place']?['id'])?.toInt(),
    start: _parseStart(_of<String>(option?['start_time'])),
    durationMinutes: _of<num>(option?['duration'])?.toInt() ?? 60,
    timezoneInfoId: _of<num>(option?['timezone_info_id'])?.toInt(),
    courtIds: [for (final c in courts) ?_of<num>(c['place_court_id'])?.toInt()],
    matches: matches,
    scoring: scoringFormat == null
        ? null
        : ScoringChoice(
            format: scoringFormat,
            minimumScore: _of<num>(e['minimum_score_to_win'])?.toInt() ?? 0,
            decidingSetType:
                _of<String>(e['deciding_set_type']) ?? ScoringKeys.decideLater,
          ),
    allowParticipantsToLogResults:
        e['allow_participants_to_log_results'] == true,
    assignNow: e['assign_type'] == MatchKeys.assignNow,
    gameType: _of<String>(e['game_type']),
    partnershipType: _of<String>(e['partnership_type']),
    eventSubType: _of<String>(e['event_sub_type']),
    screen: _of<String>(e['event_screen']),
  );
}

/// A draft made ready for the wizard, and the step to continue at.
class ResumedDraft {
  const ResumedDraft({required this.draft, required this.step});

  final EventDraft draft;
  final CreateEventStep step;
}

/// Turns [snapshot] into the wizard's draft with the people, venue and teams
/// looked up through the given functions, and picks the step to resume at:
/// the one the user left, when the type still has it, else the review.
Future<ResumedDraft> resumeDraft(
  DraftSnapshot snapshot, {
  required int draftEventId,
  required Future<List<AppUser>> Function(List<int> ids) users,
  required Future<PlaceItem> Function(int id) place,
  required Future<Team> Function(int id) team,
}) async {
  final missing = [
    for (final id in snapshot.userIds)
      if (!snapshot.knownUsers.containsKey(id)) id,
  ];
  final people = {
    ...snapshot.knownUsers,
    for (final u in await users(missing))
      if (u.id != null) u.id!: u,
  };
  AppUser? user(int id) => people[id];

  final venue = snapshot.placeId == null
      ? null
      : await place(snapshot.placeId!);
  final ownTeam = snapshot.forTeam && snapshot.teamId != null
      ? await team(snapshot.teamId!)
      : null;
  final opponentTeam = snapshot.opponentTeamId == null
      ? null
      : await team(snapshot.opponentTeamId!);

  final spec = eventTypeSpecs[snapshot.eventType]!;
  final matches = [
    for (final m in snapshot.matches)
      MatchDraft(
        matchType: m.matchType,
        players: {
          for (final p in m.players)
            if (user(p.userId) != null)
              MatchSlot(p.side, p.position): user(p.userId)!,
        },
      ),
  ];
  final draft = EventDraft(
    eventType: snapshot.eventType,
    sport: snapshot.sport,
    attendanceUnit: snapshot.attendanceUnit,
    attendanceUnitType: snapshot.attendanceUnitType,
    allowParticipantsManagePlayers: snapshot.allowParticipantsManagePlayers,
    coaches: [for (final id in snapshot.coachIds) ?user(id)],
    invitees: [for (final id in snapshot.inviteeIds) ?user(id)],
    place: venue,
    courtCount: snapshot.courtCount,
    courtIds: snapshot.courtIds.isNotEmpty
        ? snapshot.courtIds
        : [for (final m in snapshot.matches) ?m.courtId],
    start: snapshot.start,
    durationMinutes: snapshot.durationMinutes,
    timezoneInfoId: snapshot.timezoneInfoId,
    notes: snapshot.notes,
    playersLimit: snapshot.playersLimit ?? 1,
    rsvpLimit: snapshot.rsvpLimit ?? 1,
    acceptanceType: snapshot.acceptanceType ?? acceptOrderOfResponse,
    matches: matches.isEmpty && spec.hasMatches
        ? const [MatchDraft()]
        : matches,
    assignNow: snapshot.assignNow,
    scoring: snapshot.scoring,
    allowParticipantsToLogResults: snapshot.allowParticipantsToLogResults,
    gameType: snapshot.gameType ?? MatchKeys.gameDoubles,
    partnershipType: snapshot.partnershipType,
    eventSubType: snapshot.eventSubType,
    forTeam: spec.noTeam ? null : snapshot.forTeam,
    team: ownTeam,
    considerForTeamRanking: snapshot.considerForTeamRanking,
    opponent: snapshot.opponent,
    opponentTeam: opponentTeam,
    opponentName: snapshot.opponentName,
    opponentIsHome: snapshot.opponentIsHome,
    homeTeamNotDecided: snapshot.homeTeamNotDecided,
    draftEventId: draftEventId,
  );
  final steps = createEventStepsFor(
    draft.eventType,
    assignNow: draft.assignNow,
    forTeam: draft.forTeam ?? false,
    opponent: draft.opponent,
  );
  final saved = stepForScreen(snapshot.screen);
  final step = saved != null && steps.contains(saved)
      ? saved
      : (steps.contains(CreateEventStep.review)
            ? CreateEventStep.review
            : steps.last);
  return ResumedDraft(draft: draft, step: step);
}
