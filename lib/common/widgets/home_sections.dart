import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/widgets/event_tile.dart';
import 'package:racketmates/common/widgets/home_activity_card.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// The Upcoming-events/Pending-actions/Activity sections shared by Home and
/// Team Home (native `HomeFragment`/`TeamHomeFragment` both render these
/// from the same `HomeFragmentViewModel`, parameterized by an optional
/// team). Each screen supplies its own test ids and "create event"/"see
/// all" behavior, since those differ (Team Home's create-event flow checks
/// team access and an archived team; Home's does not).

/// A section header (native layouts' `txtUpcomingEvent`/`txtPendingActions`/
/// `txtActivity` rows): title left, optional "See all" link right.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    this.seeAllId,
    this.onSeeAll,
    super.key,
  });

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
              seeAllId!,
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
  required String retryId,
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
            retryId,
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
/// `upcomingEventsPager`, no page indicator). The empty state offers to
/// create an event when [canOfferCreate] allows it (native
/// `btnCreateEvent`); [onCreateEvent] runs the create flow (personal or
/// team-scoped, decided by the caller).
class UpcomingEventsSection extends StatelessWidget {
  const UpcomingEventsSection({
    required this.l10n,
    required this.value,
    required this.onRetry,
    required this.sectionId,
    required this.seeAllId,
    required this.retryId,
    required this.createEventId,
    required this.eventIdFor,
    required this.onSeeAll,
    required this.canOfferCreate,
    required this.onCreateEvent,
    super.key,
  });

  final AppLocalizations l10n;
  final AsyncValue<List<ScheduleItem>> value;
  final VoidCallback onRetry;
  final String sectionId;
  final String seeAllId;
  final String retryId;
  final String createEventId;

  /// Test id for one event tile, by event id.
  final String Function(int eventId) eventIdFor;
  final VoidCallback onSeeAll;
  final bool canOfferCreate;
  final Future<void> Function(BuildContext, WidgetRef) onCreateEvent;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final sdp = context.sdp;
        return TestId(
          sectionId,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeSectionHeader(
                title: ref.msg(MessageKeys.homeUpcomingTitle, l10n.homeUpcoming),
                seeAllId: seeAllId,
                onSeeAll: onSeeAll,
              ),
              _sectionBody<List<ScheduleItem>>(
                context: context,
                retryId: retryId,
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
                              createEventId,
                              child: FilledButton(
                                onPressed: () => onCreateEvent(context, ref),
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
                          testId: eventIdFor(events[i].eventId!),
                          onTap: () => context.push(
                            AppRoutes.eventFor(events[i].eventId!),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pending actions: a plain vertical list (native `rvPendingActions`, a
/// `LinearLayoutManager` column, not a horizontal row), shown in full (the
/// backend is not asked for a page size here).
class PendingActionsSection extends StatelessWidget {
  const PendingActionsSection({
    required this.l10n,
    required this.value,
    required this.onRetry,
    required this.sectionId,
    required this.retryId,
    required this.actionIdFor,
    super.key,
  });

  final AppLocalizations l10n;
  final AsyncValue<List<PendingAction>> value;
  final VoidCallback onRetry;
  final String sectionId;
  final String retryId;

  /// Test id for one pending-action tile, by event id (0 when absent).
  final String Function(int eventId) actionIdFor;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final sdp = context.sdp;
        return TestId(
          sectionId,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeSectionHeader(
                title: ref.msg(
                  MessageKeys.homePendingTitle,
                  l10n.homePendingActions,
                ),
              ),
              _sectionBody<List<PendingAction>>(
                context: context,
                retryId: retryId,
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
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: sdp(12)),
                        child: Column(
                          children: [
                            for (final action in items)
                              _PendingTile(
                                action: action,
                                testId: actionIdFor(action.eventId ?? 0),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.action, required this.testId});

  final PendingAction action;
  final String testId;

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
      testId,
      child: Padding(
        padding: EdgeInsets.only(bottom: sdp(8)),
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
class HomeActivitySection extends StatelessWidget {
  const HomeActivitySection({
    required this.l10n,
    required this.value,
    required this.onRetry,
    required this.sectionId,
    required this.retryId,
    required this.yearBadgeId,
    super.key,
  });

  final AppLocalizations l10n;
  final AsyncValue<List<HomePageStats>> value;
  final VoidCallback onRetry;
  final String sectionId;
  final String retryId;
  final String yearBadgeId;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => TestId(
        sectionId,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionHeader(
              title: ref.msg(MessageKeys.homeActivityTitle, l10n.homeActivity),
            ),
            _sectionBody<List<HomePageStats>>(
              context: context,
              retryId: retryId,
              l10n: l10n,
              value: value,
              onRetry: onRetry,
              data: (years) => years.isEmpty
                  ? const SizedBox.shrink()
                  : HomeActivityCard(years: years, yearBadgeId: yearBadgeId),
            ),
          ],
        ),
      ),
    );
  }
}
