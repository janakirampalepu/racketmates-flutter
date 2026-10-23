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
import 'package:racketmates/common/widgets/number_stepper.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_matches/create_event_matches_test_ids.dart';
import 'package:racketmates/screens/event_drafts/event_draft_actions.dart';

/// Courts maximum of a round robin (native stepper limit).
const maxRoundRobinCourts = 10;

/// Matches of a game (native `AddEventMatchesFragment`): add as many matches
/// as needed and choose singles, doubles or leave it open. For a round robin
/// the same step sets the number of courts, singles/doubles/both and, for
/// doubles, fixed or rotating partners.
class CreateEventMatchesScreen extends ConsumerWidget {
  const CreateEventMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    final roundRobin = draft.spec?.isRoundRobin ?? false;
    return StepScaffold(
      actions: eventDraftActions(context, ref),
      rootId: CreateEventMatchesTestIds.root,
      titleId: CreateEventMatchesTestIds.title,
      title: roundRobin
          ? l10n.createRoundRobinTitle
          : ref.msg(MessageKeys.createMatchesTitle, l10n.createMatchesTitle),
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventMatchesTestIds.next,
      onPrimary: () => context.push(
        AppRoutes.routeForStep(flow.next(CreateEventStep.matches)!),
      ),
      onBack: () => context.pop(),
      children: roundRobin
          ? _roundRobin(context, ref, draft, flow, l10n)
          : _matches(context, ref, draft, flow, l10n),
    );
  }

  List<Widget> _matches(
    BuildContext context,
    WidgetRef ref,
    EventDraft draft,
    CreateEventFlow flow,
    AppLocalizations l10n,
  ) {
    final references = ref.watch(referenceDataProvider);
    String typeLabel(String key, String fallback) =>
        references.label(key) ?? fallback;
    return [
      Text(l10n.createMatchesHint),
      const SizedBox(height: 12),
      for (var i = 0; i < draft.matches.length; i++)
        TestId(
          CreateEventMatchesTestIds.match(i),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.createMatchNumber(i + 1),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      if (draft.matches.length > 1)
                        TestId(
                          CreateEventMatchesTestIds.removeMatch(i),
                          child: IconButton(
                            tooltip: l10n.createRemoveMatch(i + 1),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => flow.removeMatch(i),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      for (final entry in {
                        MatchKeys.singles: typeLabel(
                          MatchKeys.singles,
                          l10n.createMatchSingles,
                        ),
                        MatchKeys.doubles: typeLabel(
                          MatchKeys.doubles,
                          l10n.createMatchDoubles,
                        ),
                        MatchKeys.undecided: typeLabel(
                          MatchKeys.undecided,
                          l10n.createMatchUndecided,
                        ),
                      }.entries)
                        ButtonSegment(
                          value: entry.key,
                          label: TestId(
                            CreateEventMatchesTestIds.matchType(i, entry.key),
                            child: Text(entry.value),
                          ),
                        ),
                    ],
                    selected: {draft.matches[i].matchType},
                    onSelectionChanged: (s) => flow.setMatchType(i, s.first),
                  ),
                ],
              ),
            ),
          ),
        ),
      TestId(
        CreateEventMatchesTestIds.addMatch,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: flow.addMatch,
          label: Text(
            ref.msg(MessageKeys.createAddMatchButton, l10n.createAddMatch),
          ),
        ),
      ),
    ];
  }

  List<Widget> _roundRobin(
    BuildContext context,
    WidgetRef ref,
    EventDraft draft,
    CreateEventFlow flow,
    AppLocalizations l10n,
  ) {
    Widget choice<T>({
      required String id,
      required String title,
      String? subtitle,
      required bool selected,
      required VoidCallback onTap,
    }) => TestId(
      id,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: ListTile(
          selected: selected,
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: selected ? const Icon(Icons.check_circle) : null,
          onTap: onTap,
        ),
      ),
    );

    return [
      Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(l10n.createRoundRobinCourtsHint),
            ),
          ),
          NumberStepper(
            idPrefix: CreateEventMatchesTestIds.courtCountPrefix,
            label: l10n.createCourtCountLabel,
            decreaseLabel: l10n.createDecrease,
            increaseLabel: l10n.createIncrease,
            value: draft.courtCount,
            max: maxRoundRobinCourts,
            onChanged: flow.setCourtCount,
          ),
        ],
      ),
      const SizedBox(height: 24),
      Semantics(
        header: true,
        child: Text(
          l10n.createRoundRobinPlayersLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          for (final entry in {
            MatchKeys.gameSingles: l10n.createGameSingles,
            MatchKeys.gameDoubles: l10n.createGameDoubles,
            MatchKeys.gameBoth: l10n.createGameBoth,
          }.entries)
            ButtonSegment(
              value: entry.key,
              label: TestId(
                CreateEventMatchesTestIds.gameType(entry.key),
                child: Text(entry.value),
              ),
            ),
        ],
        selected: {draft.gameType},
        onSelectionChanged: (s) => flow.setGameType(s.first),
      ),
      if (draft.gameType != MatchKeys.gameSingles) ...[
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            l10n.createPartnersLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        choice<String>(
          id: CreateEventMatchesTestIds.partners(MatchKeys.partnersRotating),
          title: l10n.createPartnersRotating,
          subtitle: l10n.createPartnersRotatingHint,
          selected: draft.partnershipType == MatchKeys.partnersRotating,
          onTap: () => flow.setPartnership(MatchKeys.partnersRotating),
        ),
        choice<String>(
          id: CreateEventMatchesTestIds.partners(MatchKeys.partnersFixed),
          title: l10n.createPartnersFixed,
          subtitle: l10n.createPartnersFixedHint,
          selected: draft.partnershipType == MatchKeys.partnersFixed,
          onTap: () => flow.setPartnership(MatchKeys.partnersFixed),
        ),
      ],
    ];
  }
}
