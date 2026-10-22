import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

/// A team and its members (read only). The native team home also has the
/// team schedule, rankings and member management; those are later work.
class TeamDetailsScreen extends ConsumerWidget {
  const TeamDetailsScreen({required this.teamId, super.key});

  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final team = ref.watch(teamDetailsProvider(teamId));
    final members = ref.watch(teamMembersProvider(teamId));

    Widget header(Team t) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TestId(
          TeamDetailsTestIds.title,
          child: Semantics(
            header: true,
            child: Text(
              t.name ?? '',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${l10n.teamDetailsType}: '
          '${ref.refLabel(t.teamType, teamTypeLabel(l10n, t.teamType))}',
        ),
        if (t.sportKeys.isNotEmpty)
          Text('${l10n.teamDetailsSports}: ${teamSportsText(l10n, t)}'),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            l10n.teamDetailsMembers,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );

    Widget memberList() => members.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Column(
        children: [
          TestId(
            TeamDetailsTestIds.membersError,
            child: Text(l10n.teamMembersLoadError),
          ),
          TextButton(
            onPressed: () => ref.invalidate(teamMembersProvider(teamId)),
            child: Text(l10n.retryAction),
          ),
        ],
      ),
      data: (list) => list.isEmpty
          ? TestId(
              TeamDetailsTestIds.membersEmpty,
              child: Text(l10n.teamMembersEmpty),
            )
          : Column(
              children: [
                for (final m in list)
                  TestId(
                    TeamDetailsTestIds.member(m.id ?? m.userId ?? 0),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.user?.displayName ?? ''),
                      subtitle: Text(memberRolesText(l10n, m)),
                    ),
                  ),
              ],
            ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: TestId(
        TeamDetailsTestIds.root,
        child: SafeArea(
          child: team.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
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
            data: (t) => ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [header(t), memberList()],
            ),
          ),
        ),
      ),
    );
  }
}
