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
import 'package:racketmates/common/widgets/load_error_body.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
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
  ConsumerState<TeamRankingsTab> createState() => TeamRankingsTabState();
}

/// Public so the hosting screen's `AppBar` (native puts "Reset ranking" in
/// the toolbar's own overflow menu, top-right — not inline with the
/// filters) can reach [openActionsSheet] through a `GlobalKey`.
class TeamRankingsTabState extends ConsumerState<TeamRankingsTab> {
  String? _sport;
  String? _period;
  // Native only offers Singles/Doubles here — no "All" option on either
  // platform (Android's `llMatchTypePreference` is a plain two-way
  // toggle; iOS's `MatchType` enum has no all-matches case either) — so
  // this always resolves to one of the two, defaulting to doubles like
  // both native apps, never left as a null "all" selection.
  String? _matchType;
  bool _busy = false;
  // Cached each build so the AppBar's action (outside this widget) can
  // reset whichever sport is currently selected.
  String? _resolvedSport;

  int get _teamId => widget.team.id ?? 0;

  AccessDecision _access(String key) => memberAccess(
    widget.team,
    key,
    subscribed: ref.read(sessionInfoControllerProvider).isSubscribed,
  );

  Future<void> _addPoints(
    TeamPlayer member,
    String sport,
    String? matchType,
  ) async {
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
            matchType: matchType,
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

  /// "Reset ranking" (native's toolbar/overflow "other actions" menu) —
  /// called from the hosting screen's `AppBar` action, top-right, not from
  /// an icon inline with the filter row.
  Future<void> openActionsSheet() async {
    final sport = _resolvedSport;
    if (sport == null) return;
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      // `SafeArea` alone can still leave the sheet's last row under the
      // system nav bar on some devices — add the inset explicitly too,
      // the same fix already applied to the Settings screen's scrollable
      // content and the Team Settings overflow sheet.
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: SafeArea(
          bottom: false,
          child: TestId(
            TeamDetailsTestIds.rankingReset,
            child: ListTile(
              leading: const Icon(Icons.restart_alt),
              title: Text(l10n.teamRankingReset),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _resetRanking(sport);
              },
            ),
          ),
        ),
      ),
    );
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
    final defaultMatchType = matchTypes
        .firstWhere(
          (m) => m.key == 'mt_doubles',
          orElse: () => matchTypes.firstOrNull ?? const ReferenceItem(),
        )
        .key;
    final matchType = _matchType ?? defaultMatchType;
    final n = context.native;
    final canAddPoints =
        _access(TeamPermissions.updateMember) != AccessDecision.hidden;
    _resolvedSport = sport;

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
        matchType: matchType,
      );
      return ref
          .watch(teamRankingsProvider(args))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: LoadErrorBody(
                error: error,
                fallbackText: l10n.teamRankingsLoadError,
                retryId: TeamDetailsTestIds.rankingsRetry,
                onRetry: () => ref.invalidate(teamRankingsProvider(args)),
                errorTestId: TeamDetailsTestIds.rankingsError,
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
                      final name = m.user?.displayName ?? '';
                      final initial = name.trim().isEmpty
                          ? ''
                          : name.trim()[0].toUpperCase();
                      return TestId(
                        TeamDetailsTestIds.rankingRow(m.id ?? i),
                        child: MergeSemantics(
                          child: ListTile(
                            // Native shows a rank number alongside a real
                            // photo/initials avatar for each member, not a
                            // number standing in as the avatar itself.
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: context.sdp(20),
                                  child: Semantics(
                                    label: l10n.teamRankingRank(rank),
                                    child: Text(
                                      '$rank',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: n.textSecondary),
                                    ),
                                  ),
                                ),
                                SizedBox(width: context.sdp(8)),
                                CircleAvatar(
                                  radius: context.sdp(18),
                                  backgroundColor: n.avatarBgColor,
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      color: n.imagePrimeryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(name),
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
                                          : () =>
                                                _addPoints(m, sport, matchType),
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

    // Native shows neither of these as chips or an inline Material
    // dropdown: both the sport and the period are a single bordered pill
    // button (icon/text + a trailing chevron) that opens a bottom-sheet
    // list of every option (Android's `SelectSportPicker`/
    // `SelectPeriodPicker`, iOS's `SelectSportSheetView`/
    // `SelectPeriodSheetView`) — only the Singles/Doubles match type is a
    // real two-chip toggle row on both platforms.
    Future<void> openSportPicker() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _FilterPickerSheet(
        title: l10n.teamRankingSport,
        children: [
          for (final key in sports)
            TestId(
              TeamDetailsTestIds.rankingSport(key),
              child: _FilterOptionRow(
                icon: SportKey.fromKey(key) == null
                    ? null
                    : sportIconName(SportKey.fromKey(key)!),
                label: _sportText(l10n, key),
                selected: key == sport,
                onTap: () {
                  setState(() => _sport = key);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
        ],
      ),
    );

    Future<void> openPeriodPicker() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _FilterPickerSheet(
        title: l10n.teamRankingPeriod,
        children: [
          for (final p in periods)
            if (p.key != null)
              TestId(
                TeamDetailsTestIds.rankingPeriod(p.key!),
                child: _FilterOptionRow(
                  label: p.localizedLabel ?? p.key!,
                  selected: p.key == period,
                  onTap: () {
                    setState(() => _period = p.key);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
        ],
      ),
    );

    String? periodLabelFor(String? key) {
      for (final p in periods) {
        if (p.key == key) return p.localizedLabel ?? p.key;
      }
      return null;
    }

    final periodLabel = periodLabelFor(period) ?? l10n.teamRankingPeriod;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              if (sports.length > 1)
                TestId(
                  TeamDetailsTestIds.rankingSportButton,
                  child: _FilterPillButton(
                    icon: SportKey.fromKey(sport ?? '') == null
                        ? null
                        : sportIconName(SportKey.fromKey(sport!)!),
                    label: sport == null
                        ? l10n.teamRankingSport
                        : _sportText(l10n, sport),
                    bold: true,
                    onTap: openSportPicker,
                  ),
                ),
              Expanded(child: SizedBox(width: context.sdp(8))),
              if (periods.isNotEmpty)
                TestId(
                  TeamDetailsTestIds.rankingsPeriod,
                  child: _FilterPillButton(
                    label: periodLabel,
                    onTap: openPeriodPicker,
                  ),
                ),
            ],
          ),
        ),
        if (matchTypes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                // No "All" chip — native only ever offers Singles/Doubles
                // here (a two-way toggle on both platforms).
                for (final m in matchTypes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TestId(
                      TeamDetailsTestIds.rankingMatch(m.key!),
                      child: ChoiceChip(
                        label: Text(m.localizedLabel ?? m.key!),
                        selected: matchType == m.key,
                        onSelected: (_) => setState(() => _matchType = m.key),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(child: table()),
      ],
    );
  }
}

/// The sport/period selector button (native `tvSportName`/`sportSelector`,
/// `tvDateFilter`/`periodSelector`): a bordered pill with optional leading
/// icon, the current value, and a trailing dropdown chevron — not a chip
/// row or a Material `DropdownButton`.
class _FilterPillButton extends StatelessWidget {
  const _FilterPillButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.bold = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? icon;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(sdp(8)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sdp(12), vertical: sdp(8)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(sdp(8)),
          border: Border.all(color: n.borderSolidPrimary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              SvgIcon(icon!, size: sdp(18), color: n.imagePrimeryColor),
              SizedBox(width: sdp(6)),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: n.textPrimary,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: n.textPrimary, size: sdp(20)),
          ],
        ),
      ),
    );
  }
}

/// A bottom-sheet list used by both the sport and period pickers (native's
/// `SelectSportPicker`/`SelectPeriodPicker`/`SelectSportSheetView`/
/// `SelectPeriodSheetView`): a title and one row per option.
class _FilterPickerSheet extends StatelessWidget {
  const _FilterPickerSheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(sdp(16), sdp(16), sdp(16), sdp(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: n.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: sdp(16),
                ),
              ),
              SizedBox(height: sdp(8)),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// One row inside [_FilterPickerSheet]: an optional sport icon, the label,
/// and a check mark when selected.
class _FilterOptionRow extends StatelessWidget {
  const _FilterOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sdp(12)),
        child: Row(
          children: [
            if (icon != null) ...[
              SvgIcon(icon!, size: sdp(20), color: n.imagePrimeryColor),
              SizedBox(width: sdp(12)),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: n.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check, color: n.imagePrimeryColor, size: sdp(20)),
          ],
        ),
      ),
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
