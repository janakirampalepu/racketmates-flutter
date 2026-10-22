import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_manage/event_manage_view_model.dart';
import 'package:racketmates/screens/event_manage_add_people/event_manage_add_people_test_ids.dart';
import 'package:racketmates/screens/event_manage_add_people/event_manage_add_people_view_model.dart';

/// Search and choose people to add to the event as players (or attendees) or
/// as coaches.
class EventManageAddPeopleScreen extends ConsumerStatefulWidget {
  const EventManageAddPeopleScreen({
    required this.eventId,
    required this.coaches,
    super.key,
  });

  final int eventId;
  final bool coaches;

  @override
  ConsumerState<EventManageAddPeopleScreen> createState() =>
      _EventManageAddPeopleScreenState();
}

class _EventManageAddPeopleScreenState
    extends ConsumerState<EventManageAddPeopleScreen> {
  final Set<int> _chosen = {};

  AddPeopleKey get _key => (eventId: widget.eventId, coaches: widget.coaches);

  Future<void> _add() async {
    final event = ref
        .read(eventDetailsViewModelProvider(widget.eventId))
        .event
        .value;
    if (event == null) return;
    final ok = await ref
        .read(eventManageViewModelProvider(widget.eventId).notifier)
        .addParticipants(
          _chosen.toList(),
          addRoleFor(event, coach: widget.coaches),
        );
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(addPeopleSearchProvider(_key));
    final vm = ref.read(addPeopleSearchProvider(_key).notifier);
    final manage = ref.watch(eventManageViewModelProvider(widget.eventId));

    Widget results() {
      if (state.loading && state.results.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.failure != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.createPlayersLoadError),
              TestId(
                EventManageAddPeopleTestIds.retry,
                child: TextButton(
                  onPressed: vm.search,
                  child: Text(l10n.retryAction),
                ),
              ),
            ],
          ),
        );
      }
      if (state.isEmpty) {
        return Center(
          child: TestId(
            EventManageAddPeopleTestIds.empty,
            child: Text(l10n.eventAddPeopleEmpty),
          ),
        );
      }
      return ListView.builder(
        itemCount: state.results.length,
        itemBuilder: (context, i) {
          final user = state.results[i];
          final id = user.id ?? i;
          return TestId(
            EventManageAddPeopleTestIds.person(id),
            child: CheckboxListTile(
              value: _chosen.contains(id),
              title: Text(user.displayName),
              onChanged: (v) => setState(
                () => v ?? false ? _chosen.add(id) : _chosen.remove(id),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          EventManageAddPeopleTestIds.title,
          child: Semantics(
            header: true,
            child: Text(
              widget.coaches ? l10n.eventAddCoaches : l10n.eventAddPlayers,
            ),
          ),
        ),
      ),
      body: TestId(
        EventManageAddPeopleTestIds.root,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: TestId(
                  EventManageAddPeopleTestIds.search,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      labelText: l10n.createPlayersSearchHint,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: vm.setQuery,
                  ),
                ),
              ),
              Expanded(child: results()),
              if (manage.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TestId(
                    EventManageAddPeopleTestIds.error,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: TestId(
                  EventManageAddPeopleTestIds.add,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _chosen.isEmpty || manage.busy ? null : _add,
                    child: manage.busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.eventAddPeopleAction),
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
