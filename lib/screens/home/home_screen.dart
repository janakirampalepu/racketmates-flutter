import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
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
    final n = context.native;
    final sdp = context.sdp;
    return Scaffold(
      backgroundColor: n.backgroundSolidPrimary,
      appBar: AppBar(
        backgroundColor: n.backgroundSolidPrimary,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(sdp(1)),
          child: Container(height: sdp(1), color: n.ndotsColor),
        ),
        title: TestId(
          HomeTestIds.greeting,
          child: Text(
            (name != null && name.isNotEmpty)
                ? l10n.homeGreeting(name)
                : l10n.homePlaceholder,
            style: NativeText.semibold(sdp(18), n.textPrimary),
          ),
        ),
        actions: [
          TestId(
            HomeTestIds.settingsButton,
            child: IconButton(
              tooltip: l10n.homeSettingsAction,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoutes.settings),
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
            padding: EdgeInsets.symmetric(vertical: sdp(8)),
            children: [
              _Section<List<PendingAction>>(
                id: HomeTestIds.pendingSection,
                title: ref.msg(
                  MessageKeys.homePendingTitle,
                  l10n.homePendingActions,
                ),
                value: state.pending,
                emptyText: ref.msg(
                  MessageKeys.homePendingEmpty,
                  l10n.emptyPendingActions,
                ),
                isEmpty: (v) => v.isEmpty,
                emptyIcon: 'ic_pending_actions',
                onRetry: () => vm.reload(HomeSection.pending),
                builder: (items) => [
                  for (final a in items) _PendingTile(action: a, l10n: l10n),
                ],
              ),
              _Section<List<ScheduleItem>>(
                id: HomeTestIds.upcomingSection,
                title: ref.msg(
                  MessageKeys.homeUpcomingTitle,
                  l10n.homeUpcoming,
                ),
                value: state.upcoming,
                emptyText: ref.msg(
                  MessageKeys.homeUpcomingEmpty,
                  l10n.emptyUpcoming,
                ),
                isEmpty: (v) => v.isEmpty,
                emptyIcon: 'ic_events',
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
                title: ref.msg(
                  MessageKeys.homeUpdatesTitle,
                  l10n.homeLatestUpdates,
                ),
                value: state.updates,
                emptyText: ref.msg(
                  MessageKeys.homeUpdatesEmpty,
                  l10n.emptyLatestUpdates,
                ),
                isEmpty: (v) => v.isEmpty,
                emptyIcon: 'ic_no_last_updates',
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
                title: ref.msg(
                  MessageKeys.homeActivityTitle,
                  l10n.homeActivity,
                ),
                value: state.activity,
                emptyText: ref.msg(
                  MessageKeys.homeActivityEmpty,
                  l10n.emptyActivity,
                ),
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
    this.emptyIcon,
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

  /// The picture of the empty state (native `ic_events` and friends).
  final String? emptyIcon;
  final String? seeAllId;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final Widget body = value.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Row(
        children: [
          Expanded(
            child: Text(
              l10n.sectionLoadError,
              style: NativeText.regular(sdp(12), n.textSecondary),
            ),
          ),
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
              padding: EdgeInsets.symmetric(vertical: sdp(8)),
              child: Row(
                children: [
                  if (emptyIcon != null) ...[
                    SvgIcon(emptyIcon!, size: sdp(62)),
                    SizedBox(width: sdp(12)),
                  ],
                  Expanded(
                    child: Text(
                      emptyText,
                      style: NativeText.medium(sdp(14), n.textPrimary),
                    ),
                  ),
                ],
              ),
            )
          : Column(children: builder(data)),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: sdp(8)),
      child: TestId(
        id,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(sdp(18), sdp(8), sdp(16), sdp(8)),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: NativeText.medium(sdp(16), n.textPrimary),
                      ),
                    ),
                  ),
                  if (onSeeAll != null)
                    TestId(
                      seeAllId ?? '${id}_see_all',
                      child: InkWell(
                        onTap: onSeeAll,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            minWidth: 48,
                          ),
                          child: Center(
                            child: Text(
                              l10n.seeAllAction,
                              style: NativeText.regular(sdp(14), n.textGreen),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sdp(16)),
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}

/// A card of the home lists (native item layouts): the window colour, a
/// 1 sdp outline and 12 sdp corners.
class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return Padding(
      padding: EdgeInsets.only(bottom: sdp(12)),
      child: Material(
        color: n.windowBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sdp(12)),
          side: BorderSide(color: n.borderSolidPrimary, width: sdp(1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: SizedBox(
              width: double.infinity,
              child: Padding(padding: EdgeInsets.all(sdp(12)), child: child),
            ),
          ),
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
    final n = context.native;
    final sdp = context.sdp;
    final who = action.eventParticipantUser?.displayName;
    final title = humanizeKey(action.eventType);
    final subtitle = [
      if (who != null && who.isNotEmpty) who,
      action.eventDate ?? '',
    ].where((s) => s.isNotEmpty).join(' · ');
    return TestId(
      HomeTestIds.pendingAction(action.eventId ?? 0),
      child: _HomeCard(
        onTap: action.eventId == null
            ? null
            : () => context.push(AppRoutes.eventFor(action.eventId!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: NativeText.semibold(sdp(14), n.textPrimary)),
            if (subtitle.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: sdp(4)),
                child: Text(
                  subtitle,
                  style: NativeText.regular(sdp(12), n.textSecondary),
                ),
              ),
          ],
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
    final n = context.native;
    final sdp = context.sdp;
    return TestId(
      HomeTestIds.update(card.id ?? card.eventId ?? 0),
      child: _HomeCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title ?? card.message ?? '',
              style: NativeText.semibold(sdp(14), n.textPrimary),
            ),
            if (card.title != null && card.message != null)
              Padding(
                padding: EdgeInsets.only(top: sdp(4)),
                child: Text(
                  card.message!,
                  style: NativeText.regular(sdp(12), n.textSecondary),
                ),
              ),
          ],
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
    final n = context.native;
    final sdp = context.sdp;
    final entries = [
      (l10n.statEvents, stats.totalEvents),
      (l10n.statHours, stats.totalHours),
      (l10n.statWins, stats.wins),
      (l10n.statLosses, stats.losses),
    ];
    return _HomeCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final (label, value) in entries)
            Column(
              children: [
                Text(
                  '${value ?? 0}',
                  style: NativeText.semibold(sdp(20), n.textPrimary),
                ),
                Text(
                  label,
                  style: NativeText.regular(sdp(12), n.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
