import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
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

    Widget matchCard(EventMatch m) {
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
            subtitle: Text(players),
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
          for (final m in matches) matchCard(m),
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
