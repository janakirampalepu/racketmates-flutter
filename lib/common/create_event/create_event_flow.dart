import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/create_event/scoring.dart';
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

  /// Games and round robins size the player limits from their matches or
  /// courts (native `setRSVPandPlayerLimit`); the invite settings step can
  /// still change them afterwards.
  EventDraft _synced(EventDraft d) {
    final capacity = d.courtPlayerCapacity;
    return capacity == null
        ? d
        : d.copyWith(playersLimit: capacity, rsvpLimit: capacity);
  }

  EventDraft _fresh(String? type, SportKey? sport) {
    final spec = eventTypeSpecs[type];
    return _synced(
      EventDraft(
        eventType: type,
        sport: sport,
        matches: (spec?.hasMatches ?? false) ? const [MatchDraft()] : const [],
      ),
    );
  }

  /// Changing the type or sport invalidates everything that depends on it.
  void setEventType(String type) => state = _fresh(type, null);

  /// Next wizard step for the current event type and assignment choice.
  CreateEventStep? next(CreateEventStep current) => nextCreateEventStep(
    _draft.eventType,
    current,
    assignNow: _draft.assignNow,
  );

  void setSport(SportKey sport) => state = _fresh(_draft.eventType, sport);

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
    } else if (d.courtIds.length < d.courtCap) {
      state = d.copyWith(courtIds: [...d.courtIds, courtId]);
    }
  }

  /// Number of courts to book; fewer courts drops the extra selections.
  void setCourtCount(int count) {
    final d = _draft;
    final next = count < 1 ? 1 : count;
    state = _synced(
      d.copyWith(courtCount: next, courtIds: d.courtIds.take(next).toList()),
    );
  }

  // --- Games: matches and the players in them ---------------------------

  void _setMatches(List<MatchDraft> matches) {
    final d = _draft;
    state = _synced(
      d.copyWith(
        matches: matches,
        courtIds: d.courtIds.take(matches.length).toList(),
      ),
    );
  }

  void addMatch() => _setMatches([..._draft.matches, const MatchDraft()]);

  /// A game keeps at least one match.
  void removeMatch(int index) {
    final matches = _draft.matches;
    if (matches.length <= 1 || index < 0 || index >= matches.length) return;
    _setMatches([
      for (var i = 0; i < matches.length; i++)
        if (i != index) matches[i],
    ]);
  }

  void setMatchType(int index, String type) => _setMatches([
    for (var i = 0; i < _draft.matches.length; i++)
      i == index ? _draft.matches[i].withType(type) : _draft.matches[i],
  ]);

  void assignPlayer(int index, MatchSlot slot, AppUser user) => _setMatches([
    for (var i = 0; i < _draft.matches.length; i++)
      i == index ? _draft.matches[i].withPlayer(slot, user) : _draft.matches[i],
  ]);

  void clearSlot(int index, MatchSlot slot) => _setMatches([
    for (var i = 0; i < _draft.matches.length; i++)
      i == index ? _draft.matches[i].withoutPlayer(slot) : _draft.matches[i],
  ]);

  /// "Assign players now" or "invite and assign later". Players already put
  /// into matches are kept but only sent while assigning now.
  void setAssignNow({required bool value}) =>
      state = _draft.copyWith(assignNow: value);

  // --- Round robin ---------------------------------------------------------

  /// Singles has no partners; doubles (or both) default to rotating partners
  /// (native `updateSelectedGameType`).
  void setGameType(String type) {
    final d = _draft;
    state = _synced(
      d.copyWith(
        gameType: type,
        partnershipType: () => type == MatchKeys.gameSingles
            ? null
            : (d.partnershipType ?? MatchKeys.partnersRotating),
        eventSubType: () => null,
      ),
    );
  }

  void setPartnership(String type) => state = _draft.copyWith(
    partnershipType: () => type,
    eventSubType: () => null,
  );

  void setEventSubType(String type) =>
      state = _draft.copyWith(eventSubType: () => type);

  // --- Scoring ----------------------------------------------------------

  /// Choosing a format resets the minimum score to its default and the
  /// deciding set to "decide later" (native scoring format picker).
  void setScoringFormat(String format, Map<String, num?> minimumScores) =>
      state = _draft.copyWith(
        scoring: ScoringChoice(
          format: format,
          minimumScore: defaultMinimumScore(format, minimumScores),
        ),
      );

  void setMinimumScore(int score) {
    final scoring = _draft.scoring;
    if (scoring == null) return;
    state = _draft.copyWith(
      scoring: scoring.copyWith(minimumScore: score < 1 ? 1 : score),
    );
  }

  void setDecidingSetType(String type) {
    final scoring = _draft.scoring;
    if (scoring == null) return;
    state = _draft.copyWith(scoring: scoring.copyWith(decidingSetType: type));
  }

  void setAllowLogResults({required bool value}) =>
      state = _draft.copyWith(allowParticipantsToLogResults: value);

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
