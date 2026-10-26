import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/widgets/event_tile.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/home/family_user_picker.dart';
import 'package:racketmates/screens/home/home_activity_card.dart';
import 'package:racketmates/screens/home/home_downtime_banner.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/home/home_view_model.dart';

/// Home tab: a maintenance notice, the family picker, upcoming events,
/// pending actions and activity (native `HomeFragment`/iOS `GlobalHomeView`).
/// "Latest updates" and "recent games" are left out: neither native app
/// currently fetches or shows them. RSVP/swipe actions on the cards arrive
/// with the event-management milestone.
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
            padding: EdgeInsets.symmetric(vertical: sdp(4)),
            children: [
              const HomeDowntimeBanner(),
              const FamilyAvatarsRow(),
              _UpcomingSection(
                l10n: l10n,
                value: state.upcoming,
                onRetry: () => vm.reload(HomeSection.upcoming),
              ),
              _PendingSection(
                l10n: l10n,
                value: state.pending,
                onRetry: () => vm.reload(HomeSection.pending),
              ),
              _ActivitySection(
                l10n: l10n,
                value: state.activity,
                onRetry: () => vm.reload(HomeSection.activity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section header (native layouts' `txtUpcomingEvent`/`txtPendingActions`/
/// `txtActivity` rows): title left, optional "See all" link right.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.id,
    required this.title,
    this.seeAllId,
    this.onSeeAll,
  });

  final String id;
  final String title;
  final String? seeAllId;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    return Padding(
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
    );
  }
}

/// Section loading/error chrome shared by the three sections (native
/// `carosel_shimmer`: one small and one large placeholder card).
Widget _sectionBody<T>({
  required BuildContext context,
  required String sectionId,
  required AppLocalizations l10n,
  required AsyncValue<T> value,
  required VoidCallback onRetry,
  required Widget Function(T data) data,
}) => value.when(
  loading: () => const _ShimmerPlaceholder(),
  error: (_, _) {
    final n = context.native;
    final sdp = context.sdp;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sdp(16)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.sectionLoadError,
              style: NativeText.regular(sdp(12), n.textSecondary),
            ),
          ),
          TestId(
            HomeTestIds.retry(sectionId),
            child: TextButton(
              onPressed: onRetry,
              child: Text(l10n.retryAction),
            ),
          ),
        ],
      ),
    );
  },
  data: data,
);

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    Widget bar(double height) => Container(
      margin: EdgeInsets.symmetric(horizontal: sdp(12), vertical: sdp(4)),
      height: sdp(height),
      decoration: BoxDecoration(
        color: n.borderSolidPrimary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(sdp(8)),
      ),
    );
    return Column(children: [bar(16), bar(140)]);
  }
}

