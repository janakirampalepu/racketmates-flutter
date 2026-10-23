import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/create_event/scoring.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/models/event_match_models.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_manage/event_manage_view_model.dart';
import 'package:racketmates/screens/event_manage_score_entry/event_manage_score_entry_test_ids.dart';

/// Enter or correct the score of one match: a row per set for the match's
/// scoring format, plus "match not finished". The server applies the sport's
/// own rules and its message is shown when it rejects a score.
class EventManageScoreEntryScreen extends ConsumerStatefulWidget {
  const EventManageScoreEntryScreen({
    required this.eventId,
    required this.matchId,
    super.key,
  });

  final int eventId;
  final int matchId;

  @override
  ConsumerState<EventManageScoreEntryScreen> createState() =>
      _EventManageScoreEntryScreenState();
}

class _EventManageScoreEntryScreenState
    extends ConsumerState<EventManageScoreEntryScreen> {
  List<TextEditingController>? _top;
  List<TextEditingController>? _bottom;
  final List<TextEditingController> _tbTop = [];
  final List<TextEditingController> _tbBottom = [];
  TextEditingController? _mtbTop;
  TextEditingController? _mtbBottom;
  String? _deciding;

  /// The sets and set tie-breaks the match had when the screen opened: a set
  /// recorded as 7-6 with a tie-break keeps showing it until it is changed.
  List<SetScore> _initialSets = const [];
  TieBreaks _initialTieBreaks = const {};
  bool _unfinished = false;
  List<ScoreError> _errors = const [];

  @override
  void dispose() {
    for (final c in [
      ...?_top,
      ...?_bottom,
      ..._tbTop,
      ..._tbBottom,
      ?_mtbTop,
      ?_mtbBottom,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  EventDetails? _event() =>
      ref.watch(eventDetailsViewModelProvider(widget.eventId)).event.value;

  EventMatch? _match() {
    for (final m in _event()?.eventMatches ?? const <EventMatch>[]) {
      if (m.id == widget.matchId) return m;
    }
    return null;
  }

  /// Fills the fields from the match the first time it is available.
  void _init(EventMatch match) {
    if (_top != null) return;
    final sets = prefillSets(match);
    _top = [for (final s in sets) TextEditingController(text: s.top)];
    _bottom = [for (final s in sets) TextEditingController(text: s.bottom)];
    final tieBreaks = prefillTieBreaks(match);
    _initialSets = sets;
    _initialTieBreaks = tieBreaks;
    for (var i = 1; i <= 5; i++) {
      _tbTop.add(TextEditingController(text: tieBreaks[i]?.top ?? ''));
      _tbBottom.add(TextEditingController(text: tieBreaks[i]?.bottom ?? ''));
    }
    final mtb = prefillMatchTieBreak(match);
    _mtbTop = TextEditingController(text: mtb?.top ?? '');
    _mtbBottom = TextEditingController(text: mtb?.bottom ?? '');
    _deciding = mtb != null ? ScoringKeys.tieBreak : match.decidingSetType;
    _unfinished = match.unfinished ?? false;
  }

  List<SetScore> _sets() => [
    for (var i = 0; i < _top!.length; i++)
      (top: _top![i].text, bottom: _bottom![i].text),
  ];

  TieBreaks _tieBreaks() => {
    for (var i = 0; i < _tbTop.length; i++)
      if (_tbTop[i].text.isNotEmpty || _tbBottom[i].text.isNotEmpty)
        i + 1: (top: _tbTop[i].text, bottom: _tbBottom[i].text),
  };

  SetScore _mtb() => (top: _mtbTop!.text, bottom: _mtbBottom!.text);

  ScoreLayout _layout(EventMatch match, EventDetails? event) => scoreLayout(
    format: match.scoringFormat,
    sportType: event?.sportType,
    decidingSetType: _deciding,
    sets: _sets(),
    tieBreaks: _tieBreaks(),
  );

  /// Whether set [index] (0-based) shows its tie-break: it is level at the
  /// minimum score, or it is still the set the server recorded with one.
  bool _tieBreakShown(
    int index,
    SetScore set,
    EventMatch match,
    EventDetails? event,
  ) =>
      needsSetTieBreak(
        set,
        allow: allowsTieBreak(event?.sportType),
        minimum: match.minimumScoreToWin ?? 0,
      ) ||
      (_initialTieBreaks.containsKey(index + 1) &&
          index < _initialSets.length &&
          _initialSets[index] == set);

  /// The tie-breaks to send: only those of sets that show one.
  TieBreaks _neededTieBreaks(
    List<SetScore> visible,
    EventMatch match,
    EventDetails? event,
  ) {
    final all = _tieBreaks();
    return {
      for (var i = 0; i < visible.length; i++)
        if (all[i + 1] != null && _tieBreakShown(i, visible[i], match, event))
          i + 1: all[i + 1]!,
    };
  }

  Future<void> _save(EventMatch match) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final event = _event();
    final layout = _layout(match, event);
    final visible = _sets().take(layout.setRows).toList();
    final tieBreaks = _neededTieBreaks(visible, match, event);
    final mtb = layout.matchTieBreakRow ? _mtb() : null;
    final level = setsWon(visible, tieBreaks: tieBreaks);
    final errors = {
      ...validateSetScores(visible),
      ...validateTieBreaks(
        visible,
        tieBreaks: tieBreaks,
        matchTieBreak: mtb,
        allow: allowsTieBreak(event?.sportType),
        minimum: match.minimumScoreToWin ?? 0,
        matchTieBreakNeeded: level.top == level.bottom,
      ),
    }.toList();
    // A match tie-break alone is no score; the sets decide that.
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    final ok = await ref
        .read(eventManageViewModelProvider(widget.eventId).notifier)
        .saveScores(
          match,
          visible,
          unfinished: _unfinished,
          tieBreaks: tieBreaks,
          matchTieBreak: mtb,
          decidingSetType: _deciding,
        );
    if (!ok || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventManageSaved)));
    context.pop();
  }

  String _errorText(AppLocalizations l10n, ScoreError e) => switch (e) {
    ScoreError.noScores => l10n.eventScoreErrorNone,
    ScoreError.incompleteSet => l10n.eventScoreErrorIncomplete,
    ScoreError.notANumber => l10n.eventScoreErrorNumber,
    ScoreError.tieBreakDrawn => l10n.eventScoreErrorTieBreak,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final match = _match();
    final manage = ref.watch(eventManageViewModelProvider(widget.eventId));
    if (match != null) _init(match);

    Widget scoreField(String id, TextEditingController c, String label) =>
        SizedBox(
          width: 88,
          child: TestId(
            id,
            child: TextField(
              controller: c,
              enabled: !manage.busy,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _errors = const []),
            ),
          ),
        );

    Widget pair({
      required String topId,
      required String bottomId,
      required TextEditingController top,
      required TextEditingController bottom,
    }) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        scoreField(topId, top, l10n.eventScoreTop),
        const SizedBox(width: 12),
        scoreField(bottomId, bottom, l10n.eventScoreBottom),
      ],
    );

    Widget row(String label, Widget fields) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          fields,
        ],
      ),
    );

    Widget body(EventMatch m) {
      final event = _event();
      final layout = _layout(m, event);
      final allSets = _sets();
      final visible = allSets.take(layout.setRows).toList();
      final tieBreaks = _neededTieBreaks(visible, m, event);
      final won = setsWon(
        visible,
        tieBreaks: tieBreaks,
        matchTieBreak: layout.matchTieBreakRow ? _mtb() : null,
      );
      final single = allSets.length == 1;
      final canSave = m.top?.id != null && m.bottom?.id != null && !manage.busy;
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            l10n.eventMatchNumber(m.order ?? 0),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('${l10n.eventScoreTop}: ${m.top?.label ?? ''}'),
          Text('${l10n.eventScoreBottom}: ${m.bottom?.label ?? ''}'),
          const SizedBox(height: 16),
          for (var i = 0; i < layout.setRows; i++) ...[
            row(
              single ? l10n.eventScoreSingle : l10n.eventScoreSet(i + 1),
              pair(
                topId: EventManageScoreEntryTestIds.top(i + 1),
                bottomId: EventManageScoreEntryTestIds.bottom(i + 1),
                top: _top![i],
                bottom: _bottom![i],
              ),
            ),
            if (_tieBreakShown(i, visible[i], m, event))
              row(
                l10n.eventScoreTieBreak(i + 1),
                pair(
                  topId: EventManageScoreEntryTestIds.tieBreakTop(i + 1),
                  bottomId: EventManageScoreEntryTestIds.tieBreakBottom(i + 1),
                  top: _tbTop[i],
                  bottom: _tbBottom[i],
                ),
              ),
          ],
          if (layout.matchTieBreakRow)
            row(
              l10n.eventScoreMatchTieBreak,
              pair(
                topId: EventManageScoreEntryTestIds.matchTieBreakTop,
                bottomId: EventManageScoreEntryTestIds.matchTieBreakBottom,
                top: _mtbTop!,
                bottom: _mtbBottom!,
              ),
            ),
          if (layout.askDecidingSet)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TestId(
                EventManageScoreEntryTestIds.decidingPrompt,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.eventScoreDecidingPrompt),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final key in const [
                              ScoringKeys.regularSet,
                              ScoringKeys.tieBreak,
                            ])
                              TestId(
                                EventManageScoreEntryTestIds.deciding(key),
                                child: OutlinedButton(
                                  onPressed: manage.busy
                                      ? null
                                      : () => setState(() => _deciding = key),
                                  child: Text(
                                    key == ScoringKeys.tieBreak
                                        ? l10n.createDecidingTieBreak
                                        : l10n.createDecidingRegular,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!single)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TestId(
                EventManageScoreEntryTestIds.winning,
                child: Text(l10n.eventScoreWinning(won.top, won.bottom)),
              ),
            ),
          TestId(
            EventManageScoreEntryTestIds.unfinished,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.eventScoreUnfinished),
              value: _unfinished,
              onChanged: manage.busy
                  ? null
                  : (v) => setState(() => _unfinished = v),
            ),
          ),
          if (m.unfinished ?? false)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TestId(
                EventManageScoreEntryTestIds.clearUnfinished,
                child: TextButton(
                  onPressed: manage.busy
                      ? null
                      : () async {
                          final ok = await ref
                              .read(
                                eventManageViewModelProvider(widget.eventId)
                                    .notifier,
                              )
                              .clearUnfinished(m);
                          if (ok && mounted) {
                            setState(() => _unfinished = false);
                          }
                        },
                  child: Text(l10n.eventScoreClearUnfinished),
                ),
              ),
            ),
          if (_errors.isNotEmpty || manage.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TestId(
                EventManageScoreEntryTestIds.error,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _errors.isNotEmpty
                        ? _errorText(l10n, _errors.first)
                        : manage.error!.isEmpty
                        ? l10n.eventManageFailed
                        : manage.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          TestId(
            EventManageScoreEntryTestIds.save,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: canSave ? () => _save(m) : null,
              child: manage.busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.eventScoreSave),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          EventManageScoreEntryTestIds.title,
          child: Semantics(
            header: true,
            child: Text(l10n.eventScoreEntryTitle),
          ),
        ),
      ),
      body: TestId(
        EventManageScoreEntryTestIds.root,
        child: SafeArea(
          child: match == null
              ? const Center(child: CircularProgressIndicator())
              : body(match),
        ),
      ),
    );
  }
}
