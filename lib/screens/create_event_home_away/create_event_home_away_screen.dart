import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_home_away/create_event_home_away_test_ids.dart';
import 'package:racketmates/screens/event_drafts/event_draft_actions.dart';

/// Which team is home and which is visiting (native `DefineHomeTeamFragment`).
/// The user's team starts as home; the home team can be left undecided.
class CreateEventHomeAwayScreen extends ConsumerWidget {
  const CreateEventHomeAwayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    final mine = draft.team?.name ?? '';
    final other = draft.opponent == OpponentKind.selectTeam
        ? draft.opponentTeam?.name ?? ''
        : draft.opponentName.trim();
    final home = draft.opponentIsHome ? other : mine;
    final away = draft.opponentIsHome ? mine : other;
    final decided = !draft.homeTeamNotDecided;

    Widget teamRow(String id, String label, String name) => TestId(
      id,
      child: Card(
        child: ListTile(title: Text(name), subtitle: Text(label)),
      ),
    );

    return StepScaffold(
      actions: eventDraftActions(context, ref),
      rootId: CreateEventHomeAwayTestIds.root,
      titleId: CreateEventHomeAwayTestIds.title,
      title: l10n.createHomeAwayTitle,
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventHomeAwayTestIds.next,
      onPrimary: () => context.push(
        AppRoutes.routeForStep(flow.next(CreateEventStep.homeAway)!),
      ),
      onBack: () => context.pop(),
      children: [
        if (decided) ...[
          teamRow(
            CreateEventHomeAwayTestIds.homeName,
            l10n.createHomeTeamLabel,
            home,
          ),
          Center(
            child: TestId(
              CreateEventHomeAwayTestIds.swap,
              child: IconButton(
                tooltip: l10n.createSwapTeams,
                icon: const Icon(Icons.swap_vert),
                onPressed: flow.swapHomeAway,
              ),
            ),
          ),
          teamRow(
            CreateEventHomeAwayTestIds.awayName,
            l10n.createAwayTeamLabel,
            away,
          ),
        ],
        const SizedBox(height: 8),
        TestId(
          CreateEventHomeAwayTestIds.notDecided,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.createHomeNotDecided),
            value: draft.homeTeamNotDecided,
            onChanged: (v) => flow.setHomeTeamNotDecided(value: v ?? false),
          ),
        ),
      ],
    );
  }
}
