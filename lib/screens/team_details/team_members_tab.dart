import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

enum _MemberAction { editRoles, deactivate, reactivate, remove }

/// Members of a team and, for those allowed to, managing them (native
/// `TeamActiveParticipantFragment`): add people, change roles, deactivate or
/// reactivate, remove. What is offered follows the team's permissions; a team
/// always keeps one active captain.
class TeamMembersTab extends ConsumerStatefulWidget {
  const TeamMembersTab({required this.team, super.key});

  final Team team;

  @override
  ConsumerState<TeamMembersTab> createState() => _TeamMembersTabState();
}

class _TeamMembersTabState extends ConsumerState<TeamMembersTab> {
  bool _inactive = false;
  bool _busy = false;

  int get _teamId => widget.team.id ?? 0;

  AccessDecision _access(String key) => memberAccess(
    widget.team,
    key,
    subscribed: ref.read(sessionInfoControllerProvider).isSubscribed,
  );

  String _permissionFor(_MemberAction action) => switch (action) {
    _MemberAction.editRoles => TeamPermissions.updateMember,
    _MemberAction.deactivate => TeamPermissions.deactivateMember,
    _MemberAction.reactivate => TeamPermissions.reactivateMember,
    _MemberAction.remove => TeamPermissions.removeMember,
  };

  /// Actions the menu of [member] lists: those whose permission exists.
  List<_MemberAction> _actionsFor(TeamPlayer member) => [
    for (final a in _MemberAction.values)
      if (switch (a) {
            _MemberAction.deactivate => !member.isInactive,
            _MemberAction.reactivate => member.isInactive,
            _ => true,
          } &&
          _access(_permissionFor(a)) != AccessDecision.hidden)
        a,
  ];

  void _refresh() {
    ref
      ..invalidate(teamRosterProvider)
      ..invalidate(teamMembersProvider)
      ..invalidate(teamDetailsProvider(_teamId));
  }

