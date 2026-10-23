import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/event_actions_repository.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_manage/event_manage_view_model.dart';
import 'package:racketmates/screens/event_manage_pairs/event_manage_pairs_test_ids.dart';

typedef _PairsData = ({
  List<List<EventParticipant>> pairs,
  List<EventParticipant> unpaired,
});

/// Pairs the server knows and the confirmed players without a partner, for the
/// match-type [filter] (null = everyone).
final _pairsProvider = FutureProvider.autoDispose
    .family<_PairsData, ({int eventId, String? filter})>((ref, q) async {
      final repo = ref.read(eventActionsRepositoryProvider);
      final groups = await repo.participants(q.eventId, groupBy: 'pairs');
      final loose = await repo.participants(
        q.eventId,
        preferredMatchType: q.filter,
        excludeWithPartner: true,
      );
      return (
        pairs: [for (final g in groups) ...?g.eventParticipantPairs],
        unpaired: [for (final g in loose) ...?g.eventParticipants],
      );
    });

/// Fixed partners (native `SetupFixedPartnersFragment`): the pairs players
/// chose, the players still without a partner (they play singles), and a way
/// to pair two of them before the rounds are generated.
class EventManagePairsScreen extends ConsumerStatefulWidget {
  const EventManagePairsScreen({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<EventManagePairsScreen> createState() =>
      _EventManagePairsScreenState();
}

class _EventManagePairsScreenState
    extends ConsumerState<EventManagePairsScreen> {
  String? _filter;
  final List<(EventParticipant, EventParticipant)> _added = [];
  final Set<int> _picked = {};
  String? _error;
  bool _busy = false;

  String _pairName((EventParticipant, EventParticipant) p) =>
      '${p.$1.name} & ${p.$2.name}';

  Future<void> _continue(_PairsData data) async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final vm = ref.read(eventManageViewModelProvider(widget.eventId).notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = await vm.generateRounds(
      partnerPairs: partnerPairsToSend(data.pairs, [
        for (final (a, b) in _added)
          if (a.person != null && b.person != null) (a.person!, b.person!),
      ]),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!outcome.ok) {
      setState(
        () => _error = outcome.error.isEmpty
            ? l10n.eventManageFailed
            : outcome.error,
      );
      return;
    }
    if (outcome.result == insufficientPlayersResult) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.eventRoundsWaitingTitle),
          content: Text(l10n.eventRoundsWaitingText),
          actions: [
            TestId(
              EventManagePairsTestIds.waitingOk,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.eventRoundsOk),
              ),
            ),
          ],
        ),
      );
      return;
    }
    unawaited(
      router.pushReplacement(AppRoutes.eventManageRoundsFor(widget.eventId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = ref
        .watch(eventDetailsViewModelProvider(widget.eventId))
        .event
        .value;
    final data = ref.watch(
      _pairsProvider((eventId: widget.eventId, filter: _filter)),
    );
    final both = event?.gameType == 'egt_both';

    Widget chip(String key, String label, String? value) => TestId(
      EventManagePairsTestIds.filter(key),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );

    Widget body(_PairsData d) {
      final addedIds = {
        for (final (a, b) in _added) ...[a.person, b.person],
      };
      final unpaired = [
        for (final p in d.unpaired)
          if (!addedIds.contains(p.person)) p,
      ];
      final picked = [
        for (final p in unpaired)
          if (_picked.contains(p.person)) p,
      ];
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.eventPairsInfo),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              l10n.eventPairsHeading,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (d.pairs.isEmpty && _added.isEmpty)
            TestId(
              EventManagePairsTestIds.noPairs,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.eventPairsNone),
              ),
            ),
          for (final (i, pair) in d.pairs.indexed)
            TestId(
              EventManagePairsTestIds.existing(i),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.people_outline),
                title: Text(pair.map((p) => p.name).join(' & ')),
              ),
            ),
          for (final (i, pair) in _added.indexed)
            TestId(
              EventManagePairsTestIds.added(i),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.people_outline),
                title: Text(_pairName(pair)),
                trailing: TestId(
                  EventManagePairsTestIds.removeAdded(i),
                  child: IconButton(
                    tooltip: l10n.eventPairsRemove,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _added.removeAt(i)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              l10n.eventPairsUnpaired,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (both)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  chip('all', l10n.eventPairsFilterAll, null),
                  chip(
                    'mt_doubles',
                    l10n.eventPairsFilterDoubles,
                    'mt_doubles',
                  ),
                  chip(
                    'mt_undecided',
                    l10n.eventPairsFilterBoth,
                    'mt_undecided',
                  ),
                ],
              ),
            ),
          if (unpaired.isEmpty)
            TestId(
              EventManagePairsTestIds.unpairedNone,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.eventPairsUnpairedNone),
              ),
            )
          else ...[
            Text(l10n.eventPairsPick),
            for (final p in unpaired)
              TestId(
                EventManagePairsTestIds.player(p.person ?? 0),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name),
                  value: _picked.contains(p.person),
                  // Two at a time: a third choice waits for a free place.
                  onChanged:
                      p.person == null ||
                          (!_picked.contains(p.person) && _picked.length >= 2)
                      ? null
                      : (v) => setState(
                          () => v == true
                              ? _picked.add(p.person!)
                              : _picked.remove(p.person),
                        ),
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TestId(
                EventManagePairsTestIds.pair,
                child: OutlinedButton(
                  onPressed: picked.length == 2
                      ? () => setState(() {
                          _added.add((picked[0], picked[1]));
                          _picked.clear();
                        })
                      : null,
                  child: Text(l10n.eventPairsPair),
                ),
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TestId(
                EventManagePairsTestIds.error,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          TestId(
            EventManagePairsTestIds.next,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _busy ? null : () => _continue(d),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.eventPairsContinue),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          EventManagePairsTestIds.title,
          child: Semantics(header: true, child: Text(l10n.eventPairsTitle)),
        ),
      ),
      body: TestId(
        EventManagePairsTestIds.root,
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.eventPairsLoadError)),
          data: body,
        ),
      ),
    );
  }
}
