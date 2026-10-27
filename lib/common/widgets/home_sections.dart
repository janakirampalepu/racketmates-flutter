import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
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
    this.trailing,
    super.key,
  });

  final String title;
  final String? seeAllId;
  final VoidCallback? onSeeAll;

  /// An extra widget at the row's end, before "See all" (native's Activity
  /// section puts its year badge directly in this header row, not inside
  /// the per-year pager).
  final Widget? trailing;

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
                style: NativeText.semibold(sdp(16), n.textPrimary),
              ),
            ),
          ),
          ?trailing,
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

/// Debug-only detail for a section's error state: always something, even
/// for failure types whose `message` is null by design (`OfflineFailure`/
/// `TimeoutFailure`) or whose body didn't match `extractServerMessage`'s
/// expected keys — a failure with no message would otherwise look
/// identical to one that was never caught at all.
String? _debugDetail(Object? error) {
  if (error is ServerFailure) {
    final message = error.message;
    return 'HTTP ${error.statusCode}${message != null && message.isNotEmpty ? ': $message' : ''}';
  }
  if (error is AppFailure) {
    final message = error.message;
    return '${error.runtimeType}${message != null && message.isNotEmpty ? ': $message' : ''}';
  }
  return error?.toString();
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
  error: (error, _) {
    final n = context.native;
    final sdp = context.sdp;
    // A `ParseFailure`/`UnknownFailure`'s message is a raw Dart exception —
    // useful for diagnosing a response-shape mismatch, too technical to
    // show a user in production. Server-provided messages (`ServerFailure`
    // etc.) are already meant to be user-facing.
    final isTechnical = error is ParseFailure || error is UnknownFailure;
    final serverMessage = (error is AppFailure && !isTechnical)
        ? error.message
        : null;
    final text = (serverMessage != null && serverMessage.isNotEmpty)
        ? serverMessage
        : l10n.sectionLoadError;
    // Every failure type gets a debug line, even ones whose `message` is
    // always null by design (`OfflineFailure`/`TimeoutFailure`) or whose
    // body didn't match `extractServerMessage`'s expected keys — otherwise
    // a failure with no message looks identical to one that was never
    // caught at all, which is indistinguishable from the screen's own
    // "nothing extra showed up" report.
    final debugDetail = kDebugMode ? _debugDetail(error) : null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sdp(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text,
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
          if (debugDetail != null && debugDetail.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: sdp(4)),
              child: Text(
                debugDetail,
                style: NativeText.regular(sdp(10), n.textSecondary),
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
                title: ref.msg(
                  MessageKeys.homeUpcomingTitle,
                  l10n.homeUpcoming,
                ),
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
                    // Centered icon-over-text (native's `EmptyStateCard`:
                    // `HStack { Spacer(); VStack {...}; Spacer() }`), not
                    // left-aligned like the rest of the section.
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: sdp(16)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgIcon(
                              'ic_events',
                              size: 62,
                              color: context.native.imagePrimeryColor,
                            ),
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
                      ),
                    );
                  }
                  return SizedBox(
                    // Taller than before: EventTile now has a third
                    // (court/coach/notes + avatars) row and an action
                    // button row, matching native's richer card.
                    height: sdp(248),
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

/// Pending actions: a horizontally-scrolling row of rich cards (native iOS
/// `pendingActionSectionContent`/`PendingActionCard` — a date badge, the
/// event-type title, a decorative sport-icon watermark and a primary action
/// button driven by the server's `primary_swipe_action`; Android's
/// `rvPendingActions` is a plain vertical list, but the iOS design is the
/// one the product screenshots confirm as current).
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
                    // Centered icon-over-text, matching native's shared
                    // `EmptyStateCard` (same layout the Upcoming section's
                    // empty state uses), not the Row this used to be.
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: sdp(16)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgIcon(
                                'ic_pending_actions',
                                size: 62,
                                color: context.native.imagePrimeryColor,
                              ),
                              SizedBox(height: sdp(8)),
                              Text(
                                ref.msg(
                                  MessageKeys.homePendingEmpty,
                                  l10n.emptyPendingActions,
                                ),
                                textAlign: TextAlign.center,
                                style: NativeText.medium(
                                  sdp(14),
                                  context.native.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(
                        height: sdp(168),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: sdp(16)),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => SizedBox(width: sdp(12)),
                          itemBuilder: (context, i) => _PendingTile(
                            action: items[i],
                            testId: actionIdFor(items[i].eventId ?? 0),
                          ),
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

/// One pending-action card (native iOS `PendingActionCard`): a date badge,
/// the event-type title, a faint sport-icon watermark top-trailing, and a
/// primary action button chosen from `primarySwipeAction`. Buttons open the
/// event itself (same as tapping the card) rather than acting in place,
/// since the accept/decline/scores flows already live on the event screen.
class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.action, required this.testId});

  static const double _width = 190;

  final PendingAction action;
  final String testId;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateTime.tryParse(action.eventDate ?? '');
    final day = date == null ? '' : DateFormat('dd', locale).format(date);
    final month = date == null
        ? ''
        : DateFormat('MMM', locale).format(date).toUpperCase();
    final title = humanizeKey(action.eventType);
    final sport = SportKey.fromKey(action.sportType);
    final sportIcon = sport == null ? null : sportIconName(sport);
    final onTap = action.eventId == null
        ? null
        : () => context.push(AppRoutes.eventFor(action.eventId!));
    return TestId(
      testId,
      child: Material(
        color: n.windowBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sdp(12)),
          side: BorderSide(color: n.borderSolidPrimary, width: sdp(1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: sdp(_width),
            child: Stack(
              children: [
                if (sportIcon != null)
                  Positioned(
                    top: -sdp(8),
                    right: -sdp(8),
                    child: SvgIcon(
                      sportIcon,
                      size: sdp(64),
                      // Native's own background art is a dedicated,
                      // single-color "pending action" ball icon tinted
                      // `icon_primary` at 15% alpha (`ic_*_sport_background`,
                      // `AppUtils.setSportTypeBallIcon`); this reuses the
                      // existing multi-color sport-chip icon tinted the same
                      // way, rather than porting 4 more complex vector
                      // patterns for a decorative watermark.
                      color: n.imagePrimeryColor.withValues(alpha: 0.15),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(sdp(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateBadge(day: day, month: month),
                      SizedBox(height: sdp(12)),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: NativeText.semibold(sdp(14), n.textPrimary),
                      ),
                      const Spacer(),
                      _PendingActionButton(
                        primarySwipeAction: action.primarySwipeAction,
                        l10n: l10n,
                        onTap: onTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Native iOS `PendingActionCard.dateBoxView`: the month strip and the day
/// area are two different fixed colors (not the per-participant-status
/// colors `EventTile`'s date badge uses, since a pending action has no
/// `participantStatus`) — month = `Border.Solid.primary`, day = (the whole
/// box's own background, showing through under the month strip) =
/// `StatusColors.darkGray`.
class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.day, required this.month});

  final String day;
  final String month;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return Container(
      // Fixed width (matches EventTile's own date badge): the month strip
      // below uses `width: double.infinity` to fill it edge-to-edge, which
      // without this expands to the full card width instead of just the
      // badge's own — exactly the "calendar fills the whole card" bug.
      width: sdp(40),
      decoration: BoxDecoration(
        color: n.statusColorsDarkGray,
        borderRadius: BorderRadius.circular(sdp(4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: sdp(2)),
            decoration: BoxDecoration(
              color: n.borderSolidPrimary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(sdp(4))),
            ),
            child: Text(
              month,
              textAlign: TextAlign.center,
              style: NativeText.medium(sdp(10), n.textPrimary),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sdp(8), vertical: sdp(2)),
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: NativeText.medium(sdp(14), n.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Native iOS `EventViewAction` raw values handled by `PendingActionCard`'s
/// `actionButtonsView`; anything else (or `null`) shows no button, matching
/// native's `default: Color.clear` case.
const _submitScoresAction = 'user_action_submit_scores';
const _confirmScoresAction = 'user_action_confirm_scores';
const _acceptAction = 'event_view_action_accept';
const _joinWaitlistAction = 'event_view_action_join_waitlist';

class _PendingActionButton extends StatelessWidget {
  const _PendingActionButton({
    required this.primarySwipeAction,
    required this.l10n,
    required this.onTap,
  });

  final String? primarySwipeAction;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sdp = context.sdp;
    return SizedBox(
      height: sdp(36),
      width: double.infinity,
      child: switch (primarySwipeAction) {
        _submitScoresAction => FilledButton.tonalIcon(
          onPressed: onTap,
          icon: const Icon(Icons.scoreboard_outlined, size: 16),
          label: Text(
            l10n.eventSubmitScores,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _confirmScoresAction => FilledButton.tonalIcon(
          onPressed: onTap,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: Text(
            l10n.eventConfirmScores,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _joinWaitlistAction => FilledButton.tonalIcon(
          onPressed: onTap,
          icon: const Icon(Icons.hourglass_bottom, size: 16),
          label: Text(
            l10n.rsvpJoinWaitlist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _acceptAction => Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onTap,
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                child: Text(
                  l10n.rsvpDecline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: onTap,
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                child: Text(
                  l10n.rsvpAccept,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        // Native (both platforms) shows no button at all for an
        // unrecognized/absent `primarySwipeAction`. Deliberate deviation:
        // show a generic fallback instead, so a card is never left without
        // any visible action — the whole-card tap target is easy to miss,
        // and this is the same destination either way.
        _ => OutlinedButton(
          onPressed: onTap,
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
          ),
          child: Text(
            l10n.homePendingViewDetails,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      },
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
      builder: (context, ref, _) {
        // Native puts the year badge in the section header itself, showing
        // the first year's value (`stats.first?.year`) — not per-page, and
        // not shown at all while loading/empty/errored.
        final firstYear = value.value?.firstOrNull?.year;
        return TestId(
          sectionId,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeSectionHeader(
                title: ref.msg(
                  MessageKeys.homeActivityTitle,
                  l10n.homeActivity,
                ),
                trailing: firstYear == null
                    ? null
                    : _YearBadge(year: firstYear, testId: yearBadgeId),
              ),
              _sectionBody<List<HomePageStats>>(
                context: context,
                retryId: retryId,
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
      },
    );
  }
}

/// Native `activityCardsSection`: a tinted, bordered badge next to the
/// section title — `stats.first?.year`, background `Background.Solid
/// .Green.green4`, border `Main.primary`, `cornerRadius: 4` (not a pill).
class _YearBadge extends StatelessWidget {
  const _YearBadge({required this.year, required this.testId});

  final int year;
  final String testId;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return TestId(
      testId,
      child: Container(
        margin: EdgeInsets.only(left: sdp(8)),
        padding: EdgeInsets.symmetric(horizontal: sdp(10), vertical: sdp(4)),
        decoration: BoxDecoration(
          color: n.backgroundSolidGreen4,
          borderRadius: BorderRadius.circular(sdp(4)),
          border: Border.all(color: n.colorPrimary, width: sdp(1)),
        ),
        child: Text('$year', style: NativeText.regular(sdp(12), n.textPrimary)),
      ),
    );
  }
}
