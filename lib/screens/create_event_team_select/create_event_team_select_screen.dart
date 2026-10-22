import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_team_select/create_event_team_select_test_ids.dart';

/// Picks the team of a team event (native `SelectTeamV2Fragment`): teams the
/// user captains that play the event's sport.
class CreateEventTeamSelectScreen extends ConsumerStatefulWidget {
  const CreateEventTeamSelectScreen({super.key});

  @override
  ConsumerState<CreateEventTeamSelectScreen> createState() =>
      _CreateEventTeamSelectScreenState();
}

class _CreateEventTeamSelectScreenState
    extends ConsumerState<CreateEventTeamSelectScreen> {
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    final sport = (draft.spec?.needsSport ?? true) ? draft.sport?.key : null;
    final teams = ref.watch(captainTeamsProvider(sport));
    final scheme = Theme.of(context).colorScheme;

    Widget teamCard(Team team) {
      final selected = draft.team?.id == team.id;
      return TestId(
        CreateEventTeamSelectTestIds.team(team.id ?? 0),
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
              flow.setTeam(team);
            },
          ),
        ),
      );
    }

    return StepScaffold(
      rootId: CreateEventTeamSelectTestIds.root,
      titleId: CreateEventTeamSelectTestIds.title,
      title: l10n.createTeamSelectTitle,
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventTeamSelectTestIds.next,
      onPrimary: () {
        if (draft.team == null) {
          setState(() => _showError = true);
          return;
        }
        context.push(
          AppRoutes.routeForStep(flow.next(CreateEventStep.teamSelect)!),
        );
      },
      onBack: () => context.pop(),
      children: [
        ...teams.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (_, _) => [
            TestId(
              CreateEventTeamSelectTestIds.error,
              child: Text(l10n.teamsLoadError),
            ),
            TestId(
              CreateEventTeamSelectTestIds.retry,
              child: TextButton(
                onPressed: () => ref.invalidate(captainTeamsProvider(sport)),
                child: Text(l10n.retryAction),
              ),
            ),
          ],
          data: (list) => list.isEmpty
              ? [
                  TestId(
                    CreateEventTeamSelectTestIds.empty,
                    child: Text(l10n.createTeamSelectEmpty),
                  ),
                ]
              : [for (final t in list) teamCard(t)],
        ),
        if (_showError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TestId(
              CreateEventTeamSelectTestIds.requiredError,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.createTeamSelectRequired,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
