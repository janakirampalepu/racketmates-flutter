import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/scoring.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/widgets/number_stepper.dart';
import 'package:racketmates/common/widgets/scoring_picker.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_manage/event_manage_view_model.dart';
import 'package:racketmates/screens/event_manage_settings/event_manage_settings_test_ids.dart';

/// Change an event's settings (native `ManageGeneralSettingsFragment` and the
/// invite settings of the update flow): response deadline, who can manage
/// players, limits and acceptance, and for scored events the results switch
/// and scoring format. A played event is read only.
class EventManageSettingsScreen extends ConsumerStatefulWidget {
  const EventManageSettingsScreen({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<EventManageSettingsScreen> createState() =>
      _EventManageSettingsScreenState();
}

class _EventManageSettingsScreenState
    extends ConsumerState<EventManageSettingsScreen> {
  EventSettingsEdit? _edit;

  Future<void> _save(EventDetails event) async {
    final edit = _edit;
    if (edit == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(eventManageViewModelProvider(widget.eventId).notifier)
        .updateSettings(event, edit);
    if (!ok || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventManageSaved)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eventAsync = ref
        .watch(eventDetailsViewModelProvider(widget.eventId))
        .event;
    final manage = ref.watch(eventManageViewModelProvider(widget.eventId));
    final event = eventAsync.value;
    if (event == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(
          child: eventAsync.hasError
              ? Text(l10n.eventLoadError)
              : const CircularProgressIndicator(),
        ),
      );
    }
    final edit = _edit ??= settingsEditFor(event);
    final locked = event.settingsLocked ?? false;
    final scored = eventIsScored(event);
    final lesson = event.eventType == 'et_individual_lesson';
    final hours = edit.attendanceUnitType == attendanceUnitHours;
    final unitLabel = hours ? l10n.createUnitHours : l10n.createUnitDays;
    void update(EventSettingsEdit next) => setState(() => _edit = next);

    Widget header(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );

    // A played event cannot be changed: controls are inert.
    return IgnorePointer(
      ignoring: manage.busy,
      child: StepScaffold(
        rootId: EventManageSettingsTestIds.root,
        titleId: EventManageSettingsTestIds.title,
        title: l10n.eventSettingsTitle,
        primaryLabel: locked ? null : l10n.eventManageSave,
        primaryId: EventManageSettingsTestIds.save,
        loading: manage.busy,
        onPrimary: locked ? null : () => _save(event),
        onBack: () => context.pop(),
        children: [
          if (locked)
            TestId(
              EventManageSettingsTestIds.locked,
              child: Text(l10n.eventManageLocked),
            ),
          AbsorbPointer(
            absorbing: locked,
            child: Opacity(
              opacity: locked ? 0.5 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header(l10n.createDeadlineLabel),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: attendanceUnitHours,
                        label: TestId(
                          EventManageSettingsTestIds.unitHours,
                          child: Text(l10n.createUnitHours),
                        ),
                      ),
                      ButtonSegment(
                        value: attendanceUnitDays,
                        label: TestId(
                          EventManageSettingsTestIds.unitDays,
                          child: Text(l10n.createUnitDays),
                        ),
                      ),
                    ],
                    selected: {edit.attendanceUnitType},
                    onSelectionChanged: (s) =>
                        update(edit.withAttendanceType(s.first)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      NumberStepper(
                        idPrefix: EventManageSettingsTestIds.deadlinePrefix,
                        label: l10n.createDeadlineLabel,
                        decreaseLabel: l10n.createDecrease,
                        increaseLabel: l10n.createIncrease,
                        value: edit.attendanceUnit,
                        max: edit.maxAttendanceUnit,
                        onChanged: (v) => update(edit.withAttendanceUnit(v)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.createDeadlineValue(
                            '${edit.attendanceUnit} $unitLabel',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!lesson)
                    TestId(
                      EventManageSettingsTestIds.allowManage,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.createAllowManageLabel),
                        value: edit.allowManagePlayers,
                        onChanged: (v) =>
                            update(edit.copyWith(allowManagePlayers: v)),
                      ),
                    ),
                  if (scored)
                    TestId(
                      EventManageSettingsTestIds.allowLogResults,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.createLogResultsLabel),
                        value: edit.allowLogResults,
                        onChanged: (v) =>
                            update(edit.copyWith(allowLogResults: v)),
                      ),
                    ),
                  if (event.isRoundRobin && event.isTeamEvent)
                    TestId(
                      EventManageSettingsTestIds.ranking,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.createRankingLabel),
                        value: edit.considerForTeamRanking,
                        onChanged: (v) =>
                            update(edit.copyWith(considerForTeamRanking: v)),
                      ),
                    ),
                  header(l10n.createInviteSettingsTitle),
                  _LimitRow(
                    label: l10n.createMaxPlayersLabel,
                    // One student per lesson: fixed at one.
                    stepper: lesson
                        ? Text(
                            '${edit.playersLimit}',
                            style: Theme.of(context).textTheme.titleLarge,
                          )
                        : NumberStepper(
                            idPrefix: EventManageSettingsTestIds.playersPrefix,
                            label: l10n.createMaxPlayersLabel,
                            decreaseLabel: l10n.createDecrease,
                            increaseLabel: l10n.createIncrease,
                            value: edit.playersLimit,
                            onChanged: (v) => update(edit.withPlayersLimit(v)),
                          ),
                  ),
                  _LimitRow(
                    label: l10n.createRsvpLimitLabel,
                    stepper: NumberStepper(
                      idPrefix: EventManageSettingsTestIds.rsvpPrefix,
                      label: l10n.createRsvpLimitLabel,
                      decreaseLabel: l10n.createDecrease,
                      increaseLabel: l10n.createIncrease,
                      value: edit.rsvpLimit,
                      min: edit.playersLimit,
                      onChanged: (v) => update(edit.withRsvpLimit(v)),
                    ),
                  ),
                  header(l10n.createAcceptanceLabel),
                  RadioGroup<String>(
                    groupValue: edit.acceptanceType,
                    onChanged: (v) {
                      if (v != null) update(edit.copyWith(acceptanceType: v));
                    },
                    child: Column(
                      children: [
                        TestId(
                          EventManageSettingsTestIds.orderOfResponse,
                          child: RadioListTile<String>(
                            value: acceptOrderOfResponse,
                            title: Text(l10n.createAcceptOrderOfResponse),
                          ),
                        ),
                        TestId(
                          EventManageSettingsTestIds.pickManually,
                          child: RadioListTile<String>(
                            value: acceptPickManually,
                            title: Text(l10n.createAcceptPickManually),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (scored) ...[
                    const SizedBox(height: 16),
                    ScoringPicker(
                      sport: SportKey.fromKey(event.sportType),
                      eventType: event.eventType,
                      scoring: edit.scoring,
                      idPrefix: EventManageSettingsTestIds.scoringPrefix,
                      selectFirstIfMissing: false,
                      onFormat: (format, minimums) => update(
                        edit.copyWith(
                          scoring: ScoringChoice(
                            format: format,
                            minimumScore: defaultMinimumScore(format, minimums),
                          ),
                        ),
                      ),
                      onScore: (v) => update(
                        edit.copyWith(
                          scoring: edit.scoring?.copyWith(
                            minimumScore: v < 1 ? 1 : v,
                          ),
                        ),
                      ),
                      onDecidingSet: (v) => update(
                        edit.copyWith(
                          scoring: edit.scoring?.copyWith(decidingSetType: v),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (manage.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TestId(
                EventManageSettingsTestIds.error,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    manage.error!.isEmpty
                        ? l10n.eventManageFailed
                        : manage.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({required this.label, required this.stepper});

  final String label;
  final Widget stepper;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        stepper,
      ],
    ),
  );
}
