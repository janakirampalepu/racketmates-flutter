import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/manage_logic.dart';
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
  bool _unfinished = false;
  List<ScoreError> _errors = const [];

  @override
  void dispose() {
    for (final c in [...?_top, ...?_bottom]) {
      c.dispose();
    }
    super.dispose();
  }

  EventMatch? _match() {
    final event = ref
        .watch(eventDetailsViewModelProvider(widget.eventId))
        .event
        .value;
    for (final m in event?.eventMatches ?? const <EventMatch>[]) {
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
    _unfinished = match.unfinished ?? false;
  }

  List<SetScore> _sets() => [
    for (var i = 0; i < _top!.length; i++)
      (top: _top![i].text, bottom: _bottom![i].text),
  ];

  Future<void> _save(EventMatch match) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final errors = validateSetScores(_sets());
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    final ok = await ref
        .read(eventManageViewModelProvider(widget.eventId).notifier)
        .saveScores(match, _sets(), unfinished: _unfinished);
    if (!ok || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventManageSaved)));
    context.pop();
  }

  String _errorText(AppLocalizations l10n, ScoreError e) => switch (e) {
    ScoreError.noScores => l10n.eventScoreErrorNone,
    ScoreError.incompleteSet => l10n.eventScoreErrorIncomplete,
    ScoreError.notANumber => l10n.eventScoreErrorNumber,
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

    Widget body(EventMatch m) {
      final sets = _sets();
      final won = setsWon(sets);
      final single = sets.length == 1;
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
          for (var i = 0; i < sets.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      single
                          ? l10n.eventScoreSingle
                          : l10n.eventScoreSet(i + 1),
                    ),
                  ),
                  scoreField(
                    EventManageScoreEntryTestIds.top(i + 1),
                    _top![i],
                    l10n.eventScoreTop,
                  ),
                  const SizedBox(width: 12),
                  scoreField(
                    EventManageScoreEntryTestIds.bottom(i + 1),
                    _bottom![i],
                    l10n.eventScoreBottom,
                  ),
                ],
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
