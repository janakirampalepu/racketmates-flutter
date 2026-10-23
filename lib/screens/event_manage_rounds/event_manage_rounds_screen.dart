import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/events/event_actions_repository.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/event_match_models.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/places/places_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_manage/event_manage_view_model.dart';
import 'package:racketmates/screens/event_manage_rounds/event_manage_rounds_test_ids.dart';

/// Courts of the event's venue that its matches can move to.
final _roundCourtsProvider = FutureProvider.autoDispose
    .family<List<PlaceCourt>, int>((ref, eventId) async {
      final event = ref
          .watch(eventDetailsViewModelProvider(eventId))
          .event
          .value;
      final placeId = event?.eventScheduleOptions?.firstOrNull?.place?.id;
      if (event == null || placeId == null) return const [];
      final details = await ref.read(placesRepositoryProvider).details(placeId);
      final allowed = roundCourtIds(event);
      return [
        for (final c in details.placeCourts ?? const <PlaceCourt>[])
          if (c.id != null && (allowed.isEmpty || allowed.contains(c.id))) c,
      ];
    });

/// The rounds of a round robin (native `SetupRoundsFragment`): pick a round to
/// see its matches. Organizers of a manual round robin add and remove rounds
/// and matches and move a match to another court. Players are assigned by the
/// server when rounds are generated.
class EventManageRoundsScreen extends ConsumerStatefulWidget {
  const EventManageRoundsScreen({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<EventManageRoundsScreen> createState() =>
      _EventManageRoundsScreenState();
}

class _EventManageRoundsScreenState
    extends ConsumerState<EventManageRoundsScreen> {
  int? _selected;

  Future<bool> _confirm({
    required String title,
    required String text,
    required String yes,
    required String no,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TestId(
              EventManageRoundsTestIds.confirmNo,
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(no),
              ),
            ),
            TestId(
              EventManageRoundsTestIds.confirmYes,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(yes),
              ),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _pickCourt(EventMatch match) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final courts = ref.watch(_roundCourtsProvider(widget.eventId));
          return SafeArea(
            child: courts.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.eventLoadError),
              ),
              data: (list) => ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: Text(l10n.eventMatchCourtTitle)),
                  if (list.isEmpty)
                    TestId(
                      EventManageRoundsTestIds.courtNone,
                      child: ListTile(title: Text(l10n.eventMatchNoCourts)),
                    ),
                  for (final c in list)
                    TestId(
                      EventManageRoundsTestIds.court(c.id!),
                      child: ListTile(
                        title: Text(c.name ?? ''),
                        selected: c.id == match.placeCourt?.id,
                        onTap: () => Navigator.of(sheetContext).pop(c.id),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (picked == null || picked == match.placeCourt?.id || match.id == null) {
      return;
    }
    await ref
        .read(eventManageViewModelProvider(widget.eventId).notifier)
        .moveMatchToCourt(match.id!, picked);
  }

  Future<void> _assign(
    EventRound round,
    EventMatch match,
    EventMatchSide side,
  ) async {
    if (side.id == null) return;
    final others = [
      for (final m in round.eventMatches ?? const <EventMatch>[])
        for (final s in m.eventMatchSides ?? const <EventMatchSide>[])
          if (s.id != side.id) ...sidePlayerIds(s),
    ];
    final picked = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssignSheet(
        eventId: widget.eventId,
        capacity: sideCapacity(match),
        current: sidePlayerIds(side),
        others: others,
      ),
    );
    if (picked == null || !mounted) return;
    await ref
        .read(eventManageViewModelProvider(widget.eventId).notifier)
        .assignPlayers(round, match, side, picked);
  }

  Future<void> _removeMatch(EventMatch match) async {
    final l10n = AppLocalizations.of(context);
    if (match.id == null) return;
    final yes = await _confirm(
      title: l10n.eventMatchRemoveTitle,
      text: l10n.eventMatchRemoveText,
      yes: l10n.eventMatchRemove,
      no: l10n.teamActionNo,
    );
    if (!yes || !mounted) return;
    await ref
        .read(eventManageViewModelProvider(widget.eventId).notifier)
        .removeMatch(match.id!);
  }

  Future<void> _removeRound(EventRound round) async {
    final l10n = AppLocalizations.of(context);
    if (round.id == null) return;
    final yes = await _confirm(
      title: l10n.eventRoundRemoveTitle,
      text: l10n.eventRoundRemoveText,
      yes: l10n.eventRoundRemove,
      no: l10n.eventRoundKeep,
    );
    if (!yes || !mounted) return;
    final ok = await ref
        .read(eventManageViewModelProvider(widget.eventId).notifier)
        .removeRound(round.id!);
    if (ok && mounted) setState(() => _selected = null);
  }

  Future<void> _addRound(List<EventRound> before) async {
    final ok = await ref
        .read(eventManageViewModelProvider(widget.eventId).notifier)
        .addRound();
    if (!ok || !mounted) return;
    // Show the new round: the one that was not there before.
    final after =
        ref
            .read(eventDetailsViewModelProvider(widget.eventId))
            .event
            .value
            ?.eventRounds ??
        const <EventRound>[];
    final known = {for (final r in before) r.id};
    final added = after.where((r) => !known.contains(r.id));
    setState(() => _selected = added.lastOrNull?.id ?? after.lastOrNull?.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eventAsync = ref
        .watch(eventDetailsViewModelProvider(widget.eventId))
        .event;
    final event = eventAsync.value;
    final manage = ref.watch(eventManageViewModelProvider(widget.eventId));
    final rounds = [...?event?.eventRounds]
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    final editable = event != null && canEditRounds(event);
    final current = rounds.isEmpty
        ? null
        : rounds.firstWhere(
            (r) => r.id == _selected,
            orElse: () => rounds.first,
          );

    Widget sideRow(
      EventRound round,
      EventMatch m,
      EventMatchSide? s,
      String who,
    ) {
      if (s == null) return const SizedBox.shrink();
      final names = s.label.isEmpty ? l10n.eventRoundNoPlayers : s.label;
      return TestId(
        EventManageRoundsTestIds.side(s.id ?? 0),
        child: InkWell(
          onTap: manage.busy || s.id == null
              ? null
              : () => _assign(round, m, s),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(child: Text('$who: $names')),
                const Icon(Icons.edit_outlined, size: 18),
              ],
            ),
          ),
        ),
      );
    }

