import 'package:intl/intl.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';

/// Native `YYYY_MM_DD_T_HH_MM_SS` = `yyyy-MM-dd'T'HH:mm'Z'`: the venue's local
/// wall time with a literal `Z` (the zone travels in `timezone_info_id`).
String formatStartTime(DateTime start) =>
    "${DateFormat('yyyy-MM-dd').format(start)}T${DateFormat('HH:mm').format(start)}Z";

/// Native `AppConstants.TEAM`: the `originator_type` of a team event.
const originatorTypeTeam = 'Team';

const _stepScreens = {
  CreateEventStep.type: 'es_event_type_selection',
  CreateEventStep.sport: 'es_sports_type',
  CreateEventStep.teamChoice: 'es_team_non_team',
  CreateEventStep.teamSelect: 'es_self_team',
  CreateEventStep.teamDynamics: 'es_event_dynamics_selection',
  CreateEventStep.opponentSelect: 'es_team_opponent_selection',
  CreateEventStep.homeAway: 'es_event_team_home_away_selection',
  CreateEventStep.settings: 'es_general_settings',
  CreateEventStep.coaches: 'es_coaches_assign',
  CreateEventStep.matches: 'es_courts_addition',
  CreateEventStep.roundRobinFormat: 'es_round_robin_format_selection',
  CreateEventStep.whenWhere: 'es_court_options',
  CreateEventStep.assignType: 'es_court_player_assign_type',
  CreateEventStep.assignPlayers: 'es_court_player_assignment',
  CreateEventStep.inviteSettings: 'es_invite_player_settings',
  CreateEventStep.players: 'es_invite_players_mgmt',
  CreateEventStep.review: 'es_review',
};

/// `screen_flow_path`: the screens opened for this event, in native
/// `EventCreateScreens` naming. Games and round robins list the screens they
/// went through; the other types keep the path of the first wizard version.
String _flowPath(EventDraft draft, EventTypeSpec spec) {
  if (spec.usesScoring || spec.individualLesson || spec.ballMachine) {
    return [
      for (final step in createEventStepsFor(
        spec.key,
        assignNow: draft.assignNow,
        forTeam: draft.forTeam ?? false,
        opponent: draft.opponent,
        teamLocked: draft.teamLocked,
      ))
        _stepScreens[step]!,
    ].join('##');
  }
  return [
    'es_event_type_selection',
    if (spec.needsSport) 'es_sports_type',
    'es_team_non_team',
    if (draft.forTeam ?? false) 'es_self_team',
    'es_general_settings',
    if (spec.needsCoaches) 'es_coaches_assign',
    'es_invite_players_mgmt',
    if (spec.usesCourts) 'es_courts_addition',
    'es_invite_player_settings',
    'es_review',
  ].join('##');
}

/// Teams of a team event (native `eventTeamsAttributes`): the user's team,
/// plus the opponent in a team game against another team. Home or visiting
/// is left out while the home team is undecided.
List<Map<String, dynamic>> _eventTeams(EventDraft draft, int teamId) {
  String? side({required bool opponentSide}) {
    if (!draft.isMultiTeam) return 'ett_home';
    if (draft.homeTeamNotDecided) return null;
    return opponentSide == draft.opponentIsHome ? 'ett_home' : 'ett_visiting';
  }

  return [
    {
      'team_id': teamId,
      'event_team_type': ?side(opponentSide: false),
      'logged_in_user_belongs_to_team': true,
    },
    if (draft.isMultiTeam)
      {
        'team_id': ?draft.opponentTeam?.id,
        'event_team_type': ?side(opponentSide: true),
        'logged_in_user_belongs_to_team': false,
      },
  ];
}

List<Map<String, dynamic>> _matchBodies(
  EventDraft draft,
  List<MatchDraft> matches,
  List<int> courts,
  int? teamId,
  int? opponentTeamId, {
  required bool withPlayers,
}) => [
  for (var i = 0; i < matches.length; i++)
    {
      'match_type': matches[i].matchType,
      'order': i + 1,
      if (i < courts.length) 'place_court_id': courts[i],
      'event_match_sides_attributes': [
        for (final side in const [MatchKeys.sideTop, MatchKeys.sideBottom])
          {
            // Within the team both sides are the user's team; against another
            // team the bottom side is the opponent (no id when only named).
            'team_id': ?(side == MatchKeys.sideBottom && draft.isMultiTeam
                ? opponentTeamId
                : teamId),
            'side': side,
            'event_participants': [
              if (withPlayers)
                for (final e in matches[i].players.entries)
                  if (e.key.side == side)
                    {'user_id': e.value.id, 'position': e.key.position},
            ],
          },
      ],
    },
];

