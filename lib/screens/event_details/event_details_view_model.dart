import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/event_actions_repository.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/rsvp_actions.dart';
import 'package:racketmates/common/events/rsvp_preferences.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/screens/event_details/event_details_state.dart';
import 'package:racketmates/screens/home/home_view_model.dart';
import 'package:racketmates/screens/schedule/schedule_view_model.dart';
import 'package:racketmates/screens/team_details/team_schedule_view_model.dart';

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
  Future<void> rsvp(RsvpAction action, {RsvpPreferences? preferences}) async {
    final event = state.event.value;
    final participantId = _participantId;
    if (event == null || participantId == null || state.busy) return;
    final option = rsvpOptionsFor(event).where((o) => o.action == action);
    if (option.isEmpty || !option.first.isSupported) return;

    final repo = ref.read(eventActionsRepositoryProvider);
    final mine = event.currentUserEventDetails!.first;
    final extra = preferences == null
        ? const <String, dynamic>{}
        : preferenceFields(event, preferences, withNotes: true);
    state = state.copyWith(busyAction: () => action, feedback: () => null);
    try {
      final response = switch (action) {
        RsvpAction.accept => await repo.accept(
          eventId,
          participantId,
          preferences: extra,
        ),
        RsvpAction.decline => await repo.decline(eventId, participantId),
        RsvpAction.rejoin => await repo.rejoin(
          eventId,
          participantId,
          scheduleOptionIds: mine.selectedScheduleOptionIds ?? const [],
          preferences: extra,
        ),
        RsvpAction.leave => await repo.leave(eventId, participantId),
        RsvpAction.joinWaitlist => await repo.joinWaitlist(
          eventId,
          participantId,
          preferences: extra,
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

  /// Changes the partner and match type of the user's response.
  Future<void> updatePreferences(RsvpPreferences preferences) async {
    final event = state.event.value;
    final participantId = _participantId;
    if (event == null || participantId == null || state.busy) return;
    state = state.copyWith(savingPreferences: true, feedback: () => null);
    try {
      final response = await ref
          .read(eventActionsRepositoryProvider)
          .updatePreference(
            eventId,
            participantId,
            preferenceFields(event, preferences, withNotes: false),
          );
      if (!ref.mounted) return;
      final updated = response.event;
      state = state.copyWith(
        event: updated == null ? null : AsyncData(updated),
        savingPreferences: false,
        feedback: () => const EventFeedback.success(FeedbackKind.preferences),
      );
      if (updated == null) await load();
    } on AppFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        savingPreferences: false,
        feedback: () =>
            EventFeedback.error(FeedbackKind.preferences, _messageOf(failure)),
      );
    }
  }

  /// Confirms the scores another player submitted (`accept_scores`).
  Future<void> acceptScores() async {
    if (state.busy) return;
    state = state.copyWith(acceptingScores: true, feedback: () => null);
    try {
      final response = await ref
          .read(eventActionsRepositoryProvider)
          .acceptScores(eventId);
      if (!ref.mounted) return;
      final updated = response.event;
      state = state.copyWith(
        event: updated == null ? null : AsyncData(updated),
        acceptingScores: false,
        feedback: () => const EventFeedback.success(FeedbackKind.scores),
      );
      _refreshLists();
      if (updated == null) await load();
    } on AppFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        acceptingScores: false,
        feedback: () =>
            EventFeedback.error(FeedbackKind.scores, _messageOf(failure)),
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
      ..invalidate(scheduleListViewModelProvider)
      ..invalidate(teamScheduleViewModelProvider);
  }
}

final eventDetailsViewModelProvider = NotifierProvider.autoDispose
    .family<EventDetailsViewModel, EventDetailsState, int>(
      EventDetailsViewModel.new,
    );

/// Whether the server offers the signed-in user *confirm scores* (native
/// `hasAction(EVENT_VIEW_CONFIRM_SCORES)`): the primary or secondary action,
/// enabled.
bool canConfirmScores(EventDetails event) {
  final mine = event.currentUserEventDetails?.firstOrNull;
  return [mine?.primaryAction, mine?.secondaryAction].any(
    (a) => a?.action == 'user_action_confirm_scores' && (a?.enabled ?? false),
  );
}

/// Whether the "cancel event" menu item should be offered. Tapping it still
/// runs through `handleAccessTap`, same as managing — this only hides it
/// once the event is already cancelled, a state check, not a permission one.
bool canCancelEvent(EventDetails event) =>
    canManageEvent(event) && event.status != 'es_cancelled';

/// Whether the "manage this event" menu (settings, people, schedule, scores)
/// should be offered at all (`event.manage`). Native shows the button for
/// anything but "not available" and branches what tapping it does
/// (`ViewEventDetailsFragment.navigateToManageEventScreen`) — this used to
/// hide it for `up_disabled`/`up_requires_subscription` too, silently
/// dropping the server's own explanation; fixed to match native, see
/// `handleAccessTap`.
bool canManageEvent(EventDetails event) {
  final access = event.permission('event.manage')?.access;
  return access != null && access != 'up_not_available';
}