    Widget matchCard(EventRound round, EventMatch m) {
      final players = '${m.top?.label ?? ''} vs ${m.bottom?.label ?? ''}'
          .trim();
      return TestId(
        EventManageRoundsTestIds.match(m.id ?? 0),
        child: Card(
          child: ListTile(
            title: Text(
              [
                l10n.eventMatchNumber(m.order ?? 0),
                ref.refLabel(m.matchType, humanizeKey(m.matchType)),
                m.placeCourt?.name ?? l10n.eventMatchNoCourt,
              ].join(' · '),
            ),
            subtitle: editable
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sideRow(round, m, m.top, l10n.eventRoundSideTop),
                      sideRow(round, m, m.bottom, l10n.eventRoundSideBottom),
                    ],
                  )
                : Text(players),
            trailing: editable && m.id != null
                ? TestId(
                    EventManageRoundsTestIds.matchMenu(m.id!),
                    child: PopupMenuButton<String>(
                      tooltip: l10n.moreOptionsLabel,
                      enabled: !manage.busy,
                      onSelected: (v) =>
                          v == 'court' ? _pickCourt(m) : _removeMatch(m),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'court',
                          child: TestId(
                            EventManageRoundsTestIds.matchCourt(m.id!),
                            child: Text(l10n.eventMatchChangeCourt),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: TestId(
                            EventManageRoundsTestIds.matchRemove(m.id!),
                            child: Text(l10n.eventMatchRemove),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      );
    }

    Widget body(EventDetails e) {
      if (rounds.isEmpty) {
        return Center(
          child: TestId(
            EventManageRoundsTestIds.empty,
            child: Text(l10n.eventRoundsEmpty),
          ),
        );
      }
      final matches = [...?current?.eventMatches]
        ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final r in rounds)
                TestId(
                  EventManageRoundsTestIds.round(r.id ?? 0),
                  child: ChoiceChip(
                    label: Text(l10n.eventRoundNumber(r.order ?? 0)),
                    selected: r.id == current?.id,
                    onSelected: (_) => setState(() => _selected = r.id),
                  ),
                ),
              if (editable)
                TestId(
                  EventManageRoundsTestIds.add,
                  child: ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(l10n.eventRoundAdd),
                    onPressed: manage.busy ? null : () => _addRound(rounds),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final m in matches) matchCard(current!, m),
          if (editable && current != null && canRemoveRound(rounds, current))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TestId(
                EventManageRoundsTestIds.remove,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: manage.busy ? null : () => _removeRound(current),
                  child: Text(l10n.eventRoundRemove),
                ),
              ),
            ),
          if (manage.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TestId(
                EventManageRoundsTestIds.error,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    manage.error!.isEmpty
                        ? l10n.eventManageFailed
                        : manage.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
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
          EventManageRoundsTestIds.title,
          child: Semantics(header: true, child: Text(l10n.eventRoundsTitle)),
        ),
      ),
      body: TestId(
        EventManageRoundsTestIds.root,
        child: event == null
            ? Center(
                child: eventAsync.hasError
                    ? Text(l10n.eventLoadError)
                    : const CircularProgressIndicator(),
              )
            : body(event),
      ),
    );
  }
}