/// Body of `POST events` (practice drill, group lesson, casual meetup,
/// competitive/casual game, round robin; team events are within the user's own
/// team), built from the fields the native `getCreateEventInfo()` sends. Throws [StateError] when the draft is
/// incomplete (screens validate first).
Map<String, dynamic> buildCreateEventBody(EventDraft draft) {
  final spec = draft.spec;
  final start = draft.start;
  final place = draft.place;
  if (spec == null ||
      (spec.needsSport && draft.sport == null) ||
      start == null ||
      place?.id == null) {
    throw StateError('incomplete event draft');
  }
  if (spec.usesScoring && draft.scoring == null) {
    throw StateError('incomplete event draft');
  }
  final team = draft.forTeam == true ? draft.team : null;
  if (draft.forTeam == true && team?.id == null) {
    throw StateError('incomplete event draft');
  }
  // A team game says who it is played against.
  if (team != null && spec.hasMatches) {
    final opponent = draft.opponent;
    if (opponent == null ||
        (opponent == OpponentKind.selectTeam &&
            draft.opponentTeam?.id == null) ||
        (opponent == OpponentKind.namedTeam &&
            draft.opponentName.trim().isEmpty)) {
      throw StateError('incomplete event draft');
    }
  }
  // A ball machine is one singles match on one court with one player.
  if (spec.ballMachine && draft.invitees.isEmpty) {
    throw StateError('incomplete event draft');
  }
  final courts = draft.courtIds.take(draft.courtCap).toList();
  final scoring = draft.scoring;
  final ballMatches = [
    MatchDraft(
      matchType: MatchKeys.singles,
      players: {
        const MatchSlot(MatchKeys.sideTop, MatchKeys.positionCenter):
            ?draft.invitees.firstOrNull,
      },
    ),
  ];
  // Players put into matches now are not event participants (native keeps
  // only coaches in that case) and the invite settings step is skipped.
  final assignNow = spec.hasMatches && draft.assignNow;
  return {
    'event': {
      'event_type': spec.key,
      if (spec.needsSport) 'sport_type': draft.sport!.key,
      // Non-team ("global") event: native sends an empty originator type;
      // lessons for one player and ball machines never ask, so send none.
      if (!spec.noTeam)
        'originator_type': team == null ? '' : originatorTypeTeam,
      if (team != null) ...{
        'originator_id': team.id,
        'event_teams_attributes': _eventTeams(draft, team.id!),
        'opponent_team_type': spec.hasMatches
            ? draft.opponent!.key
            : OpponentKind.withinTeam.key,
        if (draft.isMultiTeam) ...{
          if (draft.opponent == OpponentKind.namedTeam)
            'opponent_team_name': draft.opponentName.trim(),
          'home_team_not_decided': draft.homeTeamNotDecided,
        },
        if (spec.isRoundRobin)
          'consider_for_team_ranking': draft.considerForTeamRanking,
      },
      'with_coach': spec.needsCoaches,
      'with_audience': false,
      'request_save_as_draft': false,
      // A ball machine skips the settings and invite steps, so those fields
      // are not sent.
      if (!spec.ballMachine) ...{
        'allow_participants_manage_players':
            draft.allowParticipantsManagePlayers,
        'attendance_deadline_unit': draft.attendanceUnit,
        'attendance_deadline_unit_type': draft.attendanceUnitType,
        'player_pool': playerPoolInvitedOnly,
      },
      'players_limit': spec.ballMachine ? 1 : draft.playersLimit,
      'rsvp_limit': spec.ballMachine ? 1 : draft.rsvpLimit,
      'player_acceptance_type': draft.playersSetDirectly
          ? acceptPickManually
          : draft.acceptanceType,
      if (spec.individualLesson)
        'assign_type': draft.assignNow
            ? MatchKeys.assignNow
            : MatchKeys.assignLater,
      if (spec.ballMachine) 'assign_type': MatchKeys.assignNow,
      if (spec.usesScoring) ...{
        'scoring_format': scoring!.format,
        'deciding_set_type': scoring.decidingSetType,
        'minimum_score_to_win': scoring.minimumScore,
        'allow_participants_to_log_results':
            draft.allowParticipantsToLogResults,
        'assign_type': assignNow ? MatchKeys.assignNow : MatchKeys.assignLater,
        'all_courts_different_schedule_options': false,
      },
      if (spec.isRoundRobin) ...{
        'game_type': draft.gameType,
        if (draft.partnershipType != null &&
            draft.gameType != MatchKeys.gameSingles)
          'partnership_type': draft.partnershipType,
        'event_sub_type': draft.eventSubType,
      },
      if (spec.usesCourts && !spec.hasMatches && !spec.ballMachine)
        'no_of_courts': draft.courtCount,
      if (draft.notes.trim().isNotEmpty) 'notes_for_event': draft.notes.trim(),
      if (!spec.ballMachine)
        'event_participants_attributes': [
          for (final user in draft.coaches)
            {
              'user_id': user.id,
              'is_player': false,
              'is_coach': true,
              'is_audience': false,
            },
          for (final user in assignNow ? const <AppUser>[] : draft.invitees)
            {
              'user_id': user.id,
              'is_player': !spec.participantsAreAudience,
              'is_coach': false,
              'is_audience': spec.participantsAreAudience,
            },
        ],
      'event_schedule_options_attributes': [
        {
          'place_id': place!.id,
          'start_time': formatStartTime(start),
          'duration': draft.durationMinutes,
          if (draft.timezoneInfoId != null)
            'timezone_info_id': draft.timezoneInfoId,
        },
      ],
      if (spec.hasMatches || spec.ballMachine) ...{
        'event_matches_attributes': _matchBodies(
          draft,
          spec.ballMachine ? ballMatches : draft.matches,
          courts,
          team?.id,
          draft.opponentTeam?.id,
          withPlayers: spec.ballMachine || draft.assignNow,
        ),
        // Native sends an empty list: each match carries its own court.
        'event_venue_courts_attributes': const <Map<String, dynamic>>[],
      } else if (spec.usesCourts)
        'event_venue_courts_attributes': [
          for (var i = 0; i < courts.length; i++)
            {'place_court_id': courts[i], 'order': i + 1},
        ],
      'event_screen': 'es_review',
      'screen_flow_path': _flowPath(draft, spec),
    },
  };
}
