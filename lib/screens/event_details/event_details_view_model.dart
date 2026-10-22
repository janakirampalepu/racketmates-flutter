import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/event_actions_repository.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/rsvp_actions.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/screens/event_details/event_details_state.dart';
import 'package:racketmates/screens/home/home_view_model.dart';
import 'package:racketmates/screens/schedule/schedule_view_model.dart';

/// Event details plus the signed-in user's RSVP and manage actions.
class EventDetailsViewModel extends Notifier<EventDetailsState> {
  EventDetailsViewModel(this.eventId);

  final int eventId;

  @override
  EventDetailsState build() {
    Future.microtask(load);
    return const EventDetailsState();
  }

  Future<void> load() async {
    state = state.copyWith(event: const AsyncLoading());
    try {
      final event = await ref
          .read(scheduleRepositoryProvider)
          .eventDetails(eventId, hourFormat: ref.read(hourFormatProvider));
      if (ref.mounted) state = state.copyWith(event: AsyncData(event));
    } on Object catch (error, stack) {
      if (ref.mounted) state = state.copyWith(event: AsyncError(error, stack));
    }
  }

  /// Reloads the event without the loading state: manage screens keep showing
  /// the event while it updates. A failed refresh keeps the previous data.
  Future<void> refresh() async {
    try {
      final event = await ref
          .read(scheduleRepositoryProvider)
          .eventDetails(eventId, hourFormat: ref.read(hourFormatProvider));
      if (ref.mounted) state = state.copyWith(event: AsyncData(event));
    } on Object {
      // Keep what is shown.
    }
    if (ref.mounted) _refreshLists();
  }

  void clearFeedback() => state = state.copyWith(feedback: () => null);

  int? get _participantId => state
      .event
      .value
      ?.currentUserEventDetails
      ?.firstOrNull
      ?.eventParticipantId;

  /// Performs a supported RSVP action for the signed-in user.
  Future<void> rsvp(RsvpAction action) async {
    final event = state.event.value;
    final participantId = _participantId;
    if (event == null || participantId == null || state.busy) return;
    final option = rsvpOptionsFor(event).where((o) => o.action == action);
    if (option.isEmpty || !option.first.isSupported) return;

    final repo = ref.read(eventActionsRepositoryProvider);
    final mine = event.currentUserEventDetails!.first;
    state = state.copyWith(busyAction: () => action, feedback: () => null);
    try {
      final response = switch (action) {
        RsvpAction.accept => await repo.accept(eventId, participantId),
        RsvpAction.decline => await repo.decline(eventId, participantId),
        RsvpAction.rejoin => await repo.rejoin(
          eventId,
          participantId,
          scheduleOptionIds: mine.selectedScheduleOptionIds ?? const [],
        ),
        RsvpAction.leave => await repo.leave(eventId, participantId),
        RsvpAction.joinWaitlist => await repo.joinWaitlist(
          eventId,
          participantId,
        ),
        RsvpAction.editResponse => throw StateError('unsupported'),
      };
      if (!ref.mounted) return;
      final updated = response.event;
      state = state.copyWith(
        event: updated == null ? null : AsyncData(updated),
        busyAction: () => null,
        feedback: () => const EventFeedback.success(FeedbackKind.rsvp),
      );
      _refreshLists();
      // The response may omit the event; reload so buttons match the server.
      if (updated == null) await load();
    } on AppFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        busyAction: () => null,
        feedback: () =>
            EventFeedback.error(FeedbackKind.rsvp, _messageOf(failure)),
      );
    }
  }

  /// Cancels the event (optionally removing it from the schedule).
  Future<void> cancelEvent({String? reason, bool removeEvent = false}) async {
    if (state.busy) return;
    state = state.copyWith(cancelling: true, feedback: () => null);
    try {
      await ref
          .read(eventActionsRepositoryProvider)
          .cancelEvent(eventId, reason: reason, removeEvent: removeEvent);
      if (!ref.mounted) return;
      state = state.copyWith(
        cancelling: false,
        cancelled: true,
        removed: removeEvent,
        feedback: () => const EventFeedback.success(FeedbackKind.cancel),
      );
      _refreshLists();
      if (!removeEvent) await load();
    } on AppFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        cancelling: false,
        feedback: () =>
            EventFeedback.error(FeedbackKind.cancel, _messageOf(failure)),
      );
    }
  }

  String? _messageOf(AppFailure failure) => switch (failure) {
    ServerFailure(message: final m) when m != null && m.isNotEmpty => m,
    UnauthorizedFailure(message: final m) when m != null && m.isNotEmpty => m,
    _ => null,
  };

  /// RSVP/cancel change what home and schedule show.
  void _refreshLists() {
    ref
      ..invalidate(homeViewModelProvider)
      ..invalidate(scheduleListViewModelProvider);
  }
}

final eventDetailsViewModelProvider = NotifierProvider.autoDispose
    .family<EventDetailsViewModel, EventDetailsState, int>(
      EventDetailsViewModel.new,
    );

/// Whether the signed-in user may cancel this event (`event.manage`).
bool canCancelEvent(EventDetails event) =>
    (event.permission('event.manage')?.enabled ?? false) &&
    event.status != 'es_cancelled';

/// Whether the signed-in user may manage this event (`event.manage`): change
/// its settings, people, schedule and scores.
bool canManageEvent(EventDetails event) =>
    event.permission('event.manage')?.enabled ?? false;
