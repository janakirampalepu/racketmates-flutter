import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/settings/reminder_rules.dart';
import 'package:racketmates/common/settings/settings_models.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_reminders/event_reminders_test_ids.dart';
import 'package:racketmates/screens/event_reminders/event_reminders_view_model.dart';

/// "5 minutes before" for a reminder.
String reminderText(AppLocalizations l10n, int value, String? unit) =>
    switch (unit) {
      ReminderUnits.hour => l10n.reminderHoursBefore(value),
      ReminderUnits.day => l10n.reminderDaysBefore(value),
      _ => l10n.reminderMinutesBefore(value),
    };

/// How long before an event the user is reminded (native
/// `EventRemaindersFragment` and `RemainderAddPicker`).
class EventRemindersScreen extends ConsumerWidget {
  const EventRemindersScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<({int value, String unit})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddReminderSheet(),
    );
    if (choice == null) return;
    await ref
        .read(eventRemindersViewModelProvider.notifier)
        .add(value: choice.value, unit: choice.unit);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(eventRemindersViewModelProvider);
    final vm = ref.read(eventRemindersViewModelProvider.notifier);

    Widget body(List<ReminderPreference> list) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.remindersHint),
        const SizedBox(height: 8),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: TestId(
              EventRemindersTestIds.empty,
              child: Text(
                l10n.remindersEmpty,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        for (final r in list)
          TestId(
            EventRemindersTestIds.reminder(r.id ?? 0),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                reminderText(l10n, r.reminderUnit ?? 0, r.reminderUnitType),
              ),
              trailing: TestId(
                EventRemindersTestIds.remove(r.id ?? 0),
                child: IconButton(
                  tooltip: l10n.reminderRemove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: state.busy || r.id == null
                      ? null
                      : () => vm.remove(r.id!),
                ),
              ),
            ),
          ),
        if (state.failed)
          TestId(
            EventRemindersTestIds.failed,
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.remindersFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        const SizedBox(height: 16),
        TestId(
          EventRemindersTestIds.add,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: state.busy ? null : () => _add(context, ref),
            label: Text(l10n.remindersAdd),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          EventRemindersTestIds.title,
          child: Semantics(header: true, child: Text(l10n.remindersTitle)),
        ),
      ),
      body: TestId(
        EventRemindersTestIds.root,
        child: state.reminders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TestId(
                  EventRemindersTestIds.error,
                  child: Text(l10n.remindersLoadError),
                ),
                TestId(
                  EventRemindersTestIds.retry,
                  child: TextButton(
                    onPressed: vm.load,
                    child: Text(l10n.retryAction),
                  ),
                ),
              ],
            ),
          ),
          data: body,
        ),
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  String _unit = ReminderUnits.minute;
  int _value = reminderValuesFor(ReminderUnits.minute).first;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final values = reminderValuesFor(_unit);
    final labels = {
      ReminderUnits.minute: l10n.reminderUnitMinutes,
      ReminderUnits.hour: l10n.reminderUnitHours,
      ReminderUnits.day: l10n.reminderUnitDays,
    };
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: TestId(
          EventRemindersTestIds.sheet,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.remindersAdd,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final unit in ReminderUnits.all)
                    ButtonSegment(
                      value: unit,
                      label: TestId(
                        EventRemindersTestIds.unit(unit),
                        child: Text(labels[unit]!),
                      ),
                    ),
                ],
                selected: {_unit},
                // A new unit starts at its smallest value (native picker).
                onSelectionChanged: (s) => setState(() {
                  _unit = s.first;
                  _value = reminderValuesFor(_unit).first;
                }),
              ),
              const SizedBox(height: 16),
              TestId(
                EventRemindersTestIds.value,
                child: DropdownButtonFormField<int>(
                  key: ValueKey(_unit),
                  initialValue: _value,
                  decoration: InputDecoration(
                    labelText: l10n.reminderValueLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final v in values)
                      DropdownMenuItem(value: v, child: Text('$v')),
                  ],
                  onChanged: (v) => setState(() => _value = v ?? _value),
                ),
              ),
              const SizedBox(height: 12),
              TestId(
                EventRemindersTestIds.preview,
                child: Text(reminderText(l10n, _value, _unit)),
              ),
              const SizedBox(height: 16),
              TestId(
                EventRemindersTestIds.save,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop((value: _value, unit: _unit)),
                  child: Text(l10n.eventManageSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
