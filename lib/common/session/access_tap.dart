import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// The app-wide rule for a permission-gated button (native: `AccessState`'s
/// own doc comments — `UP_ENABLED` "for display and allow functionality",
/// `UP_DISABLED` "for display and display server msg", `UP_NOT_AVAILABLE`
/// "hidden", `UP_REQUIRES_SUBSCRIPTION` "show subscription alert"; confirmed
/// against real call sites, e.g. Android's `ActiveTeamsFragment`'s create
/// button and `ViewEventDetailsFragment.navigateToManageEventScreen`): a
/// button is **shown** for anything but "not available"; tapping it
/// performs the action when enabled, explains itself with the server's own
/// message when disabled, or offers a subscription when gated on one
/// (unless the user already has full access, in which case it behaves as
/// enabled) — never silently doing nothing and never doing the real action
/// for a state that isn't actually enabled.
Future<void> handleAccessTap(
  BuildContext context,
  WidgetRef ref,
  AccessInfo? info,
  VoidCallback onAllowed,
) async {
  final l10n = AppLocalizations.of(context);
  final session = ref.read(sessionInfoControllerProvider);
  switch (decideAccess(info, subscribed: session.isSubscribed)) {
    case AccessDecision.allowed:
    case AccessDecision.hidden:
      onAllowed();
    case AccessDecision.needsSubscription:
      if (ref.read(billingSupportedProvider)) {
        unawaited(context.push(AppRoutes.subscription));
      } else {
        await explainAccess(context, l10n.accessNeedsSubscription);
      }
    case AccessDecision.blocked:
      final message = (info?.message ?? '').isNotEmpty
          ? info!.message!
          : l10n.accessBlocked;
      await explainAccess(context, message);
  }
}

/// A plain dialog explaining why a disabled/blocked action can't run right
/// now — shared so every permission-gated button looks the same.
Future<void> explainAccess(BuildContext context, String text) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
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
}
