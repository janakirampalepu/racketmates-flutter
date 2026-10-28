import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:racketmates/common/content/reference_data.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_edit.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_access.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

/// Who is ahead in the team (native `TeamMemberRankingFragment`): the
/// ranking of the members for one sport, over a period, for all matches or
/// only singles or doubles, plus entering points by hand for one player
/// (`POST team_players/{id}/team_player_points_histories`, gated the same
/// way editing a member's own record already is) and resetting the whole
/// sport's ranking (`PUT teams/{id}/reset_players_ranking`, gated the same
/// way team settings already is — neither permission key is confirmed
/// against a live backend; both are the closest existing match).
String _sportText(AppLocalizations l10n, String key) {
  final sport = SportKey.fromKey(key);
  return sport == null ? key : sportLabel(l10n, sport);
}

class TeamRankingsTab extends ConsumerStatefulWidget {
  const TeamRankingsTab({required this.team, super.key});

  final Team team;

  @override
  ConsumerState<TeamRankingsTab> createState() => _TeamRankingsTabState();
}

class _TeamRankingsTabState extends ConsumerState<TeamRankingsTab> {
  String? _sport;
  String? _period;
  String? _matchType; // null = all
  bool _busy = false;

  int get _teamId => widget.team.id ?? 0;

  AccessDecision _access(String key) => memberAccess(
    widget.team,
    key,
    subscribed: ref.read(sessionInfoControllerProvider).isSubscribed,
  );