  Future<void> _explain(String text) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: TestId(TeamDetailsTestIds.accessDialog, child: Text(text)),
        actions: [
          TestId(
            TeamDetailsTestIds.accessDialogClose,
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.closeAction),
            ),
          ),
        ],
      ),
    );
  }

  /// Applies the access rule of [key]; true when the action may go ahead.
  Future<bool> _allowed(String key) async {
    final l10n = AppLocalizations.of(context);
    final info = widget.team.permission(key);
    switch (_access(key)) {
      case AccessDecision.allowed:
        return true;
      case AccessDecision.hidden:
        return false;
      case AccessDecision.needsSubscription:
        if (ref.read(billingSupportedProvider)) {
          unawaited(context.push(AppRoutes.subscription));
        } else {
          await _explain(l10n.accessNeedsSubscription);
        }
        return false;
      case AccessDecision.blocked:
        await _explain(
          (info?.message ?? '').isNotEmpty
              ? info!.message!
              : l10n.accessBlocked,
        );
        return false;
    }
  }

  Future<void> _change(Future<void> Function() call) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await call();
      _refresh();
    } on AppFailure {
      messenger.showSnackBar(
        SnackBar(
          content: Semantics(
            liveRegion: true,
            child: Text(
              l10n.teamMemberChangeFailed,
              key: const Key(TeamDetailsTestIds.changeFailed),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String text) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(text),
            actions: [
              TestId(
                TeamDetailsTestIds.confirmNo,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.teamMemberCancel),
                ),
              ),
              TestId(
                TeamDetailsTestIds.confirmYes,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.teamMemberYes),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _onAction(
    _MemberAction action,
    TeamPlayer member,
    List<TeamPlayer> all,
  ) async {
    final l10n = AppLocalizations.of(context);
    final id = member.id;
    if (id == null || _busy) return;
    if (!await _allowed(_permissionFor(action)) || !mounted) return;
    final repo = ref.read(teamsRepositoryProvider);
    final name = member.user?.displayName ?? '';
    switch (action) {
      case _MemberAction.editRoles:
        final roles =
            await showDialog<({bool captain, bool coach, bool player})>(
              context: context,
              builder: (_) => _RolesDialog(member: member, all: all),
            );
        if (roles == null) return;
        await _change(
          () => repo.updateMemberRoles(
            _teamId,
            id,
            captain: roles.captain,
            coach: roles.coach,
            player: roles.player,
          ),
        );
      case _MemberAction.deactivate:
        if (isOnlyCaptain(all, member)) {
          await _explain(l10n.teamMemberOnlyCaptain);
          return;
        }
        if (!await _confirm(
          l10n.teamMemberDeactivateTitle(name),
          l10n.teamMemberDeactivateText,
        )) {
          return;
        }
        await _change(() => repo.setMemberActive(_teamId, id, active: false));
      case _MemberAction.reactivate:
        if (!await _confirm(
          l10n.teamMemberReactivateTitle(name),
          l10n.teamMemberReactivateText,
        )) {
          return;
        }
        await _change(() => repo.setMemberActive(_teamId, id, active: true));
      case _MemberAction.remove:
        if (isOnlyCaptain(all, member)) {
          await _explain(l10n.teamMemberOnlyCaptain);
          return;
        }
        if (!await _confirm(
          l10n.teamMemberRemoveTitle(name),
          l10n.teamMemberRemoveText,
        )) {
          return;
        }
        await _change(() => repo.removeMember(_teamId, id));
    }
  }

  Future<void> _add() async {
    if (!await _allowed(TeamPermissions.addMembers) || !mounted) return;
    final added = await context.push<bool>(
      AppRoutes.teamAddMembersFor(_teamId),
    );
    if (added ?? false) _refresh();
  }

  String _actionLabel(AppLocalizations l10n, _MemberAction a) => switch (a) {
    _MemberAction.editRoles => l10n.teamMemberEditRoles,
    _MemberAction.deactivate => l10n.teamMemberDeactivate,
    _MemberAction.reactivate => l10n.teamMemberReactivate,
    _MemberAction.remove => l10n.teamMemberRemove,
  };

  String _actionId(_MemberAction a) => switch (a) {
    _MemberAction.editRoles => TeamDetailsTestIds.actionEdit,
    _MemberAction.deactivate => TeamDetailsTestIds.actionDeactivate,
    _MemberAction.reactivate => TeamDetailsTestIds.actionReactivate,
    _MemberAction.remove => TeamDetailsTestIds.actionRemove,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roster = ref.watch(
      teamRosterProvider((teamId: _teamId, inactive: _inactive)),
    );
    final canAdd = _access(TeamPermissions.addMembers) != AccessDecision.hidden;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TestId(
                  TeamDetailsTestIds.showInactive,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.teamMembersShowInactive),
                    value: _inactive,
                    onChanged: (v) => setState(() => _inactive = v),
                  ),
                ),
              ),
              if (canAdd)
                TestId(
                  TeamDetailsTestIds.addMembers,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _add,
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(l10n.teamAddMembers),
                  ),
                ),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: roster.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TestId(
                    TeamDetailsTestIds.membersError,
                    child: Text(l10n.teamMembersLoadError),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(teamRosterProvider),
                    child: Text(l10n.retryAction),
                  ),
                ],
              ),
            ),
            data: (list) => list.isEmpty
                ? Center(
                    child: TestId(
                      TeamDetailsTestIds.membersEmpty,
                      child: Text(l10n.teamMembersEmpty),
                    ),
                  )
                : ListView(
                    children: [
                      for (final m in list)
                        TestId(
                          TeamDetailsTestIds.member(m.id ?? m.userId ?? 0),
                          child: ListTile(
                            title: Text(m.user?.displayName ?? ''),
                            subtitle: Text(
                              [
                                memberRolesText(l10n, m),
                                if (m.isInactive) l10n.teamMemberInactive,
                              ].where((s) => s.isNotEmpty).join(' · '),
                            ),
                            trailing: _actionsFor(m).isEmpty
                                ? null
                                : TestId(
                                    TeamDetailsTestIds.memberActions(
                                      m.id ?? m.userId ?? 0,
                                    ),
                                    child: PopupMenuButton<_MemberAction>(
                                      tooltip: l10n.teamMemberActions,
                                      enabled: !_busy,
                                      onSelected: (a) => _onAction(a, m, list),
                                      itemBuilder: (_) => [
                                        for (final a in _actionsFor(m))
                                          PopupMenuItem(
                                            value: a,
                                            child: TestId(
                                              _actionId(a),
                                              child: Text(
                                                _actionLabel(l10n, a),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _RolesDialog extends StatefulWidget {
  const _RolesDialog({required this.member, required this.all});

  final TeamPlayer member;
  final List<TeamPlayer> all;

  @override
  State<_RolesDialog> createState() => _RolesDialogState();
}

class _RolesDialogState extends State<_RolesDialog> {
  late bool _captain = widget.member.isCaptain ?? false;
  late bool _player = widget.member.isPlayer ?? false;
  late bool _coach = widget.member.isCoach ?? false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget role(String id, String label, bool value, ValueChanged<bool> set) =>
        TestId(
          id,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            value: value,
            onChanged: (v) => setState(() {
              set(v ?? false);
              _error = null;
            }),
          ),
        );
    return AlertDialog(
      title: TestId(
        TeamDetailsTestIds.rolesDialog,
        child: Text(
          l10n.teamMemberRolesTitle(widget.member.user?.displayName ?? ''),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          role(
            TeamDetailsTestIds.rolesCaptain,
            l10n.teamRoleCaptain,
            _captain,
            (v) => _captain = v,
          ),
          role(
            TeamDetailsTestIds.rolesPlayer,
            l10n.teamRolePlayer,
            _player,
            (v) => _player = v,
          ),
          role(
            TeamDetailsTestIds.rolesCoach,
            l10n.teamRoleCoach,
            _coach,
            (v) => _coach = v,
          ),
          if (_error != null)
            TestId(
              TeamDetailsTestIds.rolesError,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TestId(
          TeamDetailsTestIds.rolesCancel,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.teamMemberCancel),
          ),
        ),
        TestId(
          TeamDetailsTestIds.rolesSave,
          child: FilledButton(
            onPressed: () {
              if (!rolesAllowed(
                widget.all,
                widget.member,
                captain: _captain,
                coach: _coach,
                player: _player,
              )) {
                setState(
                  () => _error = !_captain && !_coach && !_player
                      ? l10n.teamMemberRolesNeedOne
                      : l10n.teamMemberOnlyCaptain,
                );
                return;
              }
              Navigator.of(context)
                  .pop((captain: _captain, coach: _coach, player: _player));
            },
            child: Text(l10n.teamMemberSave),
          ),
        ),
      ],
    );
  }
}
