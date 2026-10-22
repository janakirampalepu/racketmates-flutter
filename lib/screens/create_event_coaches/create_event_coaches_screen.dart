import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/people_kind.dart';
import 'package:racketmates/common/widgets/people_step.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_coaches/create_event_coaches_test_ids.dart';

/// Coaches of a lesson (native `ES_COACHES_ASSIGN`); at least one.
class CreateEventCoachesScreen extends ConsumerWidget {
  const CreateEventCoachesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PeopleStep(
      kind: PeopleKind.coaches,
      ids: CreateEventCoachesTestIds.ids,
      title: l10n.createCoachesTitle,
      searchHint: l10n.createCoachesSearchHint,
      emptyText: l10n.createCoachesEmpty,
      requiredError: l10n.createCoachesRequired,
      nextLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      onContinue: () =>
          context.push(AppRoutes.routeForStep(CreateEventStep.players)),
    );
  }
}
