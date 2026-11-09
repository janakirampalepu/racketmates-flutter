import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// Starts the create-event wizard for the signed-in user's own event (not a
/// team's), gated by the global `events.create` permission — native's
/// `addclubs_btn`/`AddButton` on Home and the main Schedule screen share
/// this exact check (`AppController`'s global permission vs. a team's own).
Future<void> startGlobalCreateEvent(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final session = ref.read(sessionInfoControllerProvider);
  final access = session.user?.permission('events.create');
  switch (decideAccess(access, subscribed: session.isSubscribed)) {
    case AccessDecision.allowed || AccessDecision.hidden:
      ref.read(createEventFlowProvider.notifier).start();
      if (context.mounted) unawaited(context.push(AppRoutes.createEvent));
    case AccessDecision.needsSubscription || AccessDecision.blocked:
      final needsSubscription =
          decideAccess(access, subscribed: session.isSubscribed) ==
          AccessDecision.needsSubscription;
      final text = (access?.message ?? '').isNotEmpty
          ? access!.message!
          : (needsSubscription
                ? l10n.accessNeedsSubscription
                : l10n.accessBlocked);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(text),
          actions: [
            if (needsSubscription && ref.read(billingSupportedProvider))
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.push(AppRoutes.subscription);
                },
                child: Text(l10n.accessUpgradeAction),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.closeAction),
            ),
          ],
        ),
      );
  }
}

/// Whether the button should even be offered (native hides it outright for
/// `up_not_available`, rather than showing a disabled state).
bool canOfferGlobalCreateEvent(WidgetRef ref) {
  final session = ref.watch(sessionInfoControllerProvider);
  return decideAccess(
        session.user?.permission('events.create'),
        subscribed: session.isSubscribed,
      ) !=
      AccessDecision.hidden;
}
