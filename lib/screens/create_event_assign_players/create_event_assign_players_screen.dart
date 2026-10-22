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
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_assign_players/create_event_assign_players_test_ids.dart';

/// Puts players into the spots of every match (native `EventCourtFragment` /
/// `SelectCourtPlayersPicker`): singles has one spot per side, doubles two.
/// Every spot must be filled before continuing.
class CreateEventAssignPlayersScreen extends ConsumerStatefulWidget {
  const CreateEventAssignPlayersScreen({super.key});

  @override
  ConsumerState<CreateEventAssignPlayersScreen> createState() =>
      _CreateEventAssignPlayersScreenState();
}

class _CreateEventAssignPlayersScreenState
    extends ConsumerState<CreateEventAssignPlayersScreen> {
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    final references = ref.watch(referenceDataProvider);
    final scheme = Theme.of(context).colorScheme;

    String sideLabel(String side) =>
        side == MatchKeys.sideTop ? l10n.createSideTop : l10n.createSideBottom;

    return StepScaffold(
      rootId: CreateEventAssignPlayersTestIds.root,
      titleId: CreateEventAssignPlayersTestIds.title,
      title: l10n.createAssignPlayersTitle,
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventAssignPlayersTestIds.next,
      onPrimary: () {
        if (!draft.matches.every((m) => m.allSlotsFilled)) {
          setState(() => _showError = true);
          return;
        }
        context.push(
          AppRoutes.routeForStep(flow.next(CreateEventStep.assignPlayers)!),
        );
      },
      onBack: () => context.pop(),
      children: [
        for (var i = 0; i < draft.matches.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      '${l10n.createMatchNumber(i + 1)} · '
                      '${references.label(draft.matches[i].matchType) ?? _typeFallback(l10n, draft.matches[i].matchType)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final side in const [
                    MatchKeys.sideTop,
                    MatchKeys.sideBottom,
                  ]) ...[
                    const SizedBox(height: 8),
                    Text(
                      sideLabel(side),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    for (final slot in draft.matches[i].slots.where(
                      (s) => s.side == side,
                    ))
                      _SlotTile(
                        match: i,
                        slot: slot,
                        player: draft.matches[i].players[slot],
                        onClear: () => flow.clearSlot(i, slot),
                      ),
                  ],
                ],
              ),
            ),
          ),
        if (_showError)
          TestId(
            CreateEventAssignPlayersTestIds.error,
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.createAssignIncomplete,
                style: TextStyle(color: scheme.error),
              ),
            ),
          ),
      ],
    );
  }

  String _typeFallback(AppLocalizations l10n, String type) => switch (type) {
    MatchKeys.singles => l10n.createMatchSingles,
    MatchKeys.doubles => l10n.createMatchDoubles,
    _ => l10n.createMatchUndecided,
  };
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.match,
    required this.slot,
    required this.player,
    required this.onClear,
  });

  final int match;
  final MatchSlot slot;
  final AppUser? player;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = player?.displayName;
    return TestId(
      CreateEventAssignPlayersTestIds.slot(match, slot.side, slot.position),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(name == null ? Icons.person_add_alt : Icons.person),
        title: Text(name ?? l10n.createAddPlayer),
        trailing: name == null
            ? null
            : TestId(
                CreateEventAssignPlayersTestIds.clear(
                  match,
                  slot.side,
                  slot.position,
                ),
                child: IconButton(
                  tooltip: l10n.createRemovePlayer(name),
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                ),
              ),
        onTap: () => context.push(
          AppRoutes.slotPickerFor(
            match: match,
            side: slot.side,
            position: slot.position,
          ),
        ),
      ),
    );
  }
}
