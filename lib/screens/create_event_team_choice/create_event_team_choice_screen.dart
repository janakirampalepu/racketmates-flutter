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
import 'package:racketmates/screens/create_event_team_choice/create_event_team_choice_test_ids.dart';

/// Team or non-team event (native `SelectTeamGlobalEventFragment`). A team
/// event is for a team the user captains and invites that team's members.
class CreateEventTeamChoiceScreen extends ConsumerWidget {
  const CreateEventTeamChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Widget option({
      required String id,
      required String title,
      required String subtitle,
      required bool selected,
      required VoidCallback onTap,
    }) => TestId(
      id,
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
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: selected ? const Icon(Icons.check_circle) : null,
          onTap: onTap,
        ),
      ),
    );

    return StepScaffold(
      rootId: CreateEventTeamChoiceTestIds.root,
      titleId: CreateEventTeamChoiceTestIds.title,
      title: l10n.createTeamChoiceTitle,
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventTeamChoiceTestIds.next,
      onPrimary: draft.forTeam == null
          ? null
          : () => context.push(
              AppRoutes.routeForStep(flow.next(CreateEventStep.teamChoice)!),
            ),
      onBack: () => context.pop(),
      children: [
        option(
          id: CreateEventTeamChoiceTestIds.nonTeam,
          title: l10n.createTeamChoiceNonTeam,
          subtitle: l10n.createTeamChoiceNonTeamHint,
          selected: draft.forTeam == false,
          onTap: () => flow.setForTeam(value: false),
        ),
        option(
          id: CreateEventTeamChoiceTestIds.team,
          title: l10n.createTeamChoiceTeam,
          subtitle: l10n.createTeamChoiceTeamHint,
          selected: draft.forTeam == true,
          onTap: () => flow.setForTeam(value: true),
        ),
      ],
    );
  }
}
