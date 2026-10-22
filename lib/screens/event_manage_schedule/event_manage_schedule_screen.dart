import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_when_where/create_event_when_where_screen.dart';
import 'package:racketmates/screens/create_event_when_where/create_event_when_where_view_model.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_manage/event_manage_view_model.dart';
import 'package:racketmates/screens/event_manage_schedule/event_manage_schedule_test_ids.dart';

/// Moves an event to another venue, time or court (native reschedule). It
/// reuses the create wizard's venue screen, started from the event's current
/// venue, time, courts and notes.
class EventManageScheduleScreen extends ConsumerStatefulWidget {
  const EventManageScheduleScreen({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<EventManageScheduleScreen> createState() =>
      _EventManageScheduleScreenState();
}

class _EventManageScheduleScreenState
    extends ConsumerState<EventManageScheduleScreen> {
  bool _seeded = false;

  Future<void> _save() async {
    final draft = ref.read(createEventFlowProvider);
    if (draft == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(eventManageViewModelProvider(widget.eventId).notifier)
        .reschedule(draft);
    if (!ok || !mounted) return;
    ref.read(createEventFlowProvider.notifier).reset();
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventManageSaved)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eventAsync = ref
        .watch(eventDetailsViewModelProvider(widget.eventId))
        .event;
    final manage = ref.watch(eventManageViewModelProvider(widget.eventId));
    final event = eventAsync.value;

    if (!_seeded && event != null && event.hasSingleSchedule) {
      // Seed once the event is known; the venue screen reads the draft in its
      // own initState, so it is only built afterwards.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _seeded) return;
        ref
            .read(createEventFlowProvider.notifier)
            .seed(rescheduleDraftFor(event));
        setState(() => _seeded = true);
        // After the venue screen is built, so its view model has a listener.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(whenWhereViewModelProvider.notifier).loadPlaceCourts();
          }
        });
      });
    }
    if (!_seeded) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(
          child: eventAsync.hasError
              ? Text(l10n.eventLoadError)
              : event != null && !event.hasSingleSchedule
              ? Text(l10n.eventManageScheduleUnsupported)
              : const CircularProgressIndicator(),
        ),
      );
    }
    return CreateEventWhenWhereScreen(
      onSave: _save,
      saving: manage.busy,
      footer: manage.error == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TestId(
                EventManageScheduleTestIds.error,
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
    );
  }
}
