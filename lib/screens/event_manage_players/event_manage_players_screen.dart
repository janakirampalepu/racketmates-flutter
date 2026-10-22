import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_manage/event_manage_view_model.dart';
import 'package:racketmates/screens/event_manage_players/event_manage_players_test_ids.dart';

/// The people of an event, grouped by response (native `ManagePlayersFragment`):
/// confirm people who asked to join, remove people, add players or coaches.
class EventManagePlayersScreen extends ConsumerStatefulWidget {
  const EventManagePlayersScreen({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<EventManagePlayersScreen> createState() =>
      _EventManagePlayersScreenState();
}

class _EventManagePlayersScreenState
    extends ConsumerState<EventManagePlayersScreen> {
  final Set<int> _selected = {};

  EventManageViewModel get _vm =>
      ref.read(eventManageViewModelProvider(widget.eventId).notifier);

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.eventRemoveTitle),
        content: Text(l10n.eventRemoveMessage),
        actions: [
          TestId(
            EventManagePlayersTestIds.dialogDismiss,
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.closeAction),
            ),
          ),
          TestId(
            EventManagePlayersTestIds.dialogConfirm,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.eventRemoveSelected),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (await _vm.removeParticipants(_selected.toList()) && mounted) {
      setState(_selected.clear);
    }
  }

  Future<void> _confirm(List<int> ids) async {
    if (await _vm.pickPlayers(ids) && mounted) {
      setState(() => _selected.removeAll(ids));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eventAsync = ref
        .watch(eventDetailsViewModelProvider(widget.eventId))
        .event;
    final manage = ref.watch(eventManageViewModelProvider(widget.eventId));
    final event = eventAsync.value;

    String groupLabel(ParticipantGroup g) => switch (g) {
      ParticipantGroup.confirmed => l10n.eventGroupConfirmed,
      ParticipantGroup.toBeConfirmed => l10n.eventGroupToBeConfirmed,
      ParticipantGroup.waitlisted => l10n.eventGroupWaitlisted,
      ParticipantGroup.invited => l10n.eventGroupInvited,
      ParticipantGroup.declined => l10n.eventGroupDeclined,
      ParticipantGroup.other => l10n.eventGroupOther,
    };

    Widget row(EventParticipant p) {
      final id = p.userId ?? 0;
      final organizer = p.isOrganizer ?? false;
      return TestId(
        EventManagePlayersTestIds.participant(id),
        child: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _selected.contains(id),
          // The organizer cannot be removed.
          onChanged: organizer
              ? null
              : (v) => setState(
                  () => v ?? false ? _selected.add(id) : _selected.remove(id),
                ),
          title: Text(p.user?.displayName ?? ''),
          subtitle: Text(
            [
              ref.refLabel(p.status, humanizeKey(p.status)),
              if (organizer) p.participantLabel ?? '',
            ].where((s) => s.isNotEmpty).join(' · '),
          ),
        ),
      );
    }

    Widget section(String id, String title, List<EventParticipant> people) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: TestId(
                EventManagePlayersTestIds.group(id),
                child: Semantics(
                  header: true,
                  child: Text(
                    '$title (${people.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            for (final p in people) row(p),
          ],
        );

    Widget body(EventDetails e) {
      final all = e.eventParticipants ?? const <EventParticipant>[];
      final coaches = [
        for (final p in all)
          if (p.isCoach ?? false) p,
      ];
      final others = [
        for (final p in all)
          if (!(p.isCoach ?? false)) p,
      ];
      final groups = {
        for (final g in ParticipantGroup.values)
          g: [
            for (final p in others)
              if (groupOfStatus(p.status) == g) p,
          ],
      };
      final toConfirm = [
        for (final p in others)
          if (_selected.contains(p.userId) &&
              const {
                ParticipantGroup.toBeConfirmed,
                ParticipantGroup.waitlisted,
              }.contains(groupOfStatus(p.status)))
            p.userId!,
      ];
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              children: [
                if (all.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: TestId(
                      EventManagePlayersTestIds.empty,
                      child: Text(l10n.eventNoParticipants),
                    ),
                  ),
                if (coaches.isNotEmpty)
                  section('coaches', l10n.eventGroupCoaches, coaches),
                for (final g in ParticipantGroup.values)
                  if (groups[g]!.isNotEmpty)
                    section(g.name, groupLabel(g), groups[g]!),
                if (manage.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TestId(
                      EventManagePlayersTestIds.error,
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TestId(
                  EventManagePlayersTestIds.addPlayers,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_alt),
                    onPressed: manage.busy
                        ? null
                        : () => context.push(
                            AppRoutes.eventManageAddPeopleFor(
                              widget.eventId,
                              coaches: false,
                            ),
                          ),
                    label: Text(l10n.eventAddPlayers),
                  ),
                ),
                if (e.withCoach ?? false)
                  TestId(
                    EventManagePlayersTestIds.addCoaches,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.sports),
                      onPressed: manage.busy
                          ? null
                          : () => context.push(
                              AppRoutes.eventManageAddPeopleFor(
                                widget.eventId,
                                coaches: true,
                              ),
                            ),
                      label: Text(l10n.eventAddCoaches),
                    ),
                  ),
                if (toConfirm.isNotEmpty)
                  TestId(
                    EventManagePlayersTestIds.confirm,
                    child: FilledButton(
                      onPressed: manage.busy ? null : () => _confirm(toConfirm),
                      child: Text(l10n.eventConfirmSelected),
                    ),
                  ),
                if (_selected.isNotEmpty)
                  TestId(
                    EventManagePlayersTestIds.remove,
                    child: FilledButton.tonal(
                      onPressed: manage.busy ? null : _remove,
                      child: Text(l10n.eventRemoveSelected),
                    ),
                  ),
              ],
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
          EventManagePlayersTestIds.title,
          child: Semantics(header: true, child: Text(l10n.eventPlayersTitle)),
        ),
      ),
      body: TestId(
        EventManagePlayersTestIds.root,
        child: SafeArea(
          child: event == null
              ? Center(
                  child: eventAsync.hasError
                      ? Text(l10n.eventLoadError)
                      : const CircularProgressIndicator(),
                )
              : body(event),
        ),
      ),
    );
  }
}
