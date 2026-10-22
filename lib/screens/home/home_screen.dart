import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/widgets/event_tile.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/home/home_view_model.dart';

/// Home tab: pending actions, upcoming events, latest updates, activity
/// summary and recent games (native `HomeFragment`). Read-only for now; RSVP /
/// swipe actions arrive with the event-management milestone.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);
    final name = ref.watch(userProfileProvider).value?.firstName;
    return Scaffold(
      appBar: AppBar(
        title: TestId(
          HomeTestIds.greeting,
          child: Text(
            (name != null && name.isNotEmpty)
                ? l10n.homeGreeting(name)
                : l10n.homePlaceholder,
          ),
        ),
        actions: [
          // Temporary entry point until the settings milestone owns sign-out.
          TestId(
            HomeTestIds.signOutButton,
            child: IconButton(
              tooltip: l10n.signOutAction,
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  ref.read(sessionControllerProvider.notifier).signOut(),
            ),
          ),
        ],
      ),
      body: TestId(
        HomeTestIds.root,
        child: RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView(
            key: const Key(HomeTestIds.list),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _Section<List<PendingAction>>(
                id: HomeTestIds.pendingSection,
                title: l10n.homePendingActions,
                value: state.pending,
                emptyText: l10n.emptyPendingActions,
                isEmpty: (v) => v.isEmpty,
                onRetry: () => vm.reload(HomeSection.pending),
                builder: (items) => [
                  for (final a in items) _PendingTile(action: a, l10n: l10n),
                ],
              ),
              _Section<List<ScheduleItem>>(
                id: HomeTestIds.upcomingSection,
                title: l10n.homeUpcoming,
                value: state.upcoming,
                emptyText: l10n.emptyUpcoming,
                isEmpty: (v) => v.isEmpty,
                onRetry: () => vm.reload(HomeSection.upcoming),
                seeAllId: HomeTestIds.seeAllUpcoming,
                onSeeAll: () => context.go(AppRoutes.schedule),
                builder: (items) => [
                  for (final item in items)
                    if (item.eventId != null)
                      EventTile(
                        item: item,
                        testId: HomeTestIds.event('upcoming', item.eventId!),
                        onTap: () =>
                            context.push(AppRoutes.eventFor(item.eventId!)),
                      ),
                ],
              ),
              _Section<List<PlayerCard>>(
                id: HomeTestIds.updatesSection,
                title: l10n.homeLatestUpdates,
                value: state.updates,
                emptyText: l10n.emptyLatestUpdates,
                isEmpty: (v) => v.isEmpty,
                onRetry: () => vm.reload(HomeSection.updates),
                builder: (cards) => [
                  for (final c in cards)
                    _UpdateTile(
                      card: c,
                      onTap: c.eventId == null
                          ? null
                          : () => context.push(AppRoutes.eventFor(c.eventId!)),
                    ),
                ],
              ),
              _Section<List<HomePageStats>>(
                id: HomeTestIds.activitySection,
                title: l10n.homeActivity,
                value: state.activity,
                emptyText: l10n.emptyActivity,
                isEmpty: (v) => v.isEmpty,
                onRetry: () => vm.reload(HomeSection.activity),
                builder: (stats) => [
                  for (final s in stats) _ActivityCard(stats: s, l10n: l10n),
                ],
              ),
              _Section<List<ScheduleItem>>(
                id: HomeTestIds.pastSection,
                title: l10n.homePast,
                value: state.past,
                emptyText: l10n.emptyPast,
                isEmpty: (v) => v.isEmpty,
                onRetry: () => vm.reload(HomeSection.past),
                seeAllId: HomeTestIds.seeAllPast,
                onSeeAll: () => context.go(AppRoutes.schedule),
                builder: (items) => [
                  for (final item in items)
                    if (item.eventId != null)
                      EventTile(
                        item: item,
                        testId: HomeTestIds.event('past', item.eventId!),
                        onTap: () =>
                            context.push(AppRoutes.eventFor(item.eventId!)),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section<T> extends StatelessWidget {
  const _Section({
    required this.id,
    required this.title,
    required this.value,
    required this.emptyText,
    required this.isEmpty,
    required this.onRetry,
    required this.builder,
    this.seeAllId,
    this.onSeeAll,
  });

  final String id;
  final String title;
  final AsyncValue<T> value;
  final String emptyText;
  final bool Function(T) isEmpty;
  final VoidCallback onRetry;
  final List<Widget> Function(T) builder;
  final String? seeAllId;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final Widget body = value.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Row(
        children: [
          Expanded(child: Text(l10n.sectionLoadError)),
          TestId(
            HomeTestIds.retry(id),
            child: TextButton(
              onPressed: onRetry,
              child: Text(l10n.retryAction),
            ),
          ),
        ],
      ),
      data: (data) => isEmpty(data)
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(emptyText),
            )
          : Column(children: builder(data)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TestId(
        id,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                ),
                if (onSeeAll != null)
                  TestId(
                    seeAllId ?? '${id}_see_all',
                    child: TextButton(
                      onPressed: onSeeAll,
                      child: Text(l10n.seeAllAction),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.action, required this.l10n});

  final PendingAction action;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final who = action.eventParticipantUser?.displayName;
    final title = humanizeKey(action.eventType);
    return TestId(
      HomeTestIds.pendingAction(action.eventId ?? 0),
      child: Card(
        child: ListTile(
          minVerticalPadding: 12,
          title: Text(title),
          subtitle: Text(
            [
              if (who != null && who.isNotEmpty) who,
              action.eventDate ?? '',
            ].where((s) => s.isNotEmpty).join(' · '),
          ),
          onTap: action.eventId == null
              ? null
              : () => context.push(AppRoutes.eventFor(action.eventId!)),
        ),
      ),
    );
  }
}

class _UpdateTile extends StatelessWidget {
  const _UpdateTile({required this.card, this.onTap});

  final PlayerCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TestId(
      HomeTestIds.update(card.id ?? card.eventId ?? 0),
      child: Card(
        child: ListTile(
          minVerticalPadding: 12,
          title: Text(card.title ?? card.message ?? ''),
          subtitle: card.title != null && card.message != null
              ? Text(card.message!)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.stats, required this.l10n});

  final HomePageStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final entries = [
      (l10n.statEvents, stats.totalEvents),
      (l10n.statHours, stats.totalHours),
      (l10n.statWins, stats.wins),
      (l10n.statLosses, stats.losses),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (label, value) in entries)
              Column(
                children: [
                  Text(
                    '${value ?? 0}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(label),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
