import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/teams/create_team_flow.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/teams/teams_test_ids.dart';

/// Teams tab: the user's active teams (native `ActiveTeamsFragment`). Team
/// home pages beyond the member list, rankings, archived teams and the family
/// user picker are later work.
class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  /// Native `ActiveTeamsFragment`: a feature that needs a subscription or is
  /// disabled explains itself instead of opening; one that is not available
  /// is not offered at all (see `build`).
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
    final canOffer =
        decideAccess(
          session.user?.permission('teams.create'),
          subscribed: session.isSubscribed,
        ) !=
        AccessDecision.hidden;

    Widget body() => teams.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
                padding: const EdgeInsets.all(24),
                child: TestId(
                  TeamsTestIds.empty,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.teamsEmptyTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.teamsEmptyBody, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, i) => _TeamTile(team: list[i]),
            ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTeams)),
      floatingActionButton: canOffer
          ? TestId(
              TeamsTestIds.create,
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: Text(l10n.createTeamAction),
                onPressed: () => _create(context, ref),
              ),
            )
          : null,
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

class _TeamTile extends ConsumerWidget {
  const _TeamTile({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = team.id;
    final details = [
      ref.refLabel(team.teamType, teamTypeLabel(l10n, team.teamType)),
      teamSportsText(l10n, team),
      if (team.members != null) l10n.teamMembersCount(team.members!),
    ].where((s) => s.isNotEmpty).join(' · ');
    return TestId(
      TeamsTestIds.tile(id ?? 0),
      child: ListTile(
        title: Text(team.name ?? ''),
        subtitle: Text(details),
        trailing: const Icon(Icons.chevron_right),
        onTap: id == null ? null : () => context.push(AppRoutes.teamFor(id)),
      ),
    );
  }
}
