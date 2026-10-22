import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

/// Applies the team's permission [key] to an action the user just chose:
/// true when it may go ahead; a subscription-gated one offers the plans, a
/// disabled one shows the server's message, an unavailable one does nothing
/// (native `TeamHomeFragment` / `TeamActiveParticipantFragment`).
Future<bool> checkTeamAccess(
  BuildContext context,
  WidgetRef ref,
  Team team,
  String key,
) async {
  final l10n = AppLocalizations.of(context);
  final subscribed = ref.read(sessionInfoControllerProvider).isSubscribed;
  Future<void> explain(String text) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: TestId(TeamDetailsTestIds.accessDialog, child: Text(text)),
      actions: [
        TestId(
          TeamDetailsTestIds.accessDialogClose,
          child: TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.closeAction),
          ),
        ),
      ],
    ),
  );
  switch (memberAccess(team, key, subscribed: subscribed)) {
    case AccessDecision.allowed:
      return true;
    case AccessDecision.hidden:
      return false;
    case AccessDecision.needsSubscription:
      if (ref.read(billingSupportedProvider)) {
        unawaited(context.push(AppRoutes.subscription));
      } else {
        await explain(l10n.accessNeedsSubscription);
      }
      return false;
    case AccessDecision.blocked:
      final message = team.permission(key)?.message ?? '';
      await explain(message.isNotEmpty ? message : l10n.accessBlocked);
      return false;
  }
}