  Future<void> _addPoints(TeamPlayer member, String sport) async {
    if (!await checkTeamAccess(
          context,
          ref,
          widget.team,
          TeamPermissions.updateMember,
        ) ||
        !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final points = await showDialog<int>(
      context: context,
      builder: (dialogContext) =>
          _PointsDialog(name: member.user?.displayName ?? ''),
    );
    if (points == null || !mounted) return;
    final teamPlayerId = member.id;
    if (teamPlayerId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(teamsRepositoryProvider)
          .addRankingPoints(
            teamPlayerId,
            earnedPoints: points,
            sportType: sport,
            matchType: _matchType,
          );
      ref.invalidate(teamRankingsProvider);
    } on AppFailure {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Text(
                l10n.teamRankingPointsFailed,
                key: const Key(TeamDetailsTestIds.rankingPointsFailed),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetRanking(String sport) async {
    if (!await checkTeamAccess(
          context,
          ref,
          widget.team,
          TeamSettingsPermissions.settings,
        ) ||
        !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.teamRankingResetTitle(_sportText(l10n, sport))),
            content: Text(l10n.teamRankingResetText),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.teamActionNo),
              ),
              TestId(
                TeamDetailsTestIds.rankingResetConfirmYes,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.teamActionYes),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(teamsRepositoryProvider)
          .resetRanking(_teamId, sportType: sport);
      ref.invalidate(teamRankingsProvider);
    } on AppFailure {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Text(
                l10n.teamRankingResetFailed,
                key: const Key(TeamDetailsTestIds.rankingResetFailed),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final team = widget.team;
    if (!(team.enablePlayerRanking ?? false)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: TestId(
            TeamDetailsTestIds.rankingsOff,
            child: Text(l10n.teamRankingsOff, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    final reference = ref.watch(referenceDataProvider);
    final periods = reference.ofType(ReferenceTypes.rankingPeriodDuration);
    final matchTypes = [
      for (final i in reference.ofType(ReferenceTypes.matchType))
        if (i.key == 'mt_singles' || i.key == 'mt_doubles') i,
    ];
    final sports = team.sportKeys;
    final sport = _sport ?? (sports.isEmpty ? null : sports.first);
    final period = _period ?? periods.firstOrNull?.key;
    final n = context.native;
    final canAddPoints =
        _access(TeamPermissions.updateMember) != AccessDecision.hidden;
    final canReset =
        _access(TeamSettingsPermissions.settings) != AccessDecision.hidden;

    Widget table() {
      if (sport == null) {
        return Center(
          child: TestId(
            TeamDetailsTestIds.rankingsEmpty,
            child: Text(l10n.teamRankingsEmpty),
          ),
        );
      }
      final args = (
        teamId: team.id ?? 0,
        sport: sport,
        period: period,
        matchType: _matchType,
      );
      return ref
          .watch(teamRankingsProvider(args))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TestId(
                    TeamDetailsTestIds.rankingsError,
                    child: Text(l10n.teamRankingsLoadError),
                  ),
                  TestId(
                    TeamDetailsTestIds.rankingsRetry,
                    child: TextButton(
                      onPressed: () =>
                          ref.invalidate(teamRankingsProvider(args)),
                      child: Text(l10n.retryAction),
                    ),
                  ),
                ],
              ),
            ),
            data: (list) => list.isEmpty
                ? Center(
                    child: TestId(
                      TeamDetailsTestIds.rankingsEmpty,
                      child: Text(l10n.teamRankingsEmpty),
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final m = list[i];
                      final rank = m.currentRank ?? i + 1;
                      final change = rankChange(m);
                      return TestId(
                        TeamDetailsTestIds.rankingRow(m.id ?? i),
                        child: MergeSemantics(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Semantics(
                                label: l10n.teamRankingRank(rank),
                                child: Text('$rank'),
                              ),
                            ),
                            title: Text(m.user?.displayName ?? ''),
                            subtitle: Text(
                              '${l10n.teamRankingRecord(m.wins ?? 0, m.losses ?? 0)}'
                              ' · ${l10n.teamRankingPoints(m.totalPoints ?? 0)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (change != null && change != 0)
                                  Semantics(
                                    label: change > 0
                                        ? l10n.teamRankingUp(change)
                                        : l10n.teamRankingDown(-change),
                                    child: Icon(
                                      change > 0
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      // Native-matching status colors (the
                                      // same ones the activity card uses
                                      // for wins/losses), not a generic
                                      // Material color scheme.
                                      color: change > 0
                                          ? n.statusColorsLightGreen
                                          : n.statusColorsLightRed,
                                    ),
                                  ),
                                if (canAddPoints)
                                  TestId(
                                    TeamDetailsTestIds.rankingAddPoints(
                                      m.id ?? i,
                                    ),
                                    child: IconButton(
                                      tooltip: l10n.teamRankingAddPoints,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: _busy
                                          ? null
                                          : () => _addPoints(m, sport),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (sports.length > 1)
                for (final key in sports)
                  TestId(
                    TeamDetailsTestIds.rankingSport(key),
                    child: ChoiceChip(
                      label: Text(_sportText(l10n, key)),
                      selected: key == sport,
                      onSelected: (_) => setState(() => _sport = key),
                    ),
                  ),
              if (periods.isNotEmpty)
                TestId(
                  TeamDetailsTestIds.rankingsPeriod,
                  child: DropdownButton<String>(
                    value: period,
                    hint: Text(l10n.teamRankingPeriod),
                    items: [
                      for (final p in periods)
                        if (p.key != null)
                          DropdownMenuItem(
                            value: p.key,
                            child: Text(p.localizedLabel ?? p.key!),
                          ),
                    ],
                    onChanged: (v) => setState(() => _period = v),
                  ),
                ),
              if (matchTypes.isNotEmpty) ...[
                TestId(
                  TeamDetailsTestIds.rankingMatch('all'),
                  child: ChoiceChip(
                    label: Text(l10n.teamRankingAllMatches),
                    selected: _matchType == null,
                    onSelected: (_) => setState(() => _matchType = null),
                  ),
                ),
                for (final m in matchTypes)
                  TestId(
                    TeamDetailsTestIds.rankingMatch(m.key!),
                    child: ChoiceChip(
                      label: Text(m.localizedLabel ?? m.key!),
                      selected: _matchType == m.key,
                      onSelected: (_) => setState(() => _matchType = m.key),
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (sport != null && canReset)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TestId(
                TeamDetailsTestIds.rankingReset,
                child: TextButton.icon(
                  onPressed: _busy ? null : () => _resetRanking(sport),
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.teamRankingReset),
                ),
              ),
            ),
          ),
        Expanded(child: table()),
      ],
    );
  }
}

/// The "add points" dialog's own `StatefulWidget` (its `TextEditingController`
/// must own its own dispose lifecycle — disposing it right after `showDialog`
/// returns crashes during the dialog's close animation, a gotcha already
/// documented elsewhere in this app).
class _PointsDialog extends StatefulWidget {
  const _PointsDialog({required this.name});

  final String name;

  @override
  State<_PointsDialog> createState() => _PointsDialogState();
}

class _PointsDialogState extends State<_PointsDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.teamRankingAddPointsTitle(widget.name)),
      content: TestId(
        TeamDetailsTestIds.rankingPointsDialog,
        child: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.teamRankingPointsLabel,
            errorText: _error,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.teamActionNo),
        ),
        TestId(
          TeamDetailsTestIds.rankingPointsSave,
          child: FilledButton(
            onPressed: () {
              final value = int.tryParse(_controller.text.trim());
              if (value == null) {
                setState(() => _error = l10n.teamRankingPointsRequired);
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: Text(l10n.teamSettingsSave),
          ),
        ),
      ],
    );
  }
}
