import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/widgets/number_stepper.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_settings/create_event_settings_test_ids.dart';
import 'package:racketmates/screens/create_event_settings/scoring_section.dart';

/// General settings (native `GenerelSettingsFragment`): response deadline
/// (hours 1-23 / days 1-7), whether participants can manage players and, for
/// games and round robins, whether players can log results and the scoring
/// format. Coach and audience switches do not apply to the types built so far.
class CreateEventSettingsScreen extends ConsumerWidget {
  const CreateEventSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    final hours = draft.attendanceUnitType == attendanceUnitHours;
    final unitLabel = hours
        ? ref.refLabel(attendanceUnitHours, l10n.createUnitHours)
        : ref.refLabel(attendanceUnitDays, l10n.createUnitDays);
    final scored = draft.spec?.usesScoring ?? false;
    return StepScaffold(
      rootId: CreateEventSettingsTestIds.root,
      titleId: CreateEventSettingsTestIds.title,
      title: ref.msg(MessageKeys.createSettingsTitle, l10n.createSettingsTitle),
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventSettingsTestIds.next,
      // Scored events need a scoring format before they can continue.
      onPrimary: scored && draft.scoring == null
          ? null
          : () {
              final next = flow.next(CreateEventStep.settings)!;
              context.push(AppRoutes.routeForStep(next));
            },
      onBack: () => context.pop(),
      children: [
        Semantics(
          header: true,
          child: Text(
            ref.msg(MessageKeys.createDeadlineTitle, l10n.createDeadlineLabel),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Text(l10n.createDeadlineHint),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: attendanceUnitHours,
              label: TestId(
                CreateEventSettingsTestIds.unitHours,
                child: Text(
                  ref.refLabel(attendanceUnitHours, l10n.createUnitHours),
                ),
              ),
            ),
            ButtonSegment(
              value: attendanceUnitDays,
              label: TestId(
                CreateEventSettingsTestIds.unitDays,
                child: Text(
                  ref.refLabel(attendanceUnitDays, l10n.createUnitDays),
                ),
              ),
            ),
          ],
          selected: {draft.attendanceUnitType},
          onSelectionChanged: (s) => flow.setAttendanceType(s.first),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            NumberStepper(
              idPrefix: 'create_event_deadline',
              label: l10n.createDeadlineLabel,
              decreaseLabel: l10n.createDecrease,
              increaseLabel: l10n.createIncrease,
              value: draft.attendanceUnit,
              max: draft.maxAttendanceUnit,
              onChanged: flow.setAttendanceUnit,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TestId(
                CreateEventSettingsTestIds.deadlineValue,
                child: Text(
                  l10n.createDeadlineValue(
                    '${draft.attendanceUnit} $unitLabel',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TestId(
          CreateEventSettingsTestIds.allowManage,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.createAllowManageLabel),
            value: draft.allowParticipantsManagePlayers,
            onChanged: (v) => flow.setAllowManage(value: v),
          ),
        ),
        if (draft.forTeam == true && (draft.spec?.isRoundRobin ?? false))
          TestId(
            CreateEventSettingsTestIds.considerRanking,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.createRankingLabel),
              value: draft.considerForTeamRanking,
              onChanged: (v) => flow.setConsiderForTeamRanking(value: v),
            ),
          ),
        if (scored) ...[
          TestId(
            CreateEventSettingsTestIds.allowLogResults,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.createLogResultsLabel),
              value: draft.allowParticipantsToLogResults,
              onChanged: (v) => flow.setAllowLogResults(value: v),
            ),
          ),
          const SizedBox(height: 16),
          ScoringSection(draft: draft),
        ],
      ],
    );
  }
}
