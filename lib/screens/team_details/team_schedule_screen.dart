import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_edit.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/widgets/load_error_body.dart';
import 'package:racketmates/common/widgets/paged_schedule_list.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/schedule/schedule_chrome.dart';
import 'package:racketmates/screens/schedule/schedule_filter_sheet.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';
import 'package:racketmates/screens/team_details/team_access.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/team_details/team_schedule_view_model.dart';

/// The team's schedule (native `TeamScheduleFragment extends ScheduleFragment`
/// / iOS's `EventScheduleListView(teamId:)`) — confirmed from source to be
/// the *exact same screen* as the global Schedule tab, parameterized by a
/// team id: same List/Calendar toggle, same filter row, same "Past events"
/// entry (no Upcoming/Past split, on either platform). Reached from Team
/// Home's "See all" on the Upcoming-events section. Drafts/To-be-rescheduled
/// rows are not shown here yet — neither is team-scoped in this app
/// (`DraftsRepository`/`toBeScheduledProvider` are global-only), a known gap.
class TeamScheduleScreen extends ConsumerStatefulWidget {
  const TeamScheduleScreen({required this.teamId, super.key});

  final int teamId;

  @override
  ConsumerState<TeamScheduleScreen> createState() => _TeamScheduleScreenState();
}

class _TeamScheduleScreenState extends ConsumerState<TeamScheduleScreen> {
  ScheduleViewMode _mode = ScheduleViewMode.list;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final team = ref.watch(teamDetailsProvider(widget.teamId));

    return Scaffold(
      backgroundColor: n.backgroundSolidPrimary,
      appBar: AppBar(
        backgroundColor: n.backgroundSolidPrimary,
        title: Text(l10n.teamTabSchedule),
        actions: [
          team.whenOrNull(
                data: (t) =>
                    memberAccess(
                          t,
                          TeamSettingsPermissions.createEvent,
                          subscribed: true,
                        ) ==
                        AccessDecision.hidden
                    ? null
                    : TestId(
                        TeamDetailsTestIds.scheduleCreateEvent,
                        child: IconButton(
                          tooltip: l10n.teamCreateEvent,
                          icon: const Icon(Icons.add),
                          onPressed: () =>
                              startTeamCreateEvent(context, ref, t),
                        ),
                      ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: team.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: LoadErrorBody(
            error: error,
            fallbackText: l10n.teamDetailsLoadError,
            retryId: TeamDetailsTestIds.retry,
            onRetry: () => ref.invalidate(teamDetailsProvider(widget.teamId)),
            errorTestId: TeamDetailsTestIds.error,
          ),
        ),
        data: (t) {
          final provider = teamScheduleViewModelProvider((
            teamId: widget.teamId,
            tab: ScheduleTab.upcoming,
          ));
          final state = ref.watch(provider);
          final vm = ref.read(provider.notifier);
          return Column(
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
                    const ScheduleFilterButton(
                      isTeamContext: true,
                      testId: TeamDetailsTestIds.scheduleFilterButton,
                    ),
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
                        testName: 'team_upcoming',
                        emptyText: l10n.teamScheduleEmptyUpcoming,
                        loadErrorText: l10n.teamScheduleLoadError,
                        onRefresh: vm.refresh,
                        onLoadMore: vm.loadMore,
                        onRetry: vm.refresh,
                        header: [
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
                              onTap: () => context.push(
                                AppRoutes.teamPastEventsFor(widget.teamId),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
