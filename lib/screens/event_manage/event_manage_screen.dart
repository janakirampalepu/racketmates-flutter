import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_manage/event_manage_test_ids.dart';

/// What an organizer can change about an event (native `EventManageFragment`):
/// settings, people, date/time/venue and match scores.
class EventManageScreen extends ConsumerWidget {
  const EventManageScreen({required this.eventId, super.key});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final event = ref.watch(eventDetailsViewModelProvider(eventId)).event;

    Widget tile({
      required String id,
      required IconData icon,
      required String title,
      required String subtitle,
      required String route,
      bool enabled = true,
    }) => TestId(
      id,
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? () => context.push(route) : null,
      ),
    );

    Widget body(EventDetails e) {
      final locked = e.settingsLocked ?? false;
      final canSchedule =
          !locked && e.status != 'es_cancelled' && e.hasSingleSchedule;
      final canScore =
          (e.eventMatches?.isNotEmpty ?? false) &&
          ((e.permission('event.update_scores')?.enabled ?? false) ||
              (e.permission('event.manage_scores')?.enabled ?? false));
      return ListView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
        children: [
          tile(
            id: EventManageTestIds.settings,
            icon: Icons.tune,
            title: l10n.eventManageSettings,
            subtitle: locked
                ? l10n.eventManageLocked
                : l10n.eventManageSettingsHint,
            route: AppRoutes.eventManageSettingsFor(eventId),
          ),
          tile(
            id: EventManageTestIds.players,
            icon: Icons.group_outlined,
            title: l10n.eventManagePlayers,
            subtitle: l10n.eventManagePlayersHint,
            route: AppRoutes.eventManagePlayersFor(eventId),
          ),
          tile(
            id: EventManageTestIds.schedule,
            icon: Icons.event_outlined,
            title: l10n.eventManageSchedule,
            subtitle: canSchedule
                ? l10n.eventManageScheduleHint
                : locked
                ? l10n.eventManageLocked
                : l10n.eventManageScheduleUnsupported,
            route: AppRoutes.eventManageScheduleFor(eventId),
            enabled: canSchedule,
          ),
          if (canScore)
            tile(
              id: EventManageTestIds.scores,
              icon: Icons.scoreboard_outlined,
              title: l10n.eventManageScores,
              subtitle: l10n.eventManageScoresHint,
              route: AppRoutes.eventManageScoresFor(eventId),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          EventManageTestIds.title,
          child: Semantics(header: true, child: Text(l10n.eventManageTitle)),
        ),
      ),
      body: TestId(
        EventManageTestIds.root,
        child: event.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.eventLoadError)),
          data: body,
        ),
      ),
    );
  }
}
