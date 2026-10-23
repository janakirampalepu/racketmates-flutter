import 'package:racketmates/common/events/models/event_details.dart';

/// RSVP actions the event details screen can offer. The backend decides which
/// are available (`primary_action` / `secondary_action` with `up_enabled`);
/// this maps them and marks the cases that still need option pickers.
enum RsvpAction {
  accept('event_view_action_accept'),
  decline('event_view_action_decline'),
  rejoin('event_view_action_rejoin'),
  leave('event_view_action_leave'),
  joinWaitlist('event_view_action_join_waitlist'),
  editResponse('event_view_action_edit_response');

  const RsvpAction(this.key);

  final String key;

  static RsvpAction? fromKey(String? key) {
    for (final a in values) {
      if (a.key == key) return a;
    }
    return null;
  }
}

/// Why an action cannot be completed from this build.
enum RsvpBlock {
  /// Several time/court options need the option picker, which is not migrated
  /// yet.
  needsOptionPicker,

  /// The backend says the action needs a subscription.
  requiresSubscription,
}

class RsvpOption {
  const RsvpOption(this.action, {this.block, this.message});

  final RsvpAction action;
  final RsvpBlock? block;

  /// Backend message for disabled/subscription states.
  final String? message;

  bool get isSupported => block == null;
}

/// Actions offered to the signed-in user, in primary-then-secondary order.
/// Mirrors the native `updateActionButtons` / `confirmBtnAction` rules.
List<RsvpOption> rsvpOptionsFor(EventDetails event) {
  final mine = event.currentUserEventDetails?.firstOrNull;
  if (mine == null) return const [];
  final options = <RsvpOption>[];
  for (final raw in [mine.primaryAction, mine.secondaryAction]) {
    final action = RsvpAction.fromKey(raw?.action);
    if (raw == null || action == null) continue;
    if (!raw.enabled) {
      if (raw.access == 'up_requires_subscription') {
        options.add(
          RsvpOption(
            action,
            block: RsvpBlock.requiresSubscription,
            message: raw.message,
          ),
        );
      }
      continue; // disabled / not available: not shown (as native)
    }
    options.add(RsvpOption(action, block: _blockFor(action, event, mine)));
  }
  return options;
}

RsvpBlock? _blockFor(
  RsvpAction action,
  EventDetails event,
  CurrentUserEventDetail mine,
) {
  final multipleOptions = mine.assignedOptions.length > 1;
  return switch (action) {
    RsvpAction.accept || RsvpAction.rejoin || RsvpAction.joinWaitlist =>
      multipleOptions ? RsvpBlock.needsOptionPicker : null,
    // Editing a response always revolves around choosing options.
    RsvpAction.editResponse => RsvpBlock.needsOptionPicker,
    RsvpAction.decline || RsvpAction.leave => null,
  };
}
