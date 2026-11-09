import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// Whether a schedule-row action button should even be offered (native:
/// Android's `ScheduleV2ListAdapter` only shows the swipe row when
/// `access == UP_ENABLED`; iOS shows it for anything but `not_available`
/// and instead branches what tapping it does — followed here, since it
/// surfaces more to the user and this app already uses the same
/// enabled/disabled/needs-subscription/hidden model elsewhere, e.g.
/// `startGlobalCreateEvent`/`checkTeamAccess`).
bool canShowEventAction(EventSwipeAction? action) =>
    action?.action != null && action?.access != 'up_not_available';

/// Runs [onAllowed] when the action's permission allows it; otherwise
/// explains why (the server's own message, a subscription offer, or the
/// generic "blocked" text) instead of silently doing the same thing as a
/// usable button (native `performSwipeAction`/`permissonDisable`/
/// `requiresSubscriptionSheet`).
Future<void> handleEventActionTap(
  BuildContext context,
  WidgetRef ref,
  EventSwipeAction? action,
  VoidCallback onAllowed,
) async {
  final l10n = AppLocalizations.of(context);
  final session = ref.read(sessionInfoControllerProvider);
  final info = action == null
      ? null
      : AccessInfo(access: action.access, message: action.message);
  switch (decideAccess(info, subscribed: session.isSubscribed)) {
    case AccessDecision.allowed:
    case AccessDecision.hidden:
      onAllowed();
    case AccessDecision.needsSubscription:
      if (ref.read(billingSupportedProvider)) {
        unawaited(context.push(AppRoutes.subscription));
      } else {
        await _explain(context, l10n.accessNeedsSubscription, l10n);
      }
    case AccessDecision.blocked:
      final message = (action?.message ?? '').isNotEmpty
          ? action!.message!
          : l10n.accessBlocked;
      await _explain(context, message, l10n);
  }
}

Future<void> _explain(
  BuildContext context,
  String text,
  AppLocalizations l10n,
) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    content: Text(text),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: Text(l10n.closeAction),
      ),
    ],
  ),
);
