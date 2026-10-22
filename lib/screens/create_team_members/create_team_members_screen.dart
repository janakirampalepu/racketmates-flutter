import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/teams/create_team_flow.dart';
import 'package:racketmates/common/teams/team_member_search.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_team_members/create_team_members_test_ids.dart';

/// Invite people to the new team and choose their roles, then create the team
/// (native `InviteTeamMemFragment`). Members are optional; inviting by phone
/// number or email is later work.
class CreateTeamMembersScreen extends ConsumerWidget {
  const CreateTeamMembersScreen({super.key});

  String? _serverMessage(AppFailure failure) => switch (failure) {
    ServerFailure(message: final m) when m != null && m.isNotEmpty => m,
    UnauthorizedFailure(message: final m) when m != null && m.isNotEmpty => m,
    _ => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(teamMemberSearchProvider);
    final vm = ref.read(teamMemberSearchProvider.notifier);
    final draft = ref.watch(createTeamFlowProvider);
    final flow = ref.read(createTeamFlowProvider.notifier);
    final submission = ref.watch(createTeamSubmitterProvider);

    MemberRoles rolesOf(AppUser user) => draft.members.firstWhere(
      (m) => m.user.id == user.id,
      orElse: () => MemberRoles(user),
    );

    Widget results() {
      if (state.loading && state.results.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (state.failure != null) {
        return Column(
          children: [
            Text(l10n.createPlayersLoadError),
            TestId(
              CreateTeamMembersTestIds.retry,
              child: TextButton(
                onPressed: vm.search,
                child: Text(l10n.retryAction),
              ),
            ),
          ],
        );
      }
      if (state.isEmpty) {
        return TestId(
          CreateTeamMembersTestIds.empty,
          child: Text(l10n.createTeamMembersEmpty),
        );
      }
      return Column(
        children: [
          for (final user in state.results)
            if (user.id != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final entry in {
                          TeamRole.captain: ('captain', l10n.teamRoleCaptain),
                          TeamRole.player: ('player', l10n.teamRolePlayer),
                          TeamRole.coach: ('coach', l10n.teamRoleCoach),
                        }.entries)
                          TestId(
                            CreateTeamMembersTestIds.role(
                              user.id!,
                              entry.value.$1,
                            ),
                            child: FilterChip(
                              label: Text(entry.value.$2),
                              selected: rolesOf(user).has(entry.key),
                              onSelected: (_) =>
                                  flow.toggleMemberRole(user, entry.key),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      );
    }

    return StepScaffold(
      rootId: CreateTeamMembersTestIds.root,
      titleId: CreateTeamMembersTestIds.title,
      title: l10n.createTeamMembersTitle,
      primaryLabel: l10n.createTeamSubmitAction,
      primaryId: CreateTeamMembersTestIds.create,
      loading: submission.loading,
      onPrimary: () async {
        final ok = await ref
            .read(createTeamSubmitterProvider.notifier)
            .submit();
        if (!ok || !context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.createTeamCreated)));
        context.go(AppRoutes.teams);
      },
      onBack: () => context.pop(),
      children: [
        Text(l10n.createTeamMembersHint),
        const SizedBox(height: 12),
        TestId(
          CreateTeamMembersTestIds.search,
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: l10n.createTeamMembersSearchHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: vm.setQuery,
          ),
        ),
        const SizedBox(height: 12),
        results(),
        if (submission.failure != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TestId(
              CreateTeamMembersTestIds.error,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _serverMessage(submission.failure!) ??
                      ref.msg(MessageKeys.errorGeneral, l10n.createTeamFailed),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
