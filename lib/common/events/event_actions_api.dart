import 'package:dio/dio.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:retrofit/retrofit.dart';

part 'event_actions_api.g.dart';

/// RSVP and manage actions on an event (existing endpoints, same paths and
/// bodies as the native app). RSVP calls return the updated event envelope.
@RestApi()
abstract class EventActionsApi {
  factory EventActionsApi(Dio dio, {String? baseUrl}) = _EventActionsApi;

  @POST('events/{eventId}/event_participants/{participantId}/accept_invite')
  Future<EventDetailsResponse> acceptInvite(
    @Path('eventId') int eventId,
    @Path('participantId') int participantId,
    @Body() Map<String, dynamic> body,
  );

  @POST('events/{eventId}/event_participants/{participantId}/decline_invite')
  Future<EventDetailsResponse> declineInvite(
    @Path('eventId') int eventId,
    @Path('participantId') int participantId,
    @Body() Map<String, dynamic> body,
  );

  @POST('events/{eventId}/event_participants/{participantId}/rejoin_event')
  Future<EventDetailsResponse> rejoinEvent(
    @Path('eventId') int eventId,
    @Path('participantId') int participantId,
    @Body() Map<String, dynamic> body,
  );

  @POST('events/{eventId}/event_participants/{participantId}/leave_event')
  Future<EventDetailsResponse> leaveEvent(
    @Path('eventId') int eventId,
    @Path('participantId') int participantId,
  );

  @POST('events/{eventId}/event_participants/{participantId}/join_waitlist')
  Future<EventDetailsResponse> joinWaitlist(
    @Path('eventId') int eventId,
    @Path('participantId') int participantId,
    @Body() Map<String, dynamic> body,
  );

  @PUT('events/{eventId}/cancel_event')
  Future<void> cancelEvent(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );

  /// Confirms the scores another player submitted (event level).
  @POST('events/{eventId}/accept_scores')
  Future<EventDetailsResponse> acceptScores(@Path('eventId') int eventId);

  // --- Manage (organizer) actions; the event is reloaded afterwards ---

  @PUT('events/{eventId}/update_settings')
  Future<void> updateSettings(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );

  @PUT('events/{eventId}/reschedule_event')
  Future<void> rescheduleEvent(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );

  @POST('events/{eventId}/event_matches/{matchId}/update_scores')
  Future<void> updateScores(
    @Path('eventId') int eventId,
    @Path('matchId') int matchId,
    @Body() Map<String, dynamic> body,
  );

  @PUT('events/{eventId}/event_matches/{matchId}/unmark_as_unfinished_match')
  Future<void> unmarkUnfinishedMatch(
    @Path('eventId') int eventId,
    @Path('matchId') int matchId,
  );

  @PUT('events/{eventId}/pick_players')
  Future<void> pickPlayers(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );

  @PUT('events/{eventId}/remove_participants')
  Future<void> removeParticipants(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );

  @POST('events/{eventId}/add_participants')
  Future<void> addParticipants(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );
}
