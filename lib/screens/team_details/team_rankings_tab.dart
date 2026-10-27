import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:racketmates/common/content/reference_data.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/teams/member_rules.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_providers.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';

/// Who is ahead in the team (native `TeamMemberRankingFragment`): the ranking
/// of the members for one sport, over a period, for all matches or only
/// singles or doubles. Entering points by hand and resetting the ranking are
/// not part of this build.
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
                            trailing: change == null || change == 0
                                ? null
                                : Semantics(
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
        Expanded(child: table()),
      ],
    );
  }
}