/// Pick the players of one side of a round match from the confirmed players
/// who are not on another side of the round.
class _AssignSheet extends ConsumerStatefulWidget {
  const _AssignSheet({
    required this.eventId,
    required this.capacity,
    required this.current,
    required this.others,
  });

  final int eventId;
  final int capacity;
  final List<int> current;
  final List<int> others;

  @override
  ConsumerState<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends ConsumerState<_AssignSheet> {
  late final List<int> _selected = [...widget.current];
  List<EventParticipant>? _players;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load(''));
  }

  Future<void> _load(String search) async {
    final request = ++_request;
    try {
      final groups = await ref
          .read(eventActionsRepositoryProvider)
          .participants(
            widget.eventId,
            groupBy: 'partnership',
            include: widget.current,
            exclude: widget.others,
            search: search,
          );
      if (!mounted || request != _request) return;
      setState(() {
        _failed = false;
        _players = [for (final g in groups) ...?g.eventParticipants];
      });
    } on Object {
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final players = _players;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Semantics(
                  header: true,
                  child: Text(l10n.eventAssignTitle),
                ),
                subtitle: Text(l10n.eventAssignLimit(widget.capacity)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TestId(
                  EventManageRoundsTestIds.assignSearch,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: l10n.eventAssignSearch,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => _load(v.trim()),
                  ),
                ),
              ),
              Flexible(
                child: _failed
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: TestId(
                          EventManageRoundsTestIds.assignError,
                          child: Text(l10n.eventPairsLoadError),
                        ),
                      )
                    : players == null
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : players.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: TestId(
                          EventManageRoundsTestIds.assignNone,
                          child: Text(l10n.eventAssignNone),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final p in players)
                            if (p.person != null)
                              TestId(
                                EventManageRoundsTestIds.assignPlayer(
                                  p.person!,
                                ),
                                child: CheckboxListTile(
                                  title: Text(p.name),
                                  value: _selected.contains(p.person),
                                  onChanged:
                                      !_selected.contains(p.person) &&
                                          _selected.length >= widget.capacity
                                      ? null
                                      : (v) => setState(
                                          () => v == true
                                              ? _selected.add(p.person!)
                                              : _selected.remove(p.person),
                                        ),
                                ),
                              ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TestId(
                  EventManageRoundsTestIds.assignSave,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: Text(l10n.eventAssignSave),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
