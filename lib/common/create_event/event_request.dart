import 'package:intl/intl.dart';
import 'package:racketmates/common/create_event/event_draft.dart';

/// Native `YYYY_MM_DD_T_HH_MM_SS` = `yyyy-MM-dd'T'HH:mm'Z'`: the venue's local
/// wall time with a literal `Z` (the zone travels in `timezone_info_id`).
String formatStartTime(DateTime start) =>
    "${DateFormat('yyyy-MM-dd').format(start)}T${DateFormat('HH:mm').format(start)}Z";

/// `screen_flow_path`: the screens opened for this event type, in native
/// `EventCreateScreens` naming (event-type specific).
String _flowPath(EventTypeSpec spec) => [
  'es_event_type_selection',
  if (spec.needsSport) 'es_sports_type',
  'es_general_settings',
  if (spec.needsCoaches) 'es_coaches_assign',
  'es_invite_players_mgmt',
  if (spec.usesCourts) 'es_courts_addition',
  'es_invite_player_settings',
  'es_review',
].join('##');

/// Body of `POST events` for events without matches or teams (practice drill,
/// group lesson, casual meetup), built from the fields the native
/// `getCreateEventInfo()` sends. Throws [StateError] when the draft is
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
  final courts = draft.courtIds.take(draft.courtCount).toList();
  return {
    'event': {
      'event_type': spec.key,
      if (spec.needsSport) 'sport_type': draft.sport!.key,
      // Non-team ("global") event: native sends an empty originator type.
      'originator_type': '',
      'with_coach': spec.needsCoaches,
      'with_audience': false,
      'request_save_as_draft': false,
      'allow_participants_manage_players': draft.allowParticipantsManagePlayers,
      'attendance_deadline_unit': draft.attendanceUnit,
      'attendance_deadline_unit_type': draft.attendanceUnitType,
      'player_pool': playerPoolInvitedOnly,
      'players_limit': draft.playersLimit,
      'rsvp_limit': draft.rsvpLimit,
      'player_acceptance_type': draft.acceptanceType,
      if (spec.usesCourts) 'no_of_courts': draft.courtCount,
      if (draft.notes.trim().isNotEmpty) 'notes_for_event': draft.notes.trim(),
      'event_participants_attributes': [
        for (final user in draft.coaches)
          {
            'user_id': user.id,
            'is_player': false,
            'is_coach': true,
            'is_audience': false,
          },
        for (final user in draft.invitees)
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
      if (spec.usesCourts)
        'event_venue_courts_attributes': [
          for (var i = 0; i < courts.length; i++)
            {'place_court_id': courts[i], 'order': i + 1},
        ],
      'event_screen': 'es_review',
      'screen_flow_path': _flowPath(spec),
    },
  };
}
