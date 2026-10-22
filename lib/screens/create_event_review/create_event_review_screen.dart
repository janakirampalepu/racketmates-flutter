import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/create_event/scoring.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_review/create_event_review_test_ids.dart';

/// Summary and the single `POST events` (native `EventReviewFragment`).
class CreateEventReviewScreen extends ConsumerWidget {
  const CreateEventReviewScreen({super.key});

  String? _serverMessage(AppFailure failure) => switch (failure) {
    ServerFailure(message: final m) when m != null && m.isNotEmpty => m,
    UnauthorizedFailure(message: final m) when m != null && m.isNotEmpty => m,
    _ => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final submission = ref.watch(createEventSubmitterProvider);
    final locale = Localizations.localeOf(context).toString();
    final start = draft.start;
    final when = start == null
        ? ''
        : '${DateFormat.yMMMEd(locale).format(start)}, ${DateFormat.jm(locale).format(start)} '
              '· ${l10n.createDurationValue(draft.durationMinutes)}';
    final typeLabel = ref.refLabel(
      draft.eventType,
      humanizeKey(draft.eventType),
    );

    return StepScaffold(
      rootId: CreateEventReviewTestIds.root,
      titleId: CreateEventReviewTestIds.title,
      title: l10n.createReviewTitle,
      primaryLabel: l10n.createEventAction,
      primaryId: CreateEventReviewTestIds.create,
      loading: submission.loading,
      onPrimary: () async {
        final ok = await ref
            .read(createEventSubmitterProvider.notifier)
            .submit();
        if (!ok || !context.mounted) return;
        final id = ref.read(createEventSubmitterProvider).createdEventId;
        context.go(AppRoutes.createEventSuccessFor(id));
      },
      onBack: () => context.pop(),
      children: [
        _Row(
          CreateEventReviewTestIds.summaryType,
          l10n.createReviewType,
          typeLabel,
        ),
        if (draft.sport != null)
          _Row(
            CreateEventReviewTestIds.summarySport,
            l10n.createReviewSport,
            sportLabel(l10n, draft.sport!),
          ),
        if (draft.forTeam == true && draft.team != null)
          _Row(
            CreateEventReviewTestIds.summaryTeam,
            l10n.createReviewTeam,
            draft.team?.name ?? '',
          ),
        _Row(CreateEventReviewTestIds.summaryWhen, l10n.createDateLabel, when),
        _Row(
          CreateEventReviewTestIds.summaryWhere,
          l10n.createVenueLabel,
          draft.place?.name ?? '',
        ),
        if (draft.coaches.isNotEmpty)
          _Row(
            CreateEventReviewTestIds.summaryCoaches,
            l10n.createReviewCoaches,
            draft.coaches.map((u) => u.displayName).join(', '),
          ),
        if (draft.spec?.usesScoring ?? false)
          _Row(
            CreateEventReviewTestIds.summaryScoring,
            l10n.createReviewScoring,
            _scoringText(ref, draft),
          ),
        if (draft.spec?.hasMatches ?? false)
          for (var i = 0; i < draft.matches.length; i++)
            _Row(
              CreateEventReviewTestIds.summaryMatch(i),
              l10n.createReviewMatchLine(
                i + 1,
                ref.refLabel(
                  draft.matches[i].matchType,
                  humanizeKey(draft.matches[i].matchType),
                ),
              ),
              draft.assignNow
                  ? _sides(draft.matches[i])
                  : l10n.createAssignLater,
            ),
        if (!draft.assignNow)
          _Row(
            CreateEventReviewTestIds.summaryInvited,
            l10n.createReviewInvited,
            draft.invitees.map((u) => u.displayName).join(', '),
          ),
        if (submission.failure != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TestId(
              CreateEventReviewTestIds.error,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _serverMessage(submission.failure!) ??
                      ref.msg(MessageKeys.errorGeneral, l10n.createFailed),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _scoringText(WidgetRef ref, EventDraft draft) {
  final scoring = draft.scoring;
  if (scoring == null) return '';
  final label = ref.refLabel(scoring.format, humanizeKey(scoring.format));
  return scoreInputFor(scoring.format) == ScoreInput.none
      ? label
      : '$label (${scoring.minimumScore})';
}

/// "Alex, Pat vs Sam, Lee" for a match with players in its spots.
String _sides(MatchDraft match) {
  String side(String key) => [
    for (final slot in match.slots)
      if (slot.side == key) match.players[slot]?.displayName ?? '?',
  ].join(', ');
  return '${side(MatchKeys.sideTop)} vs ${side(MatchKeys.sideBottom)}';
}

class _Row extends StatelessWidget {
  const _Row(this.id, this.label, this.value);

  final String id;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TestId(
      id,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value),
        ],
      ),
    ),
  );
}
