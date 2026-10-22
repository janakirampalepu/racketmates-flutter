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
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_when_where/create_event_when_where_test_ids.dart';
import 'package:racketmates/screens/create_event_when_where/create_event_when_where_view_model.dart';

/// Venue, courts, date, start time, duration and notes (native
/// `EventCourtFragment`, single schedule option).
class CreateEventWhenWhereScreen extends ConsumerStatefulWidget {
  const CreateEventWhenWhereScreen({super.key});

  @override
  ConsumerState<CreateEventWhenWhereScreen> createState() =>
      _CreateEventWhenWhereScreenState();
}

class _CreateEventWhenWhereScreenState
    extends ConsumerState<CreateEventWhenWhereScreen> {
  late final TextEditingController _notes = TextEditingController(
    text: ref.read(createEventFlowProvider)?.notes ?? '',
  );

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickVenue() async {
    final sport = ref.read(createEventFlowProvider)?.sport?.key;
    final place = await context.push<PlaceItem>(
      AppRoutes.placesFor(sport: sport),
    );
    if (place == null || !mounted) return;
    await ref.read(whenWhereViewModelProvider.notifier).onPlacePicked(place);
  }

  Future<void> _pickDate() async {
    final flow = ref.read(createEventFlowProvider.notifier);
    final current = ref.read(createEventFlowProvider)?.start;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    flow.setStart(
      DateTime(
        picked.year,
        picked.month,
        picked.day,
        current?.hour ?? 18,
        current?.minute ?? 0,
      ),
    );
  }

  Future<void> _pickTime() async {
    final flow = ref.read(createEventFlowProvider.notifier);
    final current = ref.read(createEventFlowProvider)?.start;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current?.hour ?? 18,
        minute: current?.minute ?? 0,
      ),
    );
    if (picked == null) return;
    final base = current ?? DateTime.now().add(const Duration(days: 1));
    flow.setStart(
      DateTime(base.year, base.month, base.day, picked.hour, picked.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final state = ref.watch(whenWhereViewModelProvider);
    final flow = ref.read(createEventFlowProvider.notifier);
    final locale = Localizations.localeOf(context).toString();
    final place = draft.place;
    final courts = [
      for (final c in place?.placeCourts ?? const <PlaceCourt>[])
        if (c.id != null &&
            (c.sportType == null || c.sportType == draft.sport?.key))
          c,
    ];
    final start = draft.start;
    final errorColor = Theme.of(context).colorScheme.error;

    Widget error(String id, String text) => Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: TestId(
        id,
        child: Semantics(
          liveRegion: true,
          child: Text(text, style: TextStyle(color: errorColor)),
        ),
      ),
    );

    return StepScaffold(
      rootId: CreateEventWhenWhereTestIds.root,
      titleId: CreateEventWhenWhereTestIds.title,
      title: ref.msg(MessageKeys.createDetailsTitle, l10n.createWhenWhereTitle),
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventWhenWhereTestIds.next,
      onPrimary: () {
        if (ref
            .read(whenWhereViewModelProvider.notifier)
            .validate(DateTime.now())) {
          context.push(AppRoutes.createEventInviteSettings);
        }
      },
      onBack: () => context.pop(),
      children: [
        TestId(
          CreateEventWhenWhereTestIds.venueButton,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.place_outlined),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              alignment: AlignmentDirectional.centerStart,
            ),
            onPressed: _pickVenue,
            label: Text(
              place?.name ??
                  ref.msg(
                    MessageKeys.createSelectVenueButton,
                    l10n.createSelectVenue,
                  ),
            ),
          ),
        ),
        if (state.errors.contains(WhenWhereError.venueRequired))
          error(
            CreateEventWhenWhereTestIds.venueError,
            ref.msg(MessageKeys.createVenueRequired, l10n.createVenueRequired),
          ),
        if (state.loadingCourts)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (place != null && !state.loadingCourts) ...[
          const SizedBox(height: 8),
          if (courts.isEmpty)
            TestId(
              CreateEventWhenWhereTestIds.noCourts,
              child: Text(l10n.createNoCourts),
            )
          else ...[
            Semantics(header: true, child: Text(l10n.createCourtsLabel)),
            for (final court in courts)
              TestId(
                CreateEventWhenWhereTestIds.court(court.id!),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(court.name ?? '#${court.id}'),
                  value: draft.courtIds.contains(court.id),
                  onChanged: (_) => flow.toggleCourt(court.id!),
                ),
              ),
          ],
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TestId(
                CreateEventWhenWhereTestIds.dateButton,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: _pickDate,
                  label: Text(
                    start == null
                        ? l10n.createDateLabel
                        : DateFormat.yMMMEd(locale).format(start),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TestId(
                CreateEventWhenWhereTestIds.timeButton,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: _pickTime,
                  label: Text(
                    start == null
                        ? l10n.createTimeLabel
                        : DateFormat.jm(locale).format(start),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (state.errors.contains(WhenWhereError.startRequired))
          error(
            CreateEventWhenWhereTestIds.startError,
            ref.msg(MessageKeys.createStartRequired, l10n.createStartRequired),
          ),
        if (state.errors.contains(WhenWhereError.startInPast))
          error(CreateEventWhenWhereTestIds.startError, l10n.createStartInPast),
        const SizedBox(height: 16),
        TestId(
          CreateEventWhenWhereTestIds.duration,
          child: DropdownButtonFormField<int>(
            initialValue: draft.durationMinutes,
            decoration: InputDecoration(
              labelText: ref.msg(
                MessageKeys.createDurationLabel,
                l10n.createDurationLabel,
              ),
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final m in eventDurationOptions)
                DropdownMenuItem(
                  value: m,
                  child: Text(l10n.createDurationValue(m)),
                ),
            ],
            onChanged: (m) {
              if (m != null) flow.setDuration(m);
            },
          ),
        ),
        const SizedBox(height: 16),
        TestId(
          CreateEventWhenWhereTestIds.notes,
          child: TextField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: ref.msg(
                MessageKeys.createNotesLabel,
                l10n.createNotesLabel,
              ),
              border: const OutlineInputBorder(),
            ),
            onChanged: flow.setNotes,
          ),
        ),
      ],
    );
  }
}
