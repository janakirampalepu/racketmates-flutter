import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/people_search.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_opponent_select/create_event_opponent_select_test_ids.dart';
import 'package:racketmates/screens/event_drafts/event_draft_actions.dart';

/// Picks the opposing team (native `SelectTeamV2Fragment` in opponent mode):
/// any non-league team that plays the sport, except the user's own team.
class CreateEventOpponentSelectScreen extends ConsumerStatefulWidget {
  const CreateEventOpponentSelectScreen({super.key});

  @override
  ConsumerState<CreateEventOpponentSelectScreen> createState() =>
      _CreateEventOpponentSelectScreenState();
}

class _CreateEventOpponentSelectScreenState
    extends ConsumerState<CreateEventOpponentSelectScreen> {
  Timer? _debounce;
  String _query = '';
  bool _showError = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(playerSearchDebounce, () {
      if (mounted) setState(() => _query = text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    final sport = draft.sport?.key;
    final args = (sport: sport, exclude: draft.team?.id ?? 0, query: _query);
    final teams = ref.watch(opponentTeamsProvider(args));
    final scheme = Theme.of(context).colorScheme;

    Widget teamCard(Team team) {
      final selected = draft.opponentTeam?.id == team.id;
      return TestId(
        CreateEventOpponentSelectTestIds.team(team.id ?? 0),
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: ListTile(
            selected: selected,
            title: Text(team.name ?? ''),
            subtitle: Text(
              [
                ref.refLabel(team.teamType, teamTypeLabel(l10n, team.teamType)),
                teamSportsText(l10n, team),
              ].where((s) => s.isNotEmpty).join(' · '),
            ),
            trailing: selected ? const Icon(Icons.check_circle) : null,
            onTap: () {
              setState(() => _showError = false);
              flow.setOpponentTeam(team);
            },
          ),
        ),
      );
    }

    return StepScaffold(
      actions: eventDraftActions(context, ref),
      rootId: CreateEventOpponentSelectTestIds.root,
      titleId: CreateEventOpponentSelectTestIds.title,
      title: l10n.createOpponentTitle,
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventOpponentSelectTestIds.next,
      onPrimary: () {
        if (draft.opponentTeam == null) {
          setState(() => _showError = true);
          return;
        }
        context.push(
          AppRoutes.routeForStep(flow.next(CreateEventStep.opponentSelect)!),
        );
      },
      onBack: () => context.pop(),
      children: [
        TestId(
          CreateEventOpponentSelectTestIds.search,
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: l10n.createOpponentSearchHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: _onSearch,
          ),
        ),
        const SizedBox(height: 12),
        ...teams.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (_, _) => [
            TestId(
              CreateEventOpponentSelectTestIds.error,
              child: Text(l10n.teamsLoadError),
            ),
            TestId(
              CreateEventOpponentSelectTestIds.retry,
              child: TextButton(
                onPressed: () => ref.invalidate(opponentTeamsProvider(args)),
                child: Text(l10n.retryAction),
              ),
            ),
          ],
          data: (list) => list.isEmpty
              ? [
                  TestId(
                    CreateEventOpponentSelectTestIds.empty,
                    child: Text(l10n.createOpponentEmpty),
                  ),
                ]
              : [for (final t in list) teamCard(t)],
        ),
        if (_showError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TestId(
              CreateEventOpponentSelectTestIds.requiredError,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.createOpponentRequired,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
