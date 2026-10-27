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
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_edit.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/common/widgets/home_sections.dart';
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

  /// Starts the create-event wizard for [team]: its team event. An archived
  /// team cannot get events; permissions decide the rest.
  Future<void> _createEvent(
    BuildContext context,
    WidgetRef ref,
    Team team,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!await checkTeamAccess(
          context,
          ref,
          team,
          TeamSettingsPermissions.createEvent,
        ) ||
        !context.mounted) {
      return;
    }
    if (team.archived ?? false) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(
            ref.msg(
              MessageKeys.teamArchivedCreateEvent,
              l10n.teamArchivedCreateEvent,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.closeAction),
            ),
          ],
        ),
      );
      return;
    }
    ref.read(createEventFlowProvider.notifier).startForTeam(team);
    unawaited(context.push(AppRoutes.createEvent));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final team = ref.watch(teamDetailsProvider(teamId));

    final n = context.native;

    Widget loaded(Team t) {
      final ranking = t.enablePlayerRanking ?? false;
      final state = ref.watch(homeViewModelProvider(teamId));
      final vm = ref.read(homeViewModelProvider(teamId).notifier);
      return Scaffold(
        backgroundColor: n.backgroundSolidPrimary,
        appBar: AppBar(
          backgroundColor: n.backgroundSolidPrimary,
          automaticallyImplyLeading: false,
          leading: BackButton(onPressed: () => context.pop()),
          title: TestId(
            TeamDetailsTestIds.title,
            child: Semantics(header: true, child: Text(t.name ?? '')),
          ),
          actions: [
            // Placement not confirmed against a native device: native keeps
            // the ranking table on its own screen (`TeamMemberRankingFragment`)
            // but no XML/code reviewed here said how it's reached from Team
            // Home, so this icon is a reasonable, low-risk entry point, not
            // a verified match.
            if (ranking)
              TestId(
                TeamDetailsTestIds.tabRankings,
                child: IconButton(
                  tooltip: l10n.teamTabRankings,
                  icon: const Icon(Icons.leaderboard_outlined),
                  onPressed: () =>
                      context.push(AppRoutes.teamRankingsFor(teamId)),
                ),
              ),
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
        floatingActionButton:
            memberAccess(
                  t,
                  TeamSettingsPermissions.createEvent,
                  subscribed: true,
                ) ==
                AccessDecision.hidden
            ? null
            : TestId(
                TeamHomeActionIds.createEvent,
                child: FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.teamCreateEvent),
                  onPressed: () => _createEvent(context, ref, t),
                ),
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
                    onChanged: () => ref.invalidate(teamDetailsProvider(teamId)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      [
                        ref.refLabel(
                          t.teamType,
                          teamTypeLabel(l10n, t.teamType),
                        ),
                        if (t.sportKeys.isNotEmpty) teamSportsText(l10n, t),
                      ].join(' · '),
                      style: TextStyle(color: n.textSecondary, fontSize: 12),
                    ),
                  ),
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
                  onSeeAll: () =>
                      context.push(AppRoutes.teamScheduleFor(teamId)),
                  canOfferCreate:
                      memberAccess(
                        t,
                        TeamSettingsPermissions.createEvent,
                        subscribed: true,
                      ) !=
                      AccessDecision.hidden,
                  onCreateEvent: (ctx, r) => _createEvent(ctx, r, t),
                ),
                PendingActionsSection(
                  l10n: l10n,
                  value: state.pending,
                  onRetry: () => vm.reload(HomeSection.pending),
                  sectionId: TeamHomeActionIds.pendingSection,
                  retryId: TeamHomeActionIds.pendingRetry,
                  actionIdFor: TeamHomeActionIds.pendingAction,
                ),
                TeamMembersPreview(teamId: teamId),
                HomeActivitySection(
                  l10n: l10n,
                  value: state.activity,
                  onRetry: () => vm.reload(HomeSection.activity),
                  sectionId: TeamHomeActionIds.activitySection,
                  retryId: TeamHomeActionIds.activityRetry,
                  yearBadgeId: TeamHomeActionIds.activityYear,
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
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: TestId(
          TeamDetailsTestIds.root,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: n.backgroundSolidPrimary,
        appBar: AppBar(
          backgroundColor: n.backgroundSolidPrimary,
          automaticallyImplyLeading: false,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: TestId(
          TeamDetailsTestIds.root,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TestId(
                  TeamDetailsTestIds.error,
                  child: Text(l10n.teamDetailsLoadError),
                ),
                TestId(
                  TeamDetailsTestIds.retry,
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(teamDetailsProvider(teamId)),
                    child: Text(l10n.retryAction),
                  ),
                ),
              ],
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
