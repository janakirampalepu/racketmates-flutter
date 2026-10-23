import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/rsvp_actions.dart';

enum FeedbackKind { rsvp, cancel, scores, preferences }

/// One-shot message to show after an action (snack bar).
class EventFeedback {
  const EventFeedback.success(this.kind) : isError = false, text = null;
  const EventFeedback.error(this.kind, this.text) : isError = true;

  final FeedbackKind kind;

  /// Server-provided text (errors only); null = use the localized default.
  final String? text;
  final bool isError;
}

class EventDetailsState {
  const EventDetailsState({
    this.event = const AsyncLoading(),
    this.busyAction,
    this.cancelling = false,
    this.acceptingScores = false,
    this.savingPreferences = false,
    this.feedback,
    this.cancelled = false,
    this.removed = false,
  });

  final AsyncValue<EventDetails> event;

  /// RSVP action in flight (buttons disabled meanwhile).
  final RsvpAction? busyAction;
  final bool cancelling;

  /// `accept_scores` in flight.
  final bool acceptingScores;

  /// `update_rsvp_preference` in flight.
  final bool savingPreferences;
  final EventFeedback? feedback;

  /// The event was cancelled by this user (details reload shows the status).
  final bool cancelled;

  /// The event was cancelled and removed; the screen should close.
  final bool removed;

  bool get busy =>
      busyAction != null || cancelling || acceptingScores || savingPreferences;

  EventDetailsState copyWith({
    AsyncValue<EventDetails>? event,
    RsvpAction? Function()? busyAction,
    bool? cancelling,
    bool? acceptingScores,
    bool? savingPreferences,
    EventFeedback? Function()? feedback,
    bool? cancelled,
    bool? removed,
  }) => EventDetailsState(
    event: event ?? this.event,
    busyAction: busyAction != null ? busyAction() : this.busyAction,
    cancelling: cancelling ?? this.cancelling,
    acceptingScores: acceptingScores ?? this.acceptingScores,
    savingPreferences: savingPreferences ?? this.savingPreferences,
    feedback: feedback != null ? feedback() : this.feedback,
    cancelled: cancelled ?? this.cancelled,
    removed: removed ?? this.removed,
  );
}
