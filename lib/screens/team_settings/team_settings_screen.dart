import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/teams/create_team_flow.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_edit.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_access.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

/// Edit a team and archive, unarchive or delete it (native `NewTeamFragment`
/// in update mode with its team action menu). The members stay with the team
/// home; the creator's own roles are not part of the edit.
class TeamSettingsScreen extends ConsumerWidget {
  const TeamSettingsScreen({required this.teamId, super.key});

  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final team = ref.watch(teamDetailsProvider(teamId));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          TeamSettingsTestIds.title,
          child: Semantics(header: true, child: Text(l10n.teamSettingsTitle)),
        ),
      ),
      body: TestId(
        TeamSettingsTestIds.root,
        child: team.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TestId(
                  TeamSettingsTestIds.loadError,
                  child: Text(l10n.teamDetailsLoadError),
                ),
                TestId(
                  TeamSettingsTestIds.retry,
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(teamDetailsProvider(teamId)),
                    child: Text(l10n.retryAction),
                  ),
                ),
              ],
            ),
          ),
          data: (t) => _Form(team: t),
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.team});

  final Team team;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late TeamEdit _edit = TeamEdit.of(widget.team);
  late final _name = TextEditingController(text: _edit.name);
  List<TeamDetailsError> _errors = const [];
  bool _busy = false;
  bool _saveFailed = false;
  bool _actionFailed = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int get _id => widget.team.id ?? 0;

  void _clear(TeamDetailsError error) => setState(
    () => _errors = [
      for (final e in _errors)
        if (e != error) e,
    ],
  );

  void _refreshTeams() {
    ref
      ..invalidate(teamDetailsProvider(_id))
      ..invalidate(myTeamsProvider);
  }

  Future<void> _save() async {
    final errors = validateTeamEdit(_edit);
    setState(() {
      _errors = errors;
      _saveFailed = false;
    });
    if (errors.isNotEmpty || _busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(teamsRepositoryProvider)
          .updateTeam(_id, buildUpdateTeamBody(widget.team, _edit));
      _refreshTeams();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.teamSettingsSaved)));
      context.pop();
    } on AppFailure {
      if (mounted) {
        setState(() {
          _busy = false;
          _saveFailed = true;
        });
      }
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
                TeamSettingsTestIds.confirmNo,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.teamActionNo),
                ),
              ),
              TestId(
                TeamSettingsTestIds.confirmYes,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.teamActionYes),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Archive, unarchive or delete after the permission and a confirmation.
  Future<void> _teamAction(
    String permission,
    String title,
    String text,
    Future<void> Function(TeamsRepository repo) call,
    String done, {
    bool leaves = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (_busy ||
        !await checkTeamAccess(context, ref, widget.team, permission) ||
        !mounted ||
        !await _confirm(title, text)) {
      return;
    }
    setState(() {
      _busy = true;
      _actionFailed = false;
    });
    try {
      await call(ref.read(teamsRepositoryProvider));
      _refreshTeams();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      if (leaves) {
        router.go(AppRoutes.teams);
      } else if (mounted) {
        router.pop();
      }
    } on AppFailure {
      if (mounted) {
        setState(() {
          _busy = false;
          _actionFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final team = widget.team;
    final errorColor = Theme.of(context).colorScheme.error;

    Widget error(String id, String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TestId(
        id,
        child: Semantics(
          liveRegion: true,
          child: Text(text, style: TextStyle(color: errorColor)),
        ),
      ),
    );
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );

    bool offered(String key) =>
        memberAccess(team, key, subscribed: true) != AccessDecision.hidden;
    final archived = team.archived ?? false;
    final name = team.name ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TestId(
          TeamSettingsTestIds.name,
          child: TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.createTeamNameLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) {
              _edit = _edit.copyWith(name: v);
              _clear(TeamDetailsError.nameRequired);
            },
          ),
        ),
        if (_errors.contains(TeamDetailsError.nameRequired))
          error(TeamSettingsTestIds.nameError, l10n.createTeamNameRequired),
        heading(l10n.createTeamTypeLabel),
        SegmentedButton<String>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            for (final key in [TeamTypes.casual, TeamTypes.competitive])
              ButtonSegment(
                value: key,
                label: TestId(
                  TeamSettingsTestIds.type(key),
                  child: Text(ref.refLabel(key, teamTypeLabel(l10n, key))),
                ),
              ),
          ],
          selected: {?_edit.teamType},
          onSelectionChanged: (s) {
            setState(
              () => _edit = _edit.copyWith(
                teamType: () => s.isEmpty ? null : s.first,
              ),
            );
            _clear(TeamDetailsError.typeRequired);
          },
        ),
        if (_errors.contains(TeamDetailsError.typeRequired))
          error(TeamSettingsTestIds.typeError, l10n.createTeamTypeRequired),
        heading(l10n.createTeamSportsLabel),
        for (final sport in SportKey.values)
          TestId(
            TeamSettingsTestIds.sport(sport.key),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(sportLabel(l10n, sport)),
              value: _edit.sports.contains(sport),
              onChanged: (v) {
                setState(
                  () => _edit = _edit.copyWith(
                    sports: [
                      for (final s in _edit.sports)
                        if (s != sport) s,
                      if (v ?? false) sport,
                    ],
                  ),
                );
                _clear(TeamDetailsError.sportRequired);
              },
            ),
          ),
        if (_errors.contains(TeamDetailsError.sportRequired))
          error(TeamSettingsTestIds.sportError, l10n.createTeamSportRequired),
        const SizedBox(height: 8),
        TestId(
          TeamSettingsTestIds.ranking,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.createTeamRankingLabel),
            subtitle: Text(l10n.createTeamRankingHint),
            value: _edit.enablePlayerRanking,
            onChanged: (v) =>
                setState(() => _edit = _edit.copyWith(enablePlayerRanking: v)),
          ),
        ),
        if (_saveFailed)
          error(TeamSettingsTestIds.failed, l10n.teamSettingsFailed),
        const SizedBox(height: 16),
        TestId(
          TeamSettingsTestIds.save,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.teamSettingsSave),
          ),
        ),
        const Divider(height: 48),
        if (_actionFailed)
          error(TeamSettingsTestIds.actionFailed, l10n.teamActionFailed),
        if (!archived && offered(TeamSettingsPermissions.archive))
          TestId(
            TeamSettingsTestIds.archive,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.archive_outlined),
              label: Text(l10n.teamArchive),
              onPressed: _busy
                  ? null
                  : () => _teamAction(
                      TeamSettingsPermissions.archive,
                      l10n.teamArchiveTitle(name),
                      l10n.teamArchiveText,
                      (repo) => repo.archive(_id),
                      l10n.teamArchivedDone,
                    ),
            ),
          ),
        if (archived && offered(TeamSettingsPermissions.unarchive))
          TestId(
            TeamSettingsTestIds.unarchive,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.unarchive_outlined),
              label: Text(l10n.teamUnarchive),
              onPressed: _busy
                  ? null
                  : () => _teamAction(
                      TeamSettingsPermissions.unarchive,
                      l10n.teamUnarchiveTitle(name),
                      l10n.teamUnarchiveText,
                      (repo) => repo.unarchive(_id),
                      l10n.teamUnarchivedDone,
                    ),
            ),
          ),
        if (offered(TeamSettingsPermissions.destroy)) ...[
          const SizedBox(height: 12),
          TestId(
            TeamSettingsTestIds.delete,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: errorColor,
              ),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.teamDelete),
              onPressed: _busy
                  ? null
                  : () => _teamAction(
                      TeamSettingsPermissions.destroy,
                      l10n.teamDeleteTitle(name),
                      l10n.teamDeleteText,
                      (repo) => repo.deleteTeam(_id),
                      l10n.teamDeletedDone,
                      leaves: true,
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
