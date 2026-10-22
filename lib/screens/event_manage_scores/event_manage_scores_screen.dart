import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/common/events/models/event_match_models.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_manage_scores/event_manage_scores_test_ids.dart';

/// The matches of a game with their scores; tap one to enter or correct its
/// result (native `ScoresAddEditPicker`, one match at a time).
class EventManageScoresScreen extends ConsumerWidget {
  const EventManageScoresScreen({required this.eventId, super.key});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final eventAsync = ref.watch(eventDetailsViewModelProvider(eventId)).event;
    final event = eventAsync.value;
    final matches = [...?event?.eventMatches]
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    Widget tile(EventMatch m) {
      final summary = scoreSummary(m);
      final players = '${m.top?.label ?? ''} vs ${m.bottom?.label ?? ''}'
          .trim();
      return TestId(
        EventManageScoresTestIds.match(m.id ?? 0),
        child: ListTile(
          title: Text(
            [
              l10n.eventMatchNumber(m.order ?? 0),
              ref.refLabel(m.matchType, humanizeKey(m.matchType)),
              if (m.placeCourt?.name != null) m.placeCourt!.name!,
            ].join(' · '),
          ),
          subtitle: Text(
            '$players\n${summary.isEmpty ? l10n.eventScoreNone : summary}',
          ),
          isThreeLine: true,
          trailing: (m.unfinished ?? false)
              ? Chip(label: Text(l10n.eventScoreUnfinishedTag))
              : const Icon(Icons.chevron_right),
          onTap: m.id == null
              ? null
              : () =>
                    context.push(AppRoutes.eventManageScoreFor(eventId, m.id!)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          EventManageScoresTestIds.title,
          child: Semantics(header: true, child: Text(l10n.eventScoresTitle)),
        ),
      ),
      body: TestId(
        EventManageScoresTestIds.root,
        child: event == null
            ? Center(
                child: eventAsync.hasError
                    ? Text(l10n.eventLoadError)
                    : const CircularProgressIndicator(),
              )
            : matches.isEmpty
            ? Center(
                child: TestId(
                  EventManageScoresTestIds.empty,
                  child: Text(l10n.eventScoreNone),
                ),
              )
            : ListView(children: [for (final m in matches) tile(m)]),
      ),
    );
  }
}
