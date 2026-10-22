import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/people_kind.dart';
import 'package:racketmates/common/widgets/people_step.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_players/create_event_players_test_ids.dart';

/// Invited players, or attendees for a meetup (at least one).
class CreateEventPlayersScreen extends ConsumerWidget {
  const CreateEventPlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider);
    final audience = draft?.spec?.participantsAreAudience ?? false;
    final single = draft?.maxInvitees == 1;
    return PeopleStep(
      kind: PeopleKind.players,
      ids: CreateEventPlayersTestIds.ids,
      title: audience
          ? l10n.createPeopleTitle
          : single
          ? l10n.createSinglePlayerTitle
          : ref.msg(MessageKeys.createPlayersTitle, l10n.createPlayersTitle),
      searchHint: l10n.createPlayersSearchHint,
      emptyText: l10n.createPlayersEmpty,
      requiredError: audience
          ? l10n.createPeopleRequired
          : l10n.createPlayersRequired,
      nextLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      onContinue: () => context.push(
        AppRoutes.routeForStep(
          ref
              .read(createEventFlowProvider.notifier)
              .next(CreateEventStep.players)!,
        ),
      ),
    );
  }
}
