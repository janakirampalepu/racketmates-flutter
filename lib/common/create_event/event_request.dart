import 'package:intl/intl.dart';
import 'package:racketmates/common/create_event/event_draft.dart';

/// Native `YYYY_MM_DD_T_HH_MM_SS` = `yyyy-MM-dd'T'HH:mm'Z'`: the venue's local
/// wall time with a literal `Z` (the zone travels in `timezone_info_id`).
String formatStartTime(DateTime start) =>
    "${DateFormat('yyyy-MM-dd').format(start)}T${DateFormat('HH:mm').format(start)}Z";

/// Screens opened by the wizard, in the native `EventCreateScreens` naming and
/// order for this event type (sent as `screen_flow_path`).
const _flowPath =
    'es_event_type_selection##es_sports_type##es_general_settings'
    '##es_invite_players_mgmt##es_courts_addition##es_invite_player_settings'
    '##es_review';

/// Body of `POST events` for a practice drill (no teams, matches or coaches),
/// built from the same fields the native `getCreateEventInfo()` sends.
/// Throws [StateError] when the draft is incomplete (screens validate first).
Map<String, dynamic> buildCreateEventBody(EventDraft draft) {
  final start = draft.start;
  final place = draft.place;
  if (draft.eventType == null ||
      draft.sport == null ||
      start == null ||
      place?.id == null) {
    throw StateError('incomplete event draft');
  }
  return {
    'event': {
      'event_type': draft.eventType,
      'sport_type': draft.sport!.key,
      // Non-team ("global") event: native sends an empty originator type.
      'originator_type': '',
      'with_coach': false,
      'with_audience': false,
      'request_save_as_draft': false,
      'allow_participants_manage_players': draft.allowParticipantsManagePlayers,
      'attendance_deadline_unit': draft.attendanceUnit,
      'attendance_deadline_unit_type': draft.attendanceUnitType,
      'player_pool': playerPoolInvitedOnly,
      'players_limit': draft.playersLimit,
      'rsvp_limit': draft.rsvpLimit,
      'player_acceptance_type': draft.acceptanceType,
      if (draft.notes.trim().isNotEmpty) 'notes_for_event': draft.notes.trim(),
      'event_participants_attributes': [
        for (final user in draft.invitees)
          {
            'user_id': user.id,
            'is_player': true,
            'is_coach': false,
            'is_audience': false,
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
      'event_venue_courts_attributes': [
        for (var i = 0; i < draft.courtIds.length; i++)
          {'place_court_id': draft.courtIds[i], 'order': i + 1},
      ],
      'event_screen': 'es_review',
      'screen_flow_path': _flowPath,
    },
  };
}
