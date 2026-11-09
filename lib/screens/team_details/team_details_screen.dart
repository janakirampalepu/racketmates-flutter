import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_edit.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/common/widgets/home_sections.dart';
import 'package:racketmates/common/widgets/load_error_body.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/home/home_view_model.dart';
import 'package:racketmates/screens/team_details/team_access.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/team_details/team_members_preview.dart';

/// Team Home (native `TeamHomeFragment`): the same dashboard sections as
/// the Home tab (Upcoming events, Pending actions, Activity — shared via
/// `common/widgets/home_sections.dart`, each scoped to this team through
/// `homeViewModelProvider(teamId)`) plus the team-only pieces: an archived
/// banner and a team-members preview. Native does not show the ranking
/// table or the members list inline here — both are separate screens
/// (`TeamMemberRankingFragment`/`TeamActiveParticipantFragment`), reached
/// from here instead of embedded as tabs.
class TeamDetailsScreen extends ConsumerWidget {
  const TeamDetailsScreen({required this.teamId, super.key});

  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final team = ref.watch(teamDetailsProvider(teamId));

    final n = context.native;

    Widget loaded(Team t) {
      final ranking = t.enablePlayerRanking ?? false;
      final state = ref.watch(homeViewModelProvider(teamId));
      final vm = ref.read(homeViewModelProvider(teamId).notifier);
      final canCreateEvent =
          memberAccess(
            t,
            TeamSettingsPermissions.createEvent,
            subscribed: true,
          ) !=
          AccessDecision.hidden;
      // Team Home's own activity numbers (native `TeamHomeFragment
      // .displayTeamStats` / `TeamHomeViewModel`): read straight off the
      // Team object, never a separate stats call (see home_view_model.dart
      // for why) — a single "year" entry with no hours breakdown, since
      // that's all native actually has for a team.
      final activity = AsyncValue<List<HomePageStats>>.data([
        HomePageStats(
          year: DateTime.now().year,
          totalEvents: t.eventsCompleted,
          wins: t.eventsWon,
          losses: t.eventsLost,
        ),
      ]);
      return Scaffold(
        backgroundColor: n.backgroundSolidPrimary,
        appBar: AppBar(
          backgroundColor: n.backgroundSolidPrimary,
          automaticallyImplyLeading: false,
          title: TestId(
            TeamDetailsTestIds.title,
            child: Semantics(header: true, child: Text(t.name ?? '')),
          ),
          actions: [
            if (memberAccess(
                  t,
                  TeamSettingsPermissions.settings,
                  subscribed: true,
                ) !=
                AccessDecision.hidden)
              TestId(
                TeamHomeActionIds.settingsButton,
                child: IconButton(
                  tooltip: l10n.teamSettingsAction,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () async {
                    if (await checkTeamAccess(
                          context,
                          ref,
                          t,
                          TeamSettingsPermissions.settings,
                        ) &&
                        context.mounted) {
                      await context.push(AppRoutes.teamSettingsFor(teamId));
                      ref.invalidate(teamDetailsProvider(teamId));
                    }
                  },
                ),
              ),
          ],
        ),
        body: TestId(
          TeamDetailsTestIds.root,
          child: RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              children: [
                if (t.archived ?? false)
                  _ArchivedBanner(
                    team: t,
                    onChanged: () =>
                        ref.invalidate(teamDetailsProvider(teamId)),
                  ),
                UpcomingEventsSection(
                  l10n: l10n,
                  value: state.upcoming,
                  onRetry: () => vm.reload(HomeSection.upcoming),
                  sectionId: TeamHomeActionIds.upcomingSection,
                  seeAllId: TeamHomeActionIds.upcomingSeeAll,
                  retryId: TeamHomeActionIds.upcomingRetry,
                  createEventId: TeamHomeActionIds.upcomingCreateEvent,
                  eventIdFor: TeamHomeActionIds.upcomingEvent,
                  onSeeAll: () => context.go(AppRoutes.teamScheduleFor(teamId)),
                  // Native shows a create-event button in Team Home's own
                  // empty Upcoming-events state too (Android's nested
                  // `btnCreateEvent` inside `layoutUpcomingNoEvents`, iOS's
                  // `canShowAddEventButton()`), gated on the same
                  // `team.events.create` permission as Team Schedule's FAB
                  // — both entry points exist natively, not just one.
                  canOfferCreate: canCreateEvent,
                  onCreateEvent: (ctx, r) => startTeamCreateEvent(ctx, r, t),
                ),
                SizedBox(height: context.sdp(32)),
                PendingActionsSection(
                  l10n: l10n,
                  value: state.pending,
                  onRetry: () => vm.reload(HomeSection.pending),
                  sectionId: TeamHomeActionIds.pendingSection,
                  retryId: TeamHomeActionIds.pendingRetry,
                  actionIdFor: TeamHomeActionIds.pendingAction,
                ),
                SizedBox(height: context.sdp(32)),
                TeamMembersPreview(team: t, rankingEnabled: ranking),
                SizedBox(height: context.sdp(32)),
                HomeActivitySection(
                  l10n: l10n,
                  value: activity,
                  onRetry: () => vm.reload(HomeSection.activity),
                  sectionId: TeamHomeActionIds.activitySection,
                  retryId: TeamHomeActionIds.activityRetry,
                  yearBadgeId: TeamHomeActionIds.activityYear,
                  isTeamHome: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return team.when(
      loading: () => Scaffold(
        backgroundColor: n.backgroundSolidPrimary,
        appBar: AppBar(
          backgroundColor: n.backgroundSolidPrimary,
          automaticallyImplyLeading: false,
        ),
        body: TestId(
          TeamDetailsTestIds.root,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: n.backgroundSolidPrimary,
        appBar: AppBar(
          backgroundColor: n.backgroundSolidPrimary,
          automaticallyImplyLeading: false,
        ),
        body: TestId(
          TeamDetailsTestIds.root,
          child: Center(
            child: LoadErrorBody(
              error: error,
              fallbackText: l10n.teamDetailsLoadError,
              retryId: TeamDetailsTestIds.retry,
              onRetry: () => ref.invalidate(teamDetailsProvider(teamId)),
              errorTestId: TeamDetailsTestIds.error,
            ),
          ),
        ),
      ),
      data: loaded,
    );
  }
}

/// "This team is archived" with the way back (native team home).
class _ArchivedBanner extends ConsumerWidget {
  const _ArchivedBanner({required this.team, required this.onChanged});

  final Team team;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final canUnarchive =
        memberAccess(
          team,
          TeamSettingsPermissions.unarchive,
          subscribed: true,
        ) !=
        AccessDecision.hidden;
    return TestId(
      TeamHomeActionIds.archivedBanner,
      // Same tinted-card convention as Home's own banner
      // (`HomeDowntimeBanner`), not a generic Material container color.
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: n.colorPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.teamArchivedBanner,
                style: TextStyle(color: n.textPrimary),
              ),
            ),
            if (canUnarchive)
              TestId(
                TeamHomeActionIds.unarchiveButton,
                child: TextButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!await checkTeamAccess(
                          context,
                          ref,
                          team,
                          TeamSettingsPermissions.unarchive,
                        ) ||
                        !context.mounted) {
                      return;
                    }
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(l10n.teamUnarchiveTitle(team.name ?? '')),
                        content: Text(l10n.teamUnarchiveText),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text(l10n.teamActionNo),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: Text(l10n.teamActionYes),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    try {
                      await ref
                          .read(teamsRepositoryProvider)
                          .unarchive(team.id ?? 0);
                      ref.invalidate(myTeamsProvider);
                      onChanged();
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.teamUnarchivedDone)),
                      );
                    } on AppFailure {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.teamActionFailed)),
                      );
                    }
                  },
                  child: Text(l10n.teamUnarchive),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
