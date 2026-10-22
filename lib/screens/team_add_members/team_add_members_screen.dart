import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/teams/create_team_flow.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

/// Add people to an existing team (native `InviteTeamMemFragment` for a team
/// that exists): search people outside the team, choose their roles, add them.
/// Inviting by phone number or email is later work.
class TeamAddMembersScreen extends ConsumerStatefulWidget {
  const TeamAddMembersScreen({required this.teamId, super.key});

  final int teamId;

  @override
  ConsumerState<TeamAddMembersScreen> createState() =>
      _TeamAddMembersScreenState();
}

class _TeamAddMembersScreenState extends ConsumerState<TeamAddMembersScreen> {
  Timer? _debounce;
  String _query = '';
  final List<MemberRoles> _chosen = [];
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  MemberRoles _rolesOf(AppUser user) => _chosen.firstWhere(
    (m) => m.user.id == user.id,
    orElse: () => MemberRoles(user),
  );

  /// Flips a role; a person left with none is dropped.
  void _toggle(AppUser user, TeamRole role) {
    final next = _rolesOf(user).toggled(role);
    setState(() {
      _chosen.removeWhere((m) => m.user.id == user.id);
      if (next.any) _chosen.add(next);
      _failed = false;
    });
  }

  Future<void> _save() async {
    if (_chosen.isEmpty || _saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref.read(teamsRepositoryProvider).addMembers(widget.teamId, [
        for (final m in _chosen)
          {
            'user_id': m.user.id,
            'is_captain': m.captain,
            'is_player': m.player,
            'is_coach': m.coach,
          },
      ]);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.teamAddMembersDone)));
      context.pop(true);
    } on AppFailure {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final candidates = ref.watch(
      teamCandidatesProvider((teamId: widget.teamId, query: _query)),
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          TeamAddMembersTestIds.title,
          child: Semantics(header: true, child: Text(l10n.teamAddMembersTitle)),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TestId(
            TeamAddMembersTestIds.save,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _chosen.isEmpty || _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.teamAddMembersSave),
            ),
          ),
        ),
      ),
      body: TestId(
        TeamAddMembersTestIds.root,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.teamAddMembersHint),
                  const SizedBox(height: 8),
                  TestId(
                    TeamAddMembersTestIds.search,
                    child: TextField(
                      onChanged: _onChanged,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: l10n.createTeamMembersSearchHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (_failed)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TestId(
                        TeamAddMembersTestIds.failed,
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            l10n.teamAddMembersFailed,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: candidates.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TestId(
                        TeamAddMembersTestIds.error,
                        child: Text(l10n.teamAddMembersLoadError),
                      ),
                      TestId(
                        TeamAddMembersTestIds.retry,
                        child: TextButton(
                          onPressed: () =>
                              ref.invalidate(teamCandidatesProvider),
                          child: Text(l10n.retryAction),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (users) => users.isEmpty
                    ? Center(
                        child: TestId(
                          TeamAddMembersTestIds.empty,
                          child: Text(l10n.teamAddMembersEmpty),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final user in users)
                            if (user.id != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        for (final entry in {
                                          TeamRole.captain: (
                                            'captain',
                                            l10n.teamRoleCaptain,
                                          ),
                                          TeamRole.player: (
                                            'player',
                                            l10n.teamRolePlayer,
                                          ),
                                          TeamRole.coach: (
                                            'coach',
                                            l10n.teamRoleCoach,
                                          ),
                                        }.entries)
                                          TestId(
                                            TeamAddMembersTestIds.role(
                                              user.id!,
                                              entry.value.$1,
                                            ),
                                            child: FilterChip(
                                              label: Text(entry.value.$2),
                                              selected: _rolesOf(user)
                                                  .has(entry.key),
                                              onSelected: (_) =>
                                                  _toggle(user, entry.key),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
