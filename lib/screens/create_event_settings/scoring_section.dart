import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/scoring.dart';
import 'package:racketmates/common/create_event/scoring_formats_provider.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/widgets/number_stepper.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_settings/create_event_settings_test_ids.dart';

/// Scoring format of a game or round robin (native `ScoringFormatPicker`):
/// the formats the server offers for the sport and event type, the minimum
/// score of the chosen format and, for tennis and padel, how a tied last set
/// is decided. The first format is chosen when the list arrives.
class ScoringSection extends ConsumerWidget {
  const ScoringSection({required this.draft, super.key});

  final EventDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sport = draft.sport;
    final type = draft.eventType;
    if (sport == null || type == null) return const SizedBox.shrink();
    final args = (sport: sport.key, eventType: type);
    final formats = ref.watch(scoringFormatsProvider(args));
    final flow = ref.read(createEventFlowProvider.notifier);
    final references = ref.watch(referenceDataProvider);
    final scoring = draft.scoring;

    String label(String key, String fallback) =>
        references.label(key) ?? fallback;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            ref.msg(MessageKeys.createScoringTitle, l10n.createScoringTitle),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Text(ref.msg(MessageKeys.createScoringHint, l10n.createScoringHint)),
        const SizedBox(height: 8),
        formats.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: TestId(
                CreateEventSettingsTestIds.scoringLoading,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TestId(
                CreateEventSettingsTestIds.scoringError,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.createScoringLoadError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
              TestId(
                CreateEventSettingsTestIds.scoringRetry,
                child: TextButton(
                  onPressed: () => ref.invalidate(scoringFormatsProvider(args)),
                  child: Text(l10n.retryAction),
                ),
              ),
            ],
          ),
          data: (response) {
            final keys = response.scoringFormatKeys ?? const <String>[];
            final minimums = response.minimumScores ?? const <String, num?>{};
            if (keys.isNotEmpty &&
                (scoring == null || !keys.contains(scoring.format))) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final current = ref.read(createEventFlowProvider)?.scoring;
                if (current == null || !keys.contains(current.format)) {
                  flow.setScoringFormat(keys.first, minimums);
                }
              });
            }
            return RadioGroup<String>(
              groupValue: scoring?.format,
              onChanged: (v) {
                if (v != null) flow.setScoringFormat(v, minimums);
              },
              child: Column(
                children: [
                  for (final key in keys) ...[
                    TestId(
                      CreateEventSettingsTestIds.format(key),
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: key,
                        title: Text(label(key, humanizeKey(key))),
                        subtitle: references.subText(key) == null
                            ? null
                            : Text(references.subText(key)!),
                      ),
                    ),
                    if (scoring?.format == key)
                      _FormatOptions(
                        scoring: scoring!,
                        sport: sport,
                        label: label,
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FormatOptions extends ConsumerWidget {
  const _FormatOptions({
    required this.scoring,
    required this.sport,
    required this.label,
  });

  final ScoringChoice scoring;
  final SportKey sport;
  final String Function(String key, String fallback) label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final flow = ref.read(createEventFlowProvider.notifier);
    final input = scoreInputFor(scoring.format);
    final scoreLabel = switch (scoring.format) {
      ScoringKeys.reachPoints => l10n.createScorePointsToWin,
      ScoringKeys.totalPoints => l10n.createScoreTotalPoints,
      ScoringKeys.timeBased => l10n.createScoreDuration,
      _ =>
        canChooseDecidingSet(sport)
            ? ref.msg(
                MessageKeys.createScoreGamesToWin,
                l10n.createScoreGamesToWin,
              )
            : ref.msg(
                MessageKeys.createScoreMinimumPoints,
                l10n.createScoreMinimumPoints,
              ),
    };
    final decidingLabels = {
      ScoringKeys.regularSet: label(
        ScoringKeys.regularSet,
        l10n.createDecidingRegular,
      ),
      ScoringKeys.tieBreak: label(
        ScoringKeys.tieBreak,
        l10n.createDecidingTieBreak,
      ),
      ScoringKeys.decideLater: label(
        ScoringKeys.decideLater,
        l10n.createDecidingLater,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (input == ScoreInput.number)
            Row(
              children: [
                Expanded(child: Text(scoreLabel)),
                NumberStepper(
                  idPrefix: CreateEventSettingsTestIds.scoreIdPrefix,
                  label: scoreLabel,
                  decreaseLabel: l10n.createDecrease,
                  increaseLabel: l10n.createIncrease,
                  value: scoring.minimumScore,
                  onChanged: flow.setMinimumScore,
                ),
              ],
            ),
          if (input == ScoreInput.minutes)
            TestId(
              CreateEventSettingsTestIds.scoreMinutes,
              child: DropdownButtonFormField<int>(
                initialValue: scoring.minimumScore,
                decoration: InputDecoration(
                  labelText: scoreLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (
                    var m = timeBasedMinMinutes;
                    m <= timeBasedMaxMinutes;
                    m += timeBasedStepMinutes
                  )
                    DropdownMenuItem(
                      value: m,
                      child: Text(l10n.createScoreMinutes(m)),
                    ),
                ],
                onChanged: (m) {
                  if (m != null) flow.setMinimumScore(m);
                },
              ),
            ),
          if (input == ScoreInput.none && canChooseDecidingSet(sport)) ...[
            Text(l10n.createDecidingSetLabel),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final key in ScoringKeys.decidingSetTypes)
                  ButtonSegment(
                    value: key,
                    label: TestId(
                      CreateEventSettingsTestIds.decidingSet(key),
                      child: Text(decidingLabels[key]!),
                    ),
                  ),
              ],
              selected: {scoring.decidingSetType},
              onSelectionChanged: (s) => flow.setDecidingSetType(s.first),
            ),
          ],
        ],
      ),
    );
  }
}
