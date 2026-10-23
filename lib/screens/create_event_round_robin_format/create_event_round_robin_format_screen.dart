import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/screens/create_event_round_robin_format/create_event_round_robin_format_test_ids.dart';
import 'package:racketmates/screens/event_drafts/event_draft_actions.dart';

/// Round robin format (native `RoundRobinTypeSelectionFragment`): classic,
/// king of the court or manual. The descriptions depend on singles, rotating
/// partners or fixed partners.
class CreateEventRoundRobinFormatScreen extends ConsumerWidget {
  const CreateEventRoundRobinFormatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    final references = ref.watch(referenceDataProvider);
    final singles = draft.gameType == MatchKeys.gameSingles;
    final fixed = draft.partnershipType == MatchKeys.partnersFixed;

    final formats = [
      (
        key: MatchKeys.formatClassic,
        fallback: l10n.createFormatClassic,
        description: singles
            ? l10n.createFormatClassicSingles
            : fixed
            ? l10n.createFormatClassicFixed
            : l10n.createFormatClassicRotating,
      ),
      (
        key: MatchKeys.formatKingOfTheCourt,
        fallback: l10n.createFormatKing,
        description: singles
            ? l10n.createFormatKingSingles
            : fixed
            ? l10n.createFormatKingFixed
            : l10n.createFormatKingRotating,
      ),
      (
        key: MatchKeys.formatManual,
        fallback: l10n.createFormatManual,
        description: l10n.createFormatManualHint,
      ),
    ];

    return StepScaffold(
      actions: eventDraftActions(context, ref),
      rootId: CreateEventRoundRobinFormatTestIds.root,
      titleId: CreateEventRoundRobinFormatTestIds.title,
      title: l10n.createRoundRobinFormatTitle,
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventRoundRobinFormatTestIds.next,
      onPrimary: draft.eventSubType == null
          ? null
          : () => context.push(
              AppRoutes.routeForStep(
                flow.next(CreateEventStep.roundRobinFormat)!,
              ),
            ),
      onBack: () => context.pop(),
      children: [
        for (final f in formats)
          TestId(
            CreateEventRoundRobinFormatTestIds.format(f.key),
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: draft.eventSubType == f.key
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: draft.eventSubType == f.key ? 2 : 1,
                ),
              ),
              child: ListTile(
                selected: draft.eventSubType == f.key,
                title: Text(references.label(f.key) ?? f.fallback),
                subtitle: Text(f.description),
                trailing: draft.eventSubType == f.key
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: () => flow.setEventSubType(f.key),
              ),
            ),
          ),
      ],
    );
  }
}