/// Upcoming events: a swipeable carousel, at most 3 events (native
/// `upcomingEventsPager`, no page indicator). "See all" switches to the
/// Schedule tab; the empty state offers to create an event when the
/// `events.create` permission allows it (native `btnCreateEvent`).
class _UpcomingSection extends ConsumerWidget {
  const _UpcomingSection({
    required this.l10n,
    required this.value,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final AsyncValue<List<ScheduleItem>> value;
  final VoidCallback onRetry;

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionInfoControllerProvider);
    final access = session.user?.permission('events.create');
    switch (decideAccess(access, subscribed: session.isSubscribed)) {
      case AccessDecision.allowed || AccessDecision.hidden:
        ref.read(createEventFlowProvider.notifier).start();
        if (context.mounted) unawaited(context.push(AppRoutes.createEvent));
      case AccessDecision.needsSubscription || AccessDecision.blocked:
        final needsSubscription =
            decideAccess(access, subscribed: session.isSubscribed) ==
            AccessDecision.needsSubscription;
        final text = (access?.message ?? '').isNotEmpty
            ? access!.message!
            : (needsSubscription
                  ? l10n.accessNeedsSubscription
                  : l10n.accessBlocked);
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            content: Text(text),
            actions: [
              if (needsSubscription && ref.read(billingSupportedProvider))
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.push(AppRoutes.subscription);
                  },
                  child: Text(l10n.accessUpgradeAction),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.closeAction),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdp = context.sdp;
    final session = ref.watch(sessionInfoControllerProvider);
    final canOfferCreate =
        decideAccess(
          session.user?.permission('events.create'),
          subscribed: session.isSubscribed,
        ) !=
        AccessDecision.hidden;
    return TestId(
      HomeTestIds.upcomingSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            id: HomeTestIds.upcomingSection,
            title: ref.msg(MessageKeys.homeUpcomingTitle, l10n.homeUpcoming),
            seeAllId: HomeTestIds.seeAllUpcoming,
            onSeeAll: () => context.go(AppRoutes.schedule),
          ),
          _sectionBody<List<ScheduleItem>>(
            context: context,
            sectionId: HomeTestIds.upcomingSection,
            l10n: l10n,
            value: value,
            onRetry: onRetry,
            data: (items) {
              final events = [
                for (final item in items)
                  if (item.eventId != null) item,
              ];
              if (events.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: sdp(16)),
                  child: Column(
                    children: [
                      const SvgIcon('ic_events', size: 62),
                      SizedBox(height: sdp(8)),
                      Text(
                        ref.msg(
                          MessageKeys.homeUpcomingEmpty,
                          l10n.emptyUpcoming,
                        ),
                        textAlign: TextAlign.center,
                        style: NativeText.medium(
                          sdp(14),
                          context.native.textPrimary,
                        ),
                      ),
                      if (canOfferCreate) ...[
                        SizedBox(height: sdp(8)),
                        TestId(
                          HomeTestIds.createEvent,
                          child: FilledButton(
                            onPressed: () => _create(context, ref),
                            child: Text(l10n.addEventAction),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return SizedBox(
                height: sdp(176),
                child: PageView.builder(
                  itemCount: events.length,
                  padEnds: false,
                  controller: PageController(viewportFraction: 0.94),
                  itemBuilder: (context, i) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: sdp(4)),
                    child: EventTile(
                      item: events[i],
                      testId: HomeTestIds.event('upcoming', events[i].eventId!),
                      onTap: () =>
                          context.push(AppRoutes.eventFor(events[i].eventId!)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Pending actions: a plain horizontal scroll (native `rvPendingActions`, a
/// `LinearLayoutManager` row - no snap paging), shown in full (the backend is
/// not asked for a page size here).
class _PendingSection extends ConsumerWidget {
  const _PendingSection({
    required this.l10n,
    required this.value,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final AsyncValue<List<PendingAction>> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdp = context.sdp;
    return TestId(
      HomeTestIds.pendingSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            id: HomeTestIds.pendingSection,
            title: ref.msg(
              MessageKeys.homePendingTitle,
              l10n.homePendingActions,
            ),
          ),
          _sectionBody<List<PendingAction>>(
            context: context,
            sectionId: HomeTestIds.pendingSection,
            l10n: l10n,
            value: value,
            onRetry: onRetry,
            data: (items) => items.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: sdp(16)),
                    child: Row(
                      children: [
                        const SvgIcon('ic_pending_actions', size: 62),
                        SizedBox(width: sdp(12)),
                        Expanded(
                          child: Text(
                            ref.msg(
                              MessageKeys.homePendingEmpty,
                              l10n.emptyPendingActions,
                            ),
                            style: NativeText.medium(
                              sdp(14),
                              context.native.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: sdp(84),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: sdp(12)),
                      itemCount: items.length,
                      itemBuilder: (context, i) => SizedBox(
                        width: sdp(260),
                        child: _PendingTile(action: items[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.action});

  final PendingAction action;

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
      child: Padding(
        padding: EdgeInsets.only(right: sdp(8)),
        child: Material(
          color: n.windowBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sdp(12)),
            side: BorderSide(color: n.borderSolidPrimary, width: sdp(1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: action.eventId == null
                ? null
                : () => context.push(AppRoutes.eventFor(action.eventId!)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: EdgeInsets.all(sdp(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NativeText.semibold(sdp(14), n.textPrimary),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: sdp(4)),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NativeText.regular(sdp(12), n.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Activity: one page per year with a dot indicator, only when there is more
/// than one year (native `fragment_home_activity_stats` + `TabLayoutMediator`).
class _ActivitySection extends ConsumerWidget {
  const _ActivitySection({
    required this.l10n,
    required this.value,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final AsyncValue<List<HomePageStats>> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TestId(
      HomeTestIds.activitySection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            id: HomeTestIds.activitySection,
            title: ref.msg(MessageKeys.homeActivityTitle, l10n.homeActivity),
          ),
          _sectionBody<List<HomePageStats>>(
            context: context,
            sectionId: HomeTestIds.activitySection,
            l10n: l10n,
            value: value,
            onRetry: onRetry,
            data: (years) => years.isEmpty
                ? const SizedBox.shrink()
                : HomeActivityCard(years: years),
          ),
        ],
      ),
    );
  }
}
