import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';

/// Read-only event view (native `ViewEventDetailsFragment`, participant view):
/// type, status, when/where, the user's own status, spots, notes, players.
/// RSVP, scoring, manage and chat entry points arrive with later milestones.
class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({required this.eventId, super.key});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(eventDetailsProvider(eventId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventDetailsTitle),
        leading: TestId(
          EventDetailsTestIds.back,
          child: BackButton(onPressed: () => context.pop()),
        ),
      ),
      body: TestId(
        EventDetailsTestIds.root,
        child: value.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.eventLoadError),
                TestId(
                  EventDetailsTestIds.retry,
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(eventDetailsProvider(eventId)),
                    child: Text(l10n.retryAction),
                  ),
                ),
              ],
            ),
          ),
          data: (event) => _Body(event: event),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.event});

  final EventDetails event;

  String _when(BuildContext context, EventScheduleOption option) {
    final start = option.start?.toLocal();
    if (start == null) return '';
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMEd(locale).format(start);
    final from = DateFormat.jm(locale).format(start);
    final end = option.end?.toLocal();
    final to = end == null ? '' : ' – ${DateFormat.jm(locale).format(end)}';
    return '$date, $from$to';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final option = event.eventScheduleOptions?.firstOrNull;
    final place = option?.place;
    final mine = event.currentUserEventDetails?.firstOrNull;
    final players = event.players;
    final spots = event.regularSpotsLeft;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TestId(
          EventDetailsTestIds.title,
          child: Semantics(
            header: true,
            child: Text(
              humanizeKey(event.eventType),
              style: theme.textTheme.headlineSmall,
            ),
          ),
        ),
        if (event.status != null)
          TestId(
            EventDetailsTestIds.status,
            child: Text(
              '${l10n.eventStatusLabel}: ${humanizeKey(event.status)}',
            ),
          ),
        const SizedBox(height: 16),
        if (option != null)
          TestId(
            EventDetailsTestIds.when,
            child: _Row(
              label: l10n.eventWhenLabel,
              value: _when(context, option),
            ),
          ),
        if (place?.name != null)
          TestId(
            EventDetailsTestIds.where,
            child: _Row(
              label: l10n.eventWhereLabel,
              value: [
                place!.name!,
                if (place.address != null) place.address!,
              ].join('\n'),
            ),
          ),
        if (mine?.statusTitle != null)
          TestId(
            EventDetailsTestIds.yourStatus,
            child: _Row(
              label: l10n.eventYourStatus,
              value: [
                mine!.statusTitle!,
                if (mine.statusSubText != null) mine.statusSubText!,
              ].join('\n'),
            ),
          ),
        if (spots != null)
          TestId(
            EventDetailsTestIds.spots,
            child: Text(l10n.eventSpotsLeft(spots)),
          ),
        if ((event.notesForEvent ?? '').isNotEmpty)
          TestId(
            EventDetailsTestIds.notes,
            child: _Row(
              label: l10n.eventNotesLabel,
              value: event.notesForEvent!,
            ),
          ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            l10n.eventParticipantsLabel,
            style: theme.textTheme.titleLarge,
          ),
        ),
        TestId(
          EventDetailsTestIds.players,
          child: players.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l10n.eventNoPlayers),
                )
              : Column(
                  children: [
                    for (final p in players)
                      TestId(
                        EventDetailsTestIds.player(p.id ?? p.userId ?? 0),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            (p.user?.displayName.isNotEmpty ?? false)
                                ? p.user!.displayName
                                : l10n.unknownPlayer,
                          ),
                          subtitle: p.participantLabel == null
                              ? null
                              : Text(p.participantLabel!),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value),
      ],
    ),
  );
}
