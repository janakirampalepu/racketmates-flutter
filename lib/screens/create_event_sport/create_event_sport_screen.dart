import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_sport/create_event_sport_test_ids.dart';

/// Sport of the event (single choice).
class CreateEventSportScreen extends ConsumerWidget {
  const CreateEventSportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(createEventFlowProvider)?.sport;
    return StepScaffold(
      rootId: CreateEventSportTestIds.root,
      titleId: CreateEventSportTestIds.title,
      title: ref.msg(MessageKeys.createSportTitle, l10n.createSportTitle),
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventSportTestIds.next,
      onPrimary: selected == null
          ? null
          : () => context.push(
              AppRoutes.routeForStep(
                ref
                    .read(createEventFlowProvider.notifier)
                    .next(CreateEventStep.sport)!,
              ),
            ),
      onBack: () => context.pop(),
      children: [
        RadioGroup<SportKey>(
          groupValue: selected,
          onChanged: (sport) {
            if (sport != null) {
              ref.read(createEventFlowProvider.notifier).setSport(sport);
            }
          },
          child: Column(
            children: [
              for (final sport in SportKey.values)
                TestId(
                  CreateEventSportTestIds.sport(sport.key),
                  child: RadioListTile<SportKey>(
                    value: sport,
                    title: Text(sportLabel(l10n, sport)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
