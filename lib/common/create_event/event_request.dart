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
  if (spec.usesScoring) {
    return [
      for (final step in createEventStepsFor(
        spec.key,
        assignNow: draft.assignNow,
        forTeam: draft.forTeam ?? false,
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

List<Map<String, dynamic>> _matchBodies(
  EventDraft draft,
  List<int> courts,
  int? teamId,
) => [
  for (var i = 0; i < draft.matches.length; i++)
    {
      'match_type': draft.matches[i].matchType,
      'order': i + 1,
      if (i < courts.length) 'place_court_id': courts[i],
      'event_match_sides_attributes': [
        for (final side in const [MatchKeys.sideTop, MatchKeys.sideBottom])
          {
            // Both sides play for the user's team in a within-team event.
            'team_id': ?teamId,
            'side': side,
            'event_participants': [
              if (draft.assignNow)
                for (final e in draft.matches[i].players.entries)
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
  final courts = draft.courtIds.take(draft.courtCap).toList();
  final scoring = draft.scoring;
  // Players put into matches now are not event participants (native keeps
  // only coaches in that case) and the invite settings step is skipped.
  final assignNow = spec.hasMatches && draft.assignNow;
  return {
    'event': {
      'event_type': spec.key,
      if (spec.needsSport) 'sport_type': draft.sport!.key,
      // Non-team ("global") event: native sends an empty originator type.
      'originator_type': team == null ? '' : originatorTypeTeam,
      if (team != null) ...{
        'originator_id': team.id,
        'event_teams_attributes': [
          {
            'team_id': team.id,
            'event_team_type': 'ett_home',
            'logged_in_user_belongs_to_team': true,
          },
        ],
        'opponent_team_type': 'ott_within_team',
        if (spec.isRoundRobin)
          'consider_for_team_ranking': draft.considerForTeamRanking,
      },
      'with_coach': spec.needsCoaches,
      'with_audience': false,
      'request_save_as_draft': false,
      'allow_participants_manage_players': draft.allowParticipantsManagePlayers,
      'attendance_deadline_unit': draft.attendanceUnit,
      'attendance_deadline_unit_type': draft.attendanceUnitType,
      'player_pool': playerPoolInvitedOnly,
      'players_limit': draft.playersLimit,
      'rsvp_limit': draft.rsvpLimit,
      'player_acceptance_type': assignNow
          ? acceptPickManually
          : draft.acceptanceType,
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
      if (spec.usesCourts && !spec.hasMatches) 'no_of_courts': draft.courtCount,
      if (draft.notes.trim().isNotEmpty) 'notes_for_event': draft.notes.trim(),
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
      if (spec.hasMatches) ...{
        'event_matches_attributes': _matchBodies(draft, courts, team?.id),
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
