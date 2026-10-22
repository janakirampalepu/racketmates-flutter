import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';

enum WhenWhereError { venueRequired, startRequired, startInPast }

/// Errors blocking the "when and where" step (native `venue_required_error`,
/// `start_date_time_required_error`).
List<WhenWhereError> validateWhenWhere(EventDraft draft, DateTime now) => [
  if (draft.place?.id == null) WhenWhereError.venueRequired,
  if (draft.start == null)
    WhenWhereError.startRequired
  else if (!draft.start!.isAfter(now))
    WhenWhereError.startInPast,
];

/// State shared by the create-event screens; cleared when the flow ends.
class CreateEventFlow extends Notifier<EventDraft?> {
  @override
  EventDraft? build() => null;

  EventDraft get _draft => state!;

  void start() => state = const EventDraft();

  void reset() => state = null;

  /// Changing the type or sport invalidates everything that depends on it.
  void setEventType(String type) => state = EventDraft(eventType: type);

  /// Next wizard step for the current event type.
  CreateEventStep? next(CreateEventStep current) =>
      nextCreateEventStep(_draft.eventType, current);

  void setSport(SportKey sport) {
    final d = _draft;
    state = EventDraft(eventType: d.eventType, sport: sport);
  }

  void setAttendanceType(String type) =>
      state = _draft.copyWith(attendanceUnitType: type, attendanceUnit: 1);

  void setAttendanceUnit(int unit) {
    final d = _draft;
    state = d.copyWith(attendanceUnit: unit.clamp(1, d.maxAttendanceUnit));
  }

  void setAllowManage({required bool value}) =>
      state = _draft.copyWith(allowParticipantsManagePlayers: value);

  void toggleCoach(AppUser user) {
    final d = _draft;
    final exists = d.coaches.any((u) => u.id == user.id);
    state = d.copyWith(
      coaches: exists
          ? [
              for (final u in d.coaches)
                if (u.id != user.id) u,
            ]
          : [...d.coaches, user],
    );
  }

  void toggleInvitee(AppUser user) {
    final d = _draft;
    final exists = d.invitees.any((u) => u.id == user.id);
    state = d.copyWith(
      invitees: exists
          ? [
              for (final u in d.invitees)
                if (u.id != user.id) u,
            ]
          : [...d.invitees, user],
    );
  }

  /// A new venue clears the court selection and the resolved timezone.
  void setPlace(PlaceItem place) => state = _draft.copyWith(
    place: () => place,
    courtIds: const [],
    timezoneInfoId: () => null,
  );

  void setPlaceDetails(PlaceItem place) {
    if (_draft.place?.id == place.id) {
      state = _draft.copyWith(place: () => place);
    }
  }

  /// Selecting is capped at [EventDraft.courtCount] (native "select up to N
  /// courts").
  void toggleCourt(int courtId) {
    final d = _draft;
    if (d.courtIds.contains(courtId)) {
      state = d.copyWith(
        courtIds: [
          for (final c in d.courtIds)
            if (c != courtId) c,
        ],
      );
    } else if (d.courtIds.length < d.courtCount) {
      state = d.copyWith(courtIds: [...d.courtIds, courtId]);
    }
  }

  /// Number of courts to book; fewer courts drops the extra selections.
  void setCourtCount(int count) {
    final d = _draft;
    final next = count < 1 ? 1 : count;
    state = d.copyWith(
      courtCount: next,
      courtIds: d.courtIds.take(next).toList(),
    );
  }

  void setStart(DateTime? start) =>
      state = _draft.copyWith(start: () => start, timezoneInfoId: () => null);

  void setDuration(int minutes) =>
      state = _draft.copyWith(durationMinutes: minutes);

  void setNotes(String notes) => state = _draft.copyWith(notes: notes);

  /// Players limit >= 1; the RSVP limit never drops below it (native rule).
  void setPlayersLimit(int limit) {
    final d = _draft;
    final players = limit < 1 ? 1 : limit;
    state = d.copyWith(
      playersLimit: players,
      rsvpLimit: d.rsvpLimit < players ? players : d.rsvpLimit,
    );
  }

  void setRsvpLimit(int limit) {
    final d = _draft;
    state = d.copyWith(
      rsvpLimit: limit < d.playersLimit ? d.playersLimit : limit,
    );
  }

  void setAcceptanceType(String type) =>
      state = _draft.copyWith(acceptanceType: type);
}

final createEventFlowProvider = NotifierProvider<CreateEventFlow, EventDraft?>(
  CreateEventFlow.new,
);

class CreateEventSubmission {
  const CreateEventSubmission({
    this.loading = false,
    this.failure,
    this.createdEventId,
  });

  final bool loading;
  final AppFailure? failure;

  /// Id of the created event.
  final int? createdEventId;
}

/// Creates the event: resolves the venue's timezone, then `POST events`.
class CreateEventSubmitter extends Notifier<CreateEventSubmission> {
  @override
  CreateEventSubmission build() => const CreateEventSubmission();

  /// True when the event was created ([CreateEventSubmission.createdEventId]
  /// holds its id when the server returned one).
  Future<bool> submit() async {
    var draft = ref.read(createEventFlowProvider);
    if (draft == null || state.loading) return false;
    state = const CreateEventSubmission(loading: true);
    final repo = ref.read(createEventRepositoryProvider);
    try {
      final coords = draft.place?.addressDetail;
      if (draft.timezoneInfoId == null &&
          draft.start != null &&
          coords?.latitude != null &&
          coords?.longitude != null) {
        final id = await repo.timezoneInfoId(
          latitude: coords!.latitude!,
          longitude: coords.longitude!,
          time: formatStartTime(draft.start!),
        );
        draft = draft.copyWith(timezoneInfoId: () => id);
      }
      final response = await repo.create(buildCreateEventBody(draft));
      final id = response.event?.id;
      state = CreateEventSubmission(createdEventId: id);
      return true;
    } on AppFailure catch (failure) {
      state = CreateEventSubmission(failure: failure);
      return false;
    }
  }

  void clear() => state = const CreateEventSubmission();
}

final createEventSubmitterProvider =
    NotifierProvider<CreateEventSubmitter, CreateEventSubmission>(
      CreateEventSubmitter.new,
    );
