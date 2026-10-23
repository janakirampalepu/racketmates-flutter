import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/event_actions_repository.dart';
import 'package:racketmates/common/events/manage_logic.dart';
import 'package:racketmates/common/events/models/event_match_models.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';

class EventManageState {
  const EventManageState({this.busy = false, this.error});

  /// A change is being sent.
  final bool busy;

  /// Server text of the last failure, or an empty string when the server sent
  /// none (show the localized default). Null = no failure.
  final String? error;
}

/// Organizer changes to one event. Every success reloads the event so every
/// manage screen shows what the server now has.
class EventManageViewModel extends Notifier<EventManageState> {
  EventManageViewModel(this.eventId);

  final int eventId;

  @override
  EventManageState build() => const EventManageState();

  void clearError() => state = const EventManageState();

  EventActionsRepository get _repo => ref.read(eventActionsRepositoryProvider);

  Future<bool> _run(Future<void> Function() action) async {
    if (state.busy) return false;
    state = const EventManageState(busy: true);
    try {
      await action();
      if (!ref.mounted) return true;
      await ref.read(eventDetailsViewModelProvider(eventId).notifier).refresh();
      if (ref.mounted) state = const EventManageState();
      return true;
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = EventManageState(
          error: switch (failure) {
            ServerFailure(message: final m) when m != null && m.isNotEmpty => m,
            UnauthorizedFailure(message: final m)
                when m != null && m.isNotEmpty =>
              m,
            _ => '',
          },
        );
      }
      return false;
    }
  }

  Future<bool> updateSettings(EventDetails event, EventSettingsEdit edit) =>
      _run(
        () =>
            _repo.updateSettings(eventId, buildUpdateSettingsBody(event, edit)),
      );

  /// Reschedules to the venue, time, courts and notes of [draft]; the venue's
  /// time zone is looked up when the draft does not have it (native sends the
  /// zone of the chosen place).
  Future<bool> reschedule(EventDraft draft) => _run(() async {
    var d = draft;
    final coords = d.place?.addressDetail;
    if (d.timezoneInfoId == null &&
        d.start != null &&
        coords?.latitude != null &&
        coords?.longitude != null) {
      final id = await ref
          .read(createEventRepositoryProvider)
          .timezoneInfoId(
            latitude: coords!.latitude!,
            longitude: coords.longitude!,
            time: formatStartTime(d.start!),
          );
      d = d.copyWith(timezoneInfoId: () => id);
    }
    await _repo.reschedule(eventId, buildRescheduleBody(d));
  });

  Future<bool> saveScores(
    EventMatch match,
    List<SetScore> sets, {
    required bool unfinished,
    TieBreaks tieBreaks = const {},
    SetScore? matchTieBreak,
    String? decidingSetType,
  }) => _run(
    () => _repo.updateScores(
      eventId,
      match.id!,
      buildUpdateScoresBody(
        match,
        sets,
        unfinished: unfinished,
        tieBreaks: tieBreaks,
        matchTieBreak: matchTieBreak,
        decidingSetType: decidingSetType,
      ),
    ),
  );

  Future<bool> clearUnfinished(EventMatch match) =>
      _run(() => _repo.clearUnfinished(eventId, match.id!));

  Future<bool> pickPlayers(List<int> userIds) =>
      _run(() => _repo.pickPlayers(eventId, userIds));

  Future<bool> removeParticipants(List<int> userIds) =>
      _run(() => _repo.removeParticipants(eventId, userIds));

  Future<bool> addParticipants(List<int> userIds, String role) =>
      _run(() => _repo.addParticipants(eventId, userIds, role));
}

final eventManageViewModelProvider = NotifierProvider.autoDispose
    .family<EventManageViewModel, EventManageState, int>(
      EventManageViewModel.new,
    );
