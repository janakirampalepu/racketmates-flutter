import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/session/access_tap.dart';

/// Whether a schedule-row action button should even be offered (native:
/// Android's `ScheduleV2ListAdapter` only shows the swipe row when
/// `access == UP_ENABLED`; iOS shows it for anything but `not_available`
/// and instead branches what tapping it does — followed here, since it
/// matches the app-wide rule in `handleAccessTap`).
bool canShowEventAction(EventSwipeAction? action) =>
    action?.action != null && action?.access != 'up_not_available';

/// [handleAccessTap] for an [EventSwipeAction] (same `access`/`message`
/// shape as [AccessInfo], just a different model class).
Future<void> handleEventActionTap(
  BuildContext context,
  WidgetRef ref,
  EventSwipeAction? action,
  VoidCallback onAllowed,
) => handleAccessTap(
  context,
  ref,
  action == null
      ? null
      : AccessInfo(access: action.access, message: action.message),
  onAllowed,
);
