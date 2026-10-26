import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/teams/create_team_flow.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/widgets/family_user_picker.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/teams/teams_test_ids.dart';

/// Teams tab: the user's teams (native `ActiveTeamsFragment`/iOS
/// `TeamListView`). Both native apps show one flat, unpaginated list of
/// "my teams" — no search, no archived/captain/sport filter, and no
/// pull-to-refresh (kept here anyway: see the note on `RefreshIndicator`
/// below). Archived teams are not filtered out; they're tagged with an
/// "Archived" badge inline, same as native.
class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  /// Native `ActiveTeamsFragment`/`TeamListViewModel`: a feature that needs a
  /// subscription or is disabled explains itself instead of opening; one that
  /// is not available is not offered at all (see `build`).
  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionInfoControllerProvider);
    final access = session.user?.permission('teams.create');
    switch (decideAccess(access, subscribed: session.isSubscribed)) {
      case AccessDecision.allowed || AccessDecision.hidden:
        ref.read(createTeamFlowProvider.notifier).reset();
        unawaited(context.push(AppRoutes.createTeam));
      case AccessDecision.needsSubscription || AccessDecision.blocked:
        final l10n = AppLocalizations.of(context);
        final needsSubscription =
            decideAccess(access, subscribed: session.isSubscribed) ==
            AccessDecision.needsSubscription;
        final text = (access?.message ?? '').isNotEmpty
            ? access!.message!
            : (needsSubscription
                  ? l10n.accessNeedsSubscription
                  : l10n.accessBlocked);
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            content: TestId(TeamsTestIds.accessDialog, child: Text(text)),
            actions: [
              if (needsSubscription && ref.read(billingSupportedProvider))
                TestId(
                  TeamsTestIds.accessDialogUpgrade,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      unawaited(context.push(AppRoutes.subscription));
                    },
                    child: Text(l10n.accessUpgradeAction),
                  ),
                ),
              TestId(
                TeamsTestIds.accessDialogClose,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.closeAction),
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final teams = ref.watch(myTeamsProvider);
    final session = ref.watch(sessionInfoControllerProvider);
    final sdp = context.sdp;
    final canOffer =
        decideAccess(
          session.user?.permission('teams.create'),
          subscribed: session.isSubscribed,
        ) !=
        AccessDecision.hidden;

    Widget body() => teams.when(
      loading: () => const _TeamsShimmer(),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TestId(TeamsTestIds.error, child: Text(l10n.teamsLoadError)),
            TestId(
              TeamsTestIds.retry,
              child: TextButton(
                onPressed: () => ref.invalidate(myTeamsProvider),
                child: Text(l10n.retryAction),
              ),
            ),
          ],
        ),
      ),
      data: (list) => list.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(sdp(24)),
                child: TestId(
                  TeamsTestIds.empty,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SvgIcon('ic_community_team', size: 62),
                      SizedBox(height: sdp(8)),
                      Text(
                        l10n.teamsEmptyTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: sdp(8)),
                      Text(l10n.teamsEmptyBody, textAlign: TextAlign.center),
                      if (canOffer) ...[
                        SizedBox(height: sdp(16)),
                        TestId(
                          TeamsTestIds.createInEmpty,
                          child: FilledButton(
                            onPressed: () => _create(context, ref),
                            child: Text(l10n.createTeamAction),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: sdp(8)),
              children: [
                const FamilyAvatarsRow(),
                for (final team in list) _TeamTile(team: team),
              ],
            ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTeams),
        actions: [
          if (canOffer)
            TestId(
              TeamsTestIds.create,
              child: IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.createTeamAction,
                onPressed: () => _create(context, ref),
              ),
            ),
        ],
      ),
      // Neither native app has pull-to-refresh on this screen (Android's
      // SwipeRefreshLayout spinner is turned off immediately and the real
      // feedback is its shimmer reload; iOS has no refresh gesture at all).
      // Kept here anyway as a low-risk, useful deviation (same call made for
      // Home).
      body: TestId(
        TeamsTestIds.root,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(myTeamsProvider.future),
          child: body(),
        ),
      ),
    );
  }
}

/// Loading placeholder (native: a generic shimmer row, repeated). Three bars
/// stand in for native's repeated shimmer rows, pulsing like a real shimmer.
class _TeamsShimmer extends StatefulWidget {
  const _TeamsShimmer();

  @override
  State<_TeamsShimmer> createState() => _TeamsShimmerState();
}

class _TeamsShimmerState extends State<_TeamsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sdp(8), horizontal: sdp(16)),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Column(
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                margin: EdgeInsets.only(bottom: sdp(12)),
                height: sdp(72),
                decoration: BoxDecoration(
                  color: n.borderSolidPrimary.withValues(
                    alpha: 0.2 + _controller.value * 0.2,
                  ),
                  borderRadius: BorderRadius.circular(sdp(8)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One row of the list (native `item_teams_list`): name, an "Archived" pill
/// when the team is archived, per-sport icons and the member count. Neither
/// native app shows the team type or a captain badge on this row, and the
/// `GET teams` list response carries no member/avatar data to show here.
class _TeamTile extends ConsumerWidget {
  const _TeamTile({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final id = team.id;
    final archived = team.archived ?? false;
    final sportIcons = [
      for (final key in team.sportKeys)
        if (SportKey.fromKey(key) case final sport?) sportIconName(sport),
    ];
    final members = team.members;
    // Native: name, sport icons (no label) and member count; no team-type or
    // captain badge on this row.
    final sportsText = teamSportsText(l10n, team);
    return TestId(
      TeamsTestIds.tile(id ?? 0),
      child: Semantics(
        button: id != null,
        child: Padding(
          padding: EdgeInsets.fromLTRB(sdp(16), 0, sdp(16), sdp(12)),
          child: Material(
            color: n.windowBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sdp(12)),
              side: BorderSide(color: n.borderSolidPrimary, width: sdp(1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: id == null
                  ? null
                  : () => context.push(AppRoutes.teamFor(id)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: EdgeInsets.all(sdp(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    team.name ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: NativeText.medium(
                                      sdp(14),
                                      n.textPrimary,
                                    ),
                                  ),
                                ),
                                if (archived)
                                  TestId(
                                    TeamsTestIds.archivedBadge(id ?? 0),
                                    child: Container(
                                      margin: EdgeInsets.only(left: sdp(8)),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: sdp(8),
                                        vertical: sdp(2),
                                      ),
                                      decoration: BoxDecoration(
                                        color: n.borderSolidPrimary,
                                        borderRadius: BorderRadius.circular(
                                          sdp(20),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.teamArchivedBadge,
                                        style: NativeText.regular(
                                          sdp(10),
                                          n.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (members != null)
                              Padding(
                                padding: EdgeInsets.only(top: sdp(4)),
                                child: Text(
                                  l10n.teamMembersCount(members),
                                  style: NativeText.regular(
                                    sdp(12),
                                    n.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (sportIcons.isNotEmpty)
                        Semantics(
                          label: sportsText,
                          excludeSemantics: true,
                          child: Padding(
                            padding: EdgeInsets.only(left: sdp(8)),
                            child: Row(
                              children: [
                                for (final icon in sportIcons)
                                  Padding(
                                    padding: EdgeInsets.only(left: sdp(4)),
                                    child: SvgIcon(icon, size: sdp(20)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(width: sdp(4)),
                      Icon(
                        Icons.chevron_right,
                        color: n.textSecondary,
                        size: sdp(20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
