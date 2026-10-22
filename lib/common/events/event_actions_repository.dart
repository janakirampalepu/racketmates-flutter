import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/event_actions_api.dart';
import 'package:racketmates/common/events/models/event_details.dart';

abstract class EventActionsRepository {
  /// Each RSVP call returns the updated event (and the server's message).
  Future<EventDetailsResponse> accept(
    int eventId,
    int participantId, {
    List<int> scheduleOptionIds = const [],
  });

  Future<EventDetailsResponse> decline(int eventId, int participantId);

  Future<EventDetailsResponse> rejoin(
    int eventId,
    int participantId, {
    required List<int> scheduleOptionIds,
  });

  Future<EventDetailsResponse> leave(int eventId, int participantId);

  Future<EventDetailsResponse> joinWaitlist(int eventId, int participantId);

  /// `PUT cancel_event`; [removeEvent] also deletes it from the schedule.
  Future<void> cancelEvent(
    int eventId, {
    String? reason,
    bool removeEvent = false,
  });

  /// `PUT update_settings` with `{event: {...}}`.
  Future<void> updateSettings(int eventId, Map<String, dynamic> body);

  /// `PUT reschedule_event` with `{event: {...}}`.
  Future<void> reschedule(int eventId, Map<String, dynamic> body);

  /// `POST event_matches/{id}/update_scores` with `{event_match: {...}}`.
  Future<void> updateScores(
    int eventId,
    int matchId,
    Map<String, dynamic> body,
  );

  Future<void> clearUnfinished(int eventId, int matchId);

  /// Confirms players who asked to join (`pick_players`).
  Future<void> pickPlayers(int eventId, List<int> userIds);

  /// Removes people from the event (`remove_from: event`).
  Future<void> removeParticipants(int eventId, List<int> userIds);

  /// Adds people as [role] (`ur_player`, `ur_coach`, `ur_audience`).
  Future<void> addParticipants(int eventId, List<int> userIds, String role);
}

class EventActionsRepositoryImpl implements EventActionsRepository {
  const EventActionsRepositoryImpl(this.api);

  final EventActionsApi api;

  /// The backend answers rule violations with HTTP 422 and a JSON envelope
  /// carrying `message`; that text is what the user should see.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioException(e);
    } on TypeError {
      throw const ParseFailure();
    }
  }

  @override
  Future<EventDetailsResponse> accept(
    int eventId,
    int participantId, {
    List<int> scheduleOptionIds = const [],
  }) => _guard(
    () => api.acceptInvite(eventId, participantId, {
      'event_schedule_option_ids': scheduleOptionIds,
    }),
  );

  @override
  Future<EventDetailsResponse> decline(int eventId, int participantId) =>
      _guard(
        () => api.declineInvite(eventId, participantId, {
          'event_schedule_option_ids': <int>[],
        }),
      );

  @override
  Future<EventDetailsResponse> rejoin(
    int eventId,
    int participantId, {
    required List<int> scheduleOptionIds,
  }) => _guard(
    () => api.rejoinEvent(eventId, participantId, {
      'event_schedule_option_ids': scheduleOptionIds,
    }),
  );

  @override
  Future<EventDetailsResponse> leave(int eventId, int participantId) =>
      _guard(() => api.leaveEvent(eventId, participantId));

  @override
  Future<EventDetailsResponse> joinWaitlist(int eventId, int participantId) =>
      _guard(() => api.joinWaitlist(eventId, participantId, {}));

  @override
  Future<void> cancelEvent(
    int eventId, {
    String? reason,
    bool removeEvent = false,
  }) => _guard(
    () => api.cancelEvent(eventId, {
      if (reason != null && reason.trim().isNotEmpty)
        'cancellation_reason': reason.trim(),
      'remove_event': removeEvent,
    }),
  );

  @override
  Future<void> updateSettings(int eventId, Map<String, dynamic> body) =>
      _guard(() => api.updateSettings(eventId, body));

  @override
  Future<void> reschedule(int eventId, Map<String, dynamic> body) =>
      _guard(() => api.rescheduleEvent(eventId, body));

  @override
  Future<void> updateScores(
    int eventId,
    int matchId,
    Map<String, dynamic> body,
  ) => _guard(() => api.updateScores(eventId, matchId, body));

  @override
  Future<void> clearUnfinished(int eventId, int matchId) =>
      _guard(() => api.unmarkUnfinishedMatch(eventId, matchId));

  @override
  Future<void> pickPlayers(int eventId, List<int> userIds) =>
      _guard(() => api.pickPlayers(eventId, {'user_ids': userIds}));

  @override
  Future<void> removeParticipants(int eventId, List<int> userIds) => _guard(
    () => api.removeParticipants(eventId, {
      'user_ids': userIds,
      'remove_from': 'event',
    }),
  );

  @override
  Future<void> addParticipants(int eventId, List<int> userIds, String role) =>
      _guard(
        () => api.addParticipants(eventId, {
          'user_ids': userIds,
          'participant_role': role,
        }),
      );
}

final eventActionsRepositoryProvider = Provider<EventActionsRepository>(
  (ref) =>
      EventActionsRepositoryImpl(EventActionsApi(ref.watch(apiDioProvider))),
);
