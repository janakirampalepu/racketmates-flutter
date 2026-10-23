import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/event_actions_repository.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/participant_status_filter.dart';
import 'package:racketmates/common/events/rsvp_preferences.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';

/// Asks a round robin player about their game (native `llRoundRobinOptions`
/// of `MatchScheduleOptionsPicker`): the match type when the event has both,
/// whether they bring a partner and who, and for a new response a note.
/// Returns null when dismissed.
Future<RsvpPreferences?> showRsvpPreferences(
  BuildContext context, {
  required EventDetails event,
  required CurrentUserEventDetail? me,
  required bool editing,
}) => showModalBottomSheet<RsvpPreferences>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _PreferencesSheet(event: event, me: me, editing: editing),
);

class _PreferencesSheet extends ConsumerStatefulWidget {
  const _PreferencesSheet({
    required this.event,
    required this.me,
    required this.editing,
  });

  final EventDetails event;
  final CurrentUserEventDetail? me;
  final bool editing;

  @override
  ConsumerState<_PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends ConsumerState<_PreferencesSheet> {
  late RsvpPreferences _prefs = initialPreferences(
    widget.event,
    widget.me,
    editing: widget.editing,
  );
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPartner() async {
    final picked = await showModalBottomSheet<EventParticipant>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PartnerPicker(
        event: widget.event,
        me: widget.me,
        selected: _prefs.partner,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _prefs = _prefs.copyWith(partner: () => picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final event = widget.event;

    Widget choice(String id, String label, bool selected, VoidCallback onTap) =>
        TestId(
          id,
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onTap(),
          ),
        );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: TestId(
          EventDetailsTestIds.prefsSheet,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.rsvpPrefsTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (asksMatchType(event)) ...[
                  const SizedBox(height: 16),
                  Text(l10n.rsvpPrefsMatchType),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      choice(
                        EventDetailsTestIds.prefsMatch('mt_doubles'),
                        l10n.rsvpPrefsDoubles,
                        _prefs.matchType == 'mt_doubles',
                        () => setState(
                          () => _prefs = _prefs.copyWith(
                            matchType: () => 'mt_doubles',
                          ),
                        ),
                      ),
                      choice(
                        EventDetailsTestIds.prefsMatch('mt_undecided'),
                        l10n.rsvpPrefsBoth,
                        _prefs.matchType == 'mt_undecided',
                        () => setState(
                          () => _prefs = _prefs.copyWith(
                            matchType: () => 'mt_undecided',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (asksPartner(event)) ...[
                  const SizedBox(height: 16),
                  Text(l10n.rsvpPrefsPartner),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      choice(
                        EventDetailsTestIds.prefsPartnerType(partnerHas),
                        l10n.rsvpPrefsHavePartner,
                        _prefs.partnerType == partnerHas,
                        () => setState(
                          () =>
                              _prefs = _prefs.copyWith(partnerType: partnerHas),
                        ),
                      ),
                      choice(
                        EventDetailsTestIds.prefsPartnerType(partnerNeeds),
                        l10n.rsvpPrefsNeedPartner,
                        _prefs.partnerType == partnerNeeds,
                        () => setState(
                          () => _prefs = _prefs.copyWith(
                            partnerType: partnerNeeds,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_prefs.partnerType == partnerHas) ...[
                    const SizedBox(height: 8),
                    if (_prefs.partner == null)
                      TestId(
                        EventDetailsTestIds.prefsSelectPartner,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.person_add_alt),
                          label: Text(l10n.rsvpPrefsSelectPartner),
                          onPressed: _pickPartner,
                        ),
                      )
                    else
                      TestId(
                        EventDetailsTestIds.prefsPartner,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(_prefs.partner!.name),
                          trailing: TestId(
                            EventDetailsTestIds.prefsChangePartner,
                            child: TextButton(
                              onPressed: _pickPartner,
                              child: Text(l10n.rsvpPrefsChangePartner),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
                if (!widget.editing) ...[
                  const SizedBox(height: 16),
                  TestId(
                    EventDetailsTestIds.prefsNotes,
                    child: TextField(
                      controller: _notes,
                      maxLength: rsvpNotesLimit,
                      decoration: InputDecoration(
                        labelText: l10n.rsvpPrefsNotes,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TestId(
                  EventDetailsTestIds.prefsSubmit,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: preferencesComplete(event, _prefs)
                        ? () => Navigator.of(context)
                              .pop(_prefs.copyWith(notes: _notes.text.trim()))
                        : null,
                    child: Text(
                      widget.editing
                          ? l10n.rsvpPrefsSave
                          : l10n.rsvpPrefsSubmit,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pick a partner (native `SelectPartnerPicker`): players who have no partner
/// yet, grouped by their status, searchable; one choice.
class _PartnerPicker extends ConsumerStatefulWidget {
  const _PartnerPicker({
    required this.event,
    required this.me,
    required this.selected,
  });

  final EventDetails event;
  final CurrentUserEventDetail? me;
  final EventParticipant? selected;

  @override
  ConsumerState<_PartnerPicker> createState() => _PartnerPickerState();
}

class _PartnerPickerState extends ConsumerState<_PartnerPicker> {
  List<EventParticipantGroup>? _groups;
  bool _failed = false;
  int _request = 0;
  EventParticipant? _choice;

  @override
  void initState() {
    super.initState();
    _choice = widget.selected;
    unawaited(_load(''));
  }

  Future<void> _load(String search) async {
    final request = ++_request;
    try {
      final key = await ref.read(participantStatusFilterKeyProvider.future);
      final myId = widget.me?.user?.id;
      final groups = await ref
          .read(eventActionsRepositoryProvider)
          .participants(
            widget.event.id!,
            groupBy: 'status',
            exclude: [?myId],
            search: search,
            excludeWithPartner: true,
            statuses: key == null ? const [] : [key],
          );
      if (!mounted || request != _request) return;
      setState(() {
        _failed = false;
        _groups = groups;
      });
    } on Object {
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = _groups;
    final empty =
        groups != null &&
        groups.every((g) => (g.eventParticipants ?? const []).isEmpty);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Semantics(
                  header: true,
                  child: Text(l10n.rsvpPartnerTitle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TestId(
                  EventDetailsTestIds.partnerSearch,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: l10n.rsvpPartnerSearch,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => _load(v.trim()),
                  ),
                ),
              ),
              Flexible(
                child: _failed
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: TestId(
                          EventDetailsTestIds.partnerError,
                          child: Text(l10n.rsvpPartnerLoadError),
                        ),
                      )
                    : groups == null
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : empty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: TestId(
                          EventDetailsTestIds.partnerNone,
                          child: Text(l10n.rsvpPartnerNone),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final g in groups)
                            if ((g.eventParticipants ?? const [])
                                .isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  4,
                                ),
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    '${g.label ?? humanizeStatus(g.key)} '
                                    '(${g.eventParticipants!.length})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                ),
                              ),
                              for (final p in g.eventParticipants!)
                                TestId(
                                  EventDetailsTestIds.partnerOption(p.id ?? 0),
                                  child: RadioListTile<int>(
                                    // ignore: deprecated_member_use
                                    value: p.id ?? 0,
                                    // ignore: deprecated_member_use
                                    groupValue: _choice?.id,
                                    // ignore: deprecated_member_use
                                    onChanged: (_) =>
                                        setState(() => _choice = p),
                                    title: Text(p.name),
                                  ),
                                ),
                            ],
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TestId(
                  EventDetailsTestIds.partnerSelect,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _choice == null
                        ? null
                        : () => Navigator.of(context).pop(_choice),
                    child: Text(l10n.rsvpPartnerSelect),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "eus_confirmed" when a group came without a label.
String humanizeStatus(String? key) =>
    (key ?? '').replaceFirst('eus_', '').replaceAll('_', ' ');
