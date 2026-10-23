import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_manage/event_manage_test_ids.dart';
import 'package:racketmates/screens/event_manage/event_manage_view_model.dart';
import 'package:racketmates/screens/event_manage_rounds/event_manage_rounds_test_ids.dart';

/// What an organizer can change about an event (native `EventManageFragment`):
/// settings, people, date/time/venue and match scores.
class EventManageScreen extends ConsumerWidget {
  const EventManageScreen({required this.eventId, super.key});

  final int eventId;

  /// Generates the rounds, then opens them; too few confirmed players is
  /// explained instead (native `SETUP_ROUNDS_NOT_ALLOW`).
  Future<void> _setUpRounds(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final vm = ref.read(eventManageViewModelProvider(eventId).notifier);
    final outcome = await vm.generateRounds();
    if (!context.mounted) return;
    if (!outcome.ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            outcome.error.isEmpty ? l10n.eventManageFailed : outcome.error,
          ),
        ),
      );
      return;
    }
    if (outcome.result == insufficientPlayersResult) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => TestId(
          EventManageTestIds.roundsWaitingDialog,
          child: AlertDialog(
            title: Text(l10n.eventRoundsWaitingTitle),
            content: Text(l10n.eventRoundsWaitingText),
            actions: [
              TestId(
                EventManageRoundsTestIds.waitingOk,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.eventRoundsOk),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    unawaited(router.push(AppRoutes.eventManageRoundsFor(eventId)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final event = ref.watch(eventDetailsViewModelProvider(eventId)).event;

    Widget tile({
      required String id,
      required IconData icon,
      required String title,
      required String subtitle,
      String? route,
      VoidCallback? onTap,
      bool enabled = true,
    }) => TestId(
      id,
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: !enabled
            ? null
            : (onTap ?? (route == null ? null : () => context.push(route))),
      ),
    );

    Widget body(EventDetails e) {
      final locked = e.settingsLocked ?? false;
      final canSchedule =
          !locked &&
          e.status != 'es_cancelled' &&
          (e.hasSingleSchedule || canRescheduleMatches(e));
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
          if (roundsEntryFor(e) != RoundsEntry.none)
            () {
              final setUp = roundsEntryFor(e) == RoundsEntry.setUp;
              final fixed = setUp && needsFixedPartners(e);
              return tile(
                id: EventManageTestIds.rounds,
                icon: Icons.format_list_numbered,
                title: setUp
                    ? l10n.eventManageRoundsSetUp
                    : l10n.eventManageRounds,
                subtitle: fixed
                    ? l10n.eventManageRoundsFixedHint
                    : setUp
                    ? l10n.eventManageRoundsSetUpHint
                    : l10n.eventManageRoundsHint,
                // Fixed partners are paired before the rounds are generated.
                route: fixed
                    ? AppRoutes.eventManagePairsFor(eventId)
                    : setUp
                    ? null
                    : AppRoutes.eventManageRoundsFor(eventId),
                onTap: setUp && !fixed
                    ? () => _setUpRounds(context, ref)
                    : null,
              );
            }(),
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
