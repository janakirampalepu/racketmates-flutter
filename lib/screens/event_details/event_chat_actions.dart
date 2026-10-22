import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/chat/chat_repository.dart';
import 'package:racketmates/common/chat/event_chat.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/chat_new/new_chat_test_ids.dart';

/// The chat rooms of [event] the user may open; empty hides the chat button.
List<EventChatOption> chatOptionsFor(WidgetRef ref, EventDetails event) {
  final session = ref.read(sessionControllerProvider);
  return eventChatOptions(
    event,
    subscribed: ref.watch(sessionInfoControllerProvider).isSubscribed,
    userId: session is SignedIn ? session.token.user?.id : null,
  );
}

/// Opens an event's chat room (native `ViewEventDetailsFragment`): with both a
/// players' and a captains' room the user chooses; a room that needs a
/// subscription offers it, a disabled one explains why, and one that does not
/// exist yet is created first. [onCreated] runs after a room was created so
/// the event can be reloaded.
Future<void> openEventChat(
  BuildContext context,
  WidgetRef ref,
  EventDetails event,
  List<EventChatOption> options, {
  required Future<void> Function() onCreated,
}) async {
  if (options.isEmpty) return;
  final l10n = AppLocalizations.of(context);
  var option = options.first;
  if (options.length > 1) {
    final chosen = await showModalBottomSheet<EventChatOption>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: TestId(
          EventChatTestIds.sheet,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.eventChatChoose,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final o in options)
                TestId(
                  o.kind == EventChatKind.players
                      ? EventChatTestIds.players
                      : EventChatTestIds.captains,
                  child: ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(
                      o.kind == EventChatKind.players
                          ? l10n.eventChatPlayers
                          : l10n.eventChatCaptains,
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(o),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    option = chosen;
  }

  switch (option.decision) {
    case AccessDecision.needsSubscription:
      if (ref.read(billingSupportedProvider)) {
        unawaited(context.push(AppRoutes.subscription));
      } else {
        await _explain(context, l10n.accessNeedsSubscription);
      }
    case AccessDecision.blocked:
      await _explain(
        context,
        (option.message ?? '').isNotEmpty
            ? option.message!
            : l10n.accessBlocked,
      );
    case AccessDecision.allowed || AccessDecision.hidden:
      final existing = option.channelUrl;
      if (existing != null) {
        unawaited(context.push(AppRoutes.chatChannelFor(existing)));
        return;
      }
      await _create(context, ref, event, option, onCreated);
  }
}

Future<void> _create(
  BuildContext context,
  WidgetRef ref,
  EventDetails event,
  EventChatOption option,
  Future<void> Function() onCreated,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final eventId = event.id;
  if (eventId == null) return;
  final session = ref.read(sessionControllerProvider);
  final repo = ref.read(chatRepositoryProvider);
  final teamId = loginTeamId(
    event,
    session is SignedIn ? session.token.user?.id : null,
  );
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: TestId(
            EventChatTestIds.opening,
            child: Semantics(
              label: l10n.eventChatOpening,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    ),
  );
  String? url;
  try {
    url = option.kind == EventChatKind.players
        ? await repo.playersChatRoom(eventId, teamId: teamId)
        : await repo.captainsChatRoom(eventId);
  } on AppFailure {
    url = null;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  if (url == null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventChatFailed)));
    return;
  }
  unawaited(onCreated());
  unawaited(router.push(AppRoutes.chatChannelFor(url)));
}

Future<void> _explain(BuildContext context, String text) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: TestId(EventChatTestIds.blockedDialog, child: Text(text)),
      actions: [
        TestId(
          EventChatTestIds.blockedClose,
          child: TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.closeAction),
          ),
        ),
      ],
    ),
  );
}
