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

  /// Generates the rounds of a round robin; `{}` (fixed partner pairs go in
  /// `event_partner_pairs`).
  @POST('events/{eventId}/generate_event_rounds')
  Future<EventDetailsResponse> generateRounds(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );

  @POST('events/{eventId}/event_rounds')
  Future<EventDetailsResponse> addRound(@Path('eventId') int eventId);

  @DELETE('events/{eventId}/event_rounds/{roundId}')
  Future<EventDetailsResponse> removeRound(
    @Path('eventId') int eventId,
    @Path('roundId') int roundId,
  );

  @DELETE('events/{eventId}/event_matches/{matchId}')
  Future<void> removeMatch(
    @Path('eventId') int eventId,
    @Path('matchId') int matchId,
  );

  @PUT('events/{eventId}/update_matches')
  Future<void> updateMatches(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );

  /// Participants, optionally grouped (`group_by`: `pairs`, `partnership`).
  /// The answer is parsed by `parseParticipantGroups`.
  @GET('events/{eventId}/event_participants')
  Future<dynamic> participants(
    @Path('eventId') int eventId,
    @Query('roles[]') List<String> roles,
    @Query('participant_statuses[]') List<String> statuses, {
    @Query('group_by') String? groupBy,
    @Query('include_user_ids[]') List<int>? includeUserIds,
    @Query('exclude_user_ids[]') List<int>? excludeUserIds,
    @Query('search') String? search,
    @Query('preferred_match_type') String? preferredMatchType,
    @Query('exclude_participants_with_partner') bool? excludeWithPartner,
  });

  /// Puts players on the sides of the matches of a round.
  @PUT('events/{eventId}/assign_players')
  Future<void> assignPlayers(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );

  // --- Manage (organizer) actions; the event is reloaded afterwards ---

  @PUT('events/{eventId}/update_settings')
  Future<void> updateSettings(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );

  @PUT('events/{eventId}/reschedule_matches')
  Future<void> rescheduleMatches(
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
