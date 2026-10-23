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
import 'package:racketmates/screens/create_event_team_dynamics/create_event_team_dynamics_test_ids.dart';
import 'package:racketmates/screens/event_drafts/event_draft_actions.dart';

/// Who a team game is played against (native `EventDynamicsFragment`): within
/// the team, another team in the app, or a team known only by name.
class CreateEventTeamDynamicsScreen extends ConsumerStatefulWidget {
  const CreateEventTeamDynamicsScreen({super.key});

  @override
  ConsumerState<CreateEventTeamDynamicsScreen> createState() =>
      _CreateEventTeamDynamicsScreenState();
}

class _CreateEventTeamDynamicsScreenState
    extends ConsumerState<CreateEventTeamDynamicsScreen> {
  late final TextEditingController _name;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    // Created up front: the name field only exists for one of the options, and
    // `dispose` must not be the first time the controller is touched.
    _name = TextEditingController(
      text: ref.read(createEventFlowProvider)?.opponentName ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Widget option({
      required OpponentKind kind,
      required String title,
      required String subtitle,
      Widget? extra,
    }) {
      final selected = draft.opponent == kind;
      return TestId(
        CreateEventTeamDynamicsTestIds.option(kind.key),
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                selected: selected,
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: selected ? const Icon(Icons.check_circle) : null,
                onTap: () {
                  setState(() => _showError = false);
                  flow.setOpponent(kind);
                },
              ),
              ?extra,
            ],
          ),
        ),
      );
    }

    return StepScaffold(
      actions: eventDraftActions(context, ref),
      rootId: CreateEventTeamDynamicsTestIds.root,
      titleId: CreateEventTeamDynamicsTestIds.title,
      title: l10n.createDynamicsTitle,
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventTeamDynamicsTestIds.next,
      onPrimary: draft.opponent == null
          ? null
          : () {
              if (draft.opponent == OpponentKind.namedTeam &&
                  draft.opponentName.trim().isEmpty) {
                setState(() => _showError = true);
                return;
              }
              context.push(
                AppRoutes.routeForStep(
                  flow.next(CreateEventStep.teamDynamics)!,
                ),
              );
            },
      onBack: () => context.pop(),
      children: [
        option(
          kind: OpponentKind.withinTeam,
          title: l10n.createDynamicsWithin,
          subtitle: l10n.createDynamicsWithinHint,
        ),
        option(
          kind: OpponentKind.selectTeam,
          title: l10n.createDynamicsOpponent,
          subtitle: l10n.createDynamicsOpponentHint,
        ),
        option(
          kind: OpponentKind.namedTeam,
          title: l10n.createDynamicsNamed,
          subtitle: l10n.createDynamicsNamedHint,
          extra: draft.opponent != OpponentKind.namedTeam
              ? null
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TestId(
                        CreateEventTeamDynamicsTestIds.name,
                        child: TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.createOpponentNameLabel,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            flow.setOpponentName(v);
                            if (v.trim().isNotEmpty && _showError) {
                              setState(() => _showError = false);
                            }
                          },
                        ),
                      ),
                      if (_showError)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: TestId(
                            CreateEventTeamDynamicsTestIds.nameError,
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                l10n.createOpponentNameRequired,
                                style: TextStyle(color: scheme.error),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
