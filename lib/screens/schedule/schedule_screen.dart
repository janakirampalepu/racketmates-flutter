import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/global_create_event.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/widgets/paged_schedule_list.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_drafts/event_draft_actions.dart';
import 'package:racketmates/screens/event_to_be_scheduled/to_be_scheduled_view_model.dart';
import 'package:racketmates/screens/schedule/schedule_chrome.dart';
import 'package:racketmates/screens/schedule/schedule_filter_sheet.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_view_model.dart';

/// Schedule tab (native `ScheduleFragment`/`EventScheduleListView`): a
/// List/Calendar toggle + filter row, then Drafts/To-be-rescheduled/Past
/// entry rows above the upcoming-events list — there is no Upcoming/Past
/// tab on either native app; "Past" is its own screen. Calendar view is not
/// built (placeholder shown instead).
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  ScheduleViewMode _mode = ScheduleViewMode.list;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final provider = scheduleListViewModelProvider(ScheduleTab.upcoming);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final draftsAsync = ref.watch(draftsProvider);
    final drafts = draftsAsync.value ?? const [];
    // Hide only once we know for sure there's nothing — loading or a failed
    // fetch keeps the row so the user can still reach it (and its own
    // error/retry UI), matching native (which fetches these counts once
    // and only hides a button when the server answer says zero).
    final showDrafts = !draftsAsync.hasValue || drafts.isNotEmpty;
    final toBeScheduledAsync = ref.watch(toBeScheduledProvider);
    final toBeScheduled = toBeScheduledAsync.value ?? const [];
    final showToBeScheduled =
        !toBeScheduledAsync.hasValue || toBeScheduled.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.msg(MessageKeys.scheduleTitle, l10n.scheduleTitle)),
        actions: [
          if (canOfferGlobalCreateEvent(ref))
            TestId(
              ScheduleTestIds.createEvent,
              child: IconButton(
                tooltip: l10n.addEventAction,
                icon: const Icon(Icons.add),
                onPressed: () => startGlobalCreateEvent(context, ref),
              ),
            ),
        ],
      ),
      body: TestId(
        ScheduleTestIds.root,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(sdp(16), sdp(8), sdp(16), sdp(8)),
              child: Row(
                children: [
                  Expanded(
                    child: ScheduleViewToggle(
                      mode: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                  ),
                  SizedBox(width: sdp(8)),
                  const ScheduleFilterButton(isTeamContext: false),
                ],
              ),
            ),
            Expanded(
              child: _mode == ScheduleViewMode.calendar
                  ? TestId(
                      ScheduleTestIds.calendarPlaceholder,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(sdp(24)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                size: sdp(40),
                                color: n.textSecondary,
                              ),
                              SizedBox(height: sdp(12)),
                              Text(
                                l10n.comingSoonTitle,
                                style: TextStyle(color: n.textPrimary),
                              ),
                              SizedBox(height: sdp(4)),
                              Text(
                                l10n.comingSoonMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: n.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : PagedScheduleList(
                      state: state,
                      testName: 'upcoming',
                      emptyText: ref.msg(
                        MessageKeys.scheduleNoUpcoming,
                        l10n.scheduleEmptyUpcoming,
                      ),
                      loadErrorText: l10n.scheduleLoadError,
                      onRefresh: vm.refresh,
                      onLoadMore: vm.loadMore,
                      onRetry: vm.retry,
                      header: [
                        // Native hides the Drafts/To-be-rescheduled buttons
                        // entirely when their count is zero (`displayListTypeView`:
                        // visible only when the server's label is non-null);
                        // only "Past" stays unconditional (tied to the
                        // filter's own `showPastEvents` default, not a count).
                        if (showDrafts)
                          Padding(
                            padding: EdgeInsets.only(bottom: sdp(12)),
                            child: ScheduleTopRow(
                              testId: ScheduleTestIds.topRowDrafts,
                              icon: Icons.drafts_outlined,
                              label: l10n.scheduleDraftsRow(drafts.length),
                              iconColor: n.textSecondary,
                              textColor: n.textPrimary,
                              backgroundColor: n.statusColorsDarkGray,
                              borderColor: n.statusColorsDarkGray,
                              onTap: () => context.push(AppRoutes.drafts),
                            ),
                          ),
                        if (showToBeScheduled)
                          Padding(
                            padding: EdgeInsets.only(bottom: sdp(12)),
                            child: ScheduleTopRow(
                              testId: ScheduleTestIds.topRowToBeScheduled,
                              icon: Icons.event_repeat_outlined,
                              label: l10n.scheduleToBeScheduledRow(
                                toBeScheduled.length,
                              ),
                              iconColor: n.statusColorsLightOrange,
                              // Light orange on dark orange fails the app's
                              // own enforced 4.5:1 text-contrast test; kept
                              // the icon tint but moved the label text to
                              // `textPrimary`, same fix as the Home activity
                              // tiles hit for the same reason.
                              textColor: n.textPrimary,
                              backgroundColor: n.statusColorsDarkOrange,
                              borderColor: n.statusColorsDarkOrange,
                              onTap: () =>
                                  context.push(AppRoutes.toBeScheduled),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.only(bottom: sdp(12)),
                          child: ScheduleTopRow(
                            testId: ScheduleTestIds.topRowPast,
                            icon: Icons.history_outlined,
                            label: l10n.schedulePastEventsRow,
                            iconColor: n.imagePrimeryColor,
                            textColor: n.textPrimary,
                            backgroundColor: Colors.transparent,
                            borderColor: n.borderSolidPrimary,
                            onTap: () => context.push(AppRoutes.pastEvents),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
