import 'package:dio/dio.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:retrofit/retrofit.dart';

part 'schedule_api.g.dart';

/// Read endpoints for home, schedule and event details (see
/// `docs/api-endpoint-decisions.md`). List parameters keep the native `[]`
/// names (`user_ids[]`, `event_roles[]`, `card_types[]`).
@RestApi()
abstract class ScheduleApi {
  factory ScheduleApi(Dio dio, {String? baseUrl}) = _ScheduleApi;

  /// Home upcoming events (`events_for=home_page_upcoming`), the schedule tabs
  /// (`events_for=upcoming|past` with `time_period=future|past`).
  @GET('schedule/scheduled_events')
  Future<ScheduleListResponse> scheduledEvents({
    @Query('per_page') int? perPage,
    @Query('events_for') String? eventsFor,
    @Query('time_period') String? timePeriod,
    @Query('page') int? page,
    @Query('team_id') int? teamId,
    @Query('user_ids[]') List<String>? userIds,
    @Query('event_roles[]') List<String>? eventRoles,
    @Query('sport_types[]') List<String>? sportTypes,
    @Query('hour_format') int? hourFormat,
  });

  /// Events that need a time picked (native `btnToBeScheduledEvent`'s own
  /// destination screen, not a Schedule tab). Same response shape as
  /// `scheduled_events`; Android sends no paging for it, so this app
  /// follows that and loads the whole list at once.
  @GET('schedule/to_be_scheduled')
  Future<ScheduleListResponse> toBeScheduled({
    @Query('status') String? status,
    @Query('team_id') int? teamId,
    @Query('user_ids[]') List<String>? userIds,
    @Query('event_roles[]') List<String>? eventRoles,
    @Query('sport_types[]') List<String>? sportTypes,
  });

  @GET('current_session/pending_actions')
  Future<PendingActionsResponse> pendingActions({
    @Query('team_id') int? teamId,
    @Query('user_ids[]') List<String>? userIds,
  });

  @GET('current_session/stats_summary')
  Future<StatsSummaryResponse> statsSummary({
    @Query('team_id') int? teamId,
    @Query('user_ids[]') List<String>? userIds,
  });

  @GET('current_session/player_cards')
  Future<PlayerCardsResponse> playerCards({
    @Query('user_ids[]') List<String>? userIds,
    @Query('card_types[]') List<String>? cardTypes,
  });

  @GET('events/{id}')
  Future<EventDetailsResponse> eventDetails(
    @Path('id') int id, {
    @Query('hour_format') int? hourFormat,
    @Query('view_type') String? viewType,
  });
}
