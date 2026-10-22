import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';

const _place = PlaceItem(
  id: 5,
  name: 'Central Courts',
  addressDetail: PlaceAddress(latitude: 40.7, longitude: -74.0),
  placeCourts: [
    PlaceCourt(id: 11, name: 'Court 1'),
    PlaceCourt(id: 12, name: 'Court 2'),
  ],
);

EventDraft _complete() => EventDraft(
  eventType: 'et_practice_drill',
  sport: SportKey.tennis,
  attendanceUnit: 3,
  attendanceUnitType: attendanceUnitDays,
  allowParticipantsManagePlayers: true,
  invitees: const [
    AppUser(id: 8, firstName: 'Alex'),
    AppUser(id: 9, firstName: 'Pat'),
  ],
  place: _place,
  courtIds: const [12, 11],
  start: DateTime(2026, 11, 3, 18, 5),
  durationMinutes: 90,
  timezoneInfoId: 77,
  notes: '  Bring balls  ',
  playersLimit: 4,
  rsvpLimit: 6,
  acceptanceType: acceptPickManually,
);

class _FakeCreateEventRepository implements CreateEventRepository {
  Map<String, dynamic>? body;
  AppFailure? failure;
  int? timezone = 42;
  int? createdId = 500;
  int timezoneCalls = 0;
  String? timezoneTime;

  @override
  Future<EventDetailsResponse> create(Map<String, dynamic> b) async {
    if (failure != null) throw failure!;
    body = b;
    return EventDetailsResponse(event: EventDetails(id: createdId));
  }

  @override
  Future<List<AppUser>> searchPlayers({
    required String query,
    required String sportKey,
  }) async => const [];

  @override
  Future<int?> timezoneInfoId({
    required double latitude,
    required double longitude,
    required String time,
  }) async {
    timezoneCalls++;
    timezoneTime = time;
    return timezone;
  }
}

void main() {
  group('buildCreateEventBody', () {
    test('practice drill body uses the native field names and values', () {
      final event =
          buildCreateEventBody(_complete())['event'] as Map<String, dynamic>;
      expect(event['event_type'], 'et_practice_drill');
      expect(event['sport_type'], 'st_tennis');
      expect(event['originator_type'], '');
      expect(event['with_coach'], isFalse);
      expect(event['with_audience'], isFalse);
      expect(event['request_save_as_draft'], isFalse);
      expect(event['allow_participants_manage_players'], isTrue);
      expect(event['attendance_deadline_unit'], 3);
      expect(event['attendance_deadline_unit_type'], 'adut_day');
      expect(event['player_pool'], 'pp_invited_only');
      expect(event['players_limit'], 4);
      expect(event['rsvp_limit'], 6);
      expect(event['player_acceptance_type'], 'pat_pick_manually');
      expect(event['notes_for_event'], 'Bring balls');
      expect(event['event_screen'], 'es_review');
      expect(
        event['screen_flow_path'],
        startsWith('es_event_type_selection##es_sports_type##'),
      );
    });

    test('participants, schedule option and courts', () {
      final event =
          buildCreateEventBody(_complete())['event'] as Map<String, dynamic>;
      expect(event['event_participants_attributes'], [
        {
          'user_id': 8,
          'is_player': true,
          'is_coach': false,
          'is_audience': false,
        },
        {
          'user_id': 9,
          'is_player': true,
          'is_coach': false,
          'is_audience': false,
        },
      ]);
      expect(event['event_schedule_options_attributes'], [
        {
          'place_id': 5,
          'start_time': '2026-11-03T18:05Z',
          'duration': 90,
          'timezone_info_id': 77,
        },
      ]);
      expect(event['event_venue_courts_attributes'], [
        {'place_court_id': 12, 'order': 1},
        {'place_court_id': 11, 'order': 2},
      ]);
    });

    test('optional parts are left out', () {
      final draft = _complete().copyWith(
        notes: ' ',
        timezoneInfoId: () => null,
        courtIds: const [],
      );
      final event =
          buildCreateEventBody(draft)['event'] as Map<String, dynamic>;
      expect(event.containsKey('notes_for_event'), isFalse);
      expect(
        (event['event_schedule_options_attributes'] as List).single.containsKey(
          'timezone_info_id',
        ),
        isFalse,
      );
      expect(event['event_venue_courts_attributes'], isEmpty);
    });

    test('an incomplete draft cannot be built', () {
      expect(() => buildCreateEventBody(const EventDraft()), throwsStateError);
      expect(
        () => buildCreateEventBody(_complete().copyWith(start: () => null)),
        throwsStateError,
      );
    });

    test('start time keeps the venue wall clock with a literal Z', () {
      expect(formatStartTime(DateTime(2026, 1, 5, 7, 0)), '2026-01-05T07:00Z');
      expect(
        formatStartTime(DateTime(2026, 12, 31, 23, 45)),
        '2026-12-31T23:45Z',
      );
    });
  });

  group('validateWhenWhere', () {
    final now = DateTime(2026, 11, 1, 12);
    test('needs a venue and a future start', () {
      expect(validateWhenWhere(const EventDraft(), now), [
        WhenWhereError.venueRequired,
        WhenWhereError.startRequired,
      ]);
      expect(
        validateWhenWhere(
          EventDraft(place: _place, start: DateTime(2026, 11, 1, 11)),
          now,
        ),
        [WhenWhereError.startInPast],
      );
      expect(
        validateWhenWhere(
          EventDraft(place: _place, start: DateTime(2026, 11, 2)),
          now,
        ),
        isEmpty,
      );
    });
  });

  group('CreateEventFlow rules', () {
    ProviderContainer container() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(createEventFlowProvider.notifier).start();
      return c;
    }

    test('changing the type or sport clears the dependent choices', () {
      final c = container();
      final flow = c.read(createEventFlowProvider.notifier)
        ..setEventType('et_practice_drill')
        ..setSport(SportKey.padel)
        ..setPlace(_place)
        ..toggleCourt(11);
      expect(c.read(createEventFlowProvider)!.courtIds, [11]);
      flow.setSport(SportKey.tennis);
      expect(c.read(createEventFlowProvider)!.place, isNull);
      expect(c.read(createEventFlowProvider)!.eventType, 'et_practice_drill');
    });

    test('a new venue clears the courts and resolved timezone', () {
      final c = container();
      c.read(createEventFlowProvider.notifier)
        ..setPlace(_place)
        ..toggleCourt(11)
        ..toggleCourt(12)
        ..toggleCourt(11);
      expect(c.read(createEventFlowProvider)!.courtIds, [12]);
      c.read(createEventFlowProvider.notifier).setPlace(const PlaceItem(id: 6));
      expect(c.read(createEventFlowProvider)!.courtIds, isEmpty);
    });

    test('attendance deadline is clamped to 1-23 hours / 1-7 days and resets on unit change', () {
      final c = container();
      final flow = c.read(createEventFlowProvider.notifier)
        ..setAttendanceUnit(99);
      expect(c.read(createEventFlowProvider)!.attendanceUnit, 23);
      flow.setAttendanceType(attendanceUnitDays);
      expect(c.read(createEventFlowProvider)!.attendanceUnit, 1);
      flow.setAttendanceUnit(99);
      expect(c.read(createEventFlowProvider)!.attendanceUnit, 7);
      flow.setAttendanceUnit(0);
      expect(c.read(createEventFlowProvider)!.attendanceUnit, 1);
    });

    test('rsvp limit never drops below the players limit', () {
      final c = container();
      final flow = c.read(createEventFlowProvider.notifier)..setPlayersLimit(4);
      expect(c.read(createEventFlowProvider)!.rsvpLimit, 4);
      flow.setRsvpLimit(2);
      expect(c.read(createEventFlowProvider)!.rsvpLimit, 4);
      flow.setRsvpLimit(7);
      flow.setPlayersLimit(3);
      expect(c.read(createEventFlowProvider)!.rsvpLimit, 7);
      flow.setPlayersLimit(0);
      expect(c.read(createEventFlowProvider)!.playersLimit, 1);
    });

    test('invitees toggle on and off', () {
      final c = container();
      const alex = AppUser(id: 8, firstName: 'Alex');
      c.read(createEventFlowProvider.notifier).toggleInvitee(alex);
      expect(c.read(createEventFlowProvider)!.invitees, hasLength(1));
      c.read(createEventFlowProvider.notifier).toggleInvitee(alex);
      expect(c.read(createEventFlowProvider)!.invitees, isEmpty);
    });
  });

  group('CreateEventSubmitter', () {
    ProviderContainer container(
      _FakeCreateEventRepository repo,
      EventDraft draft,
    ) {
      final c = ProviderContainer(
        overrides: [createEventRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      c.read(createEventFlowProvider.notifier).start();
      c.read(createEventFlowProvider.notifier).state = draft;
      return c;
    }

    test('looks up the venue timezone from its coordinates and the start time, then creates', () async {
      final repo = _FakeCreateEventRepository();
      final c = container(
        repo,
        _complete().copyWith(timezoneInfoId: () => null),
      );
      expect(
        await c.read(createEventSubmitterProvider.notifier).submit(),
        isTrue,
      );
      expect(repo.timezoneTime, '2026-11-03T18:05Z');
      final event = repo.body!['event'] as Map<String, dynamic>;
      expect(
        (event['event_schedule_options_attributes'] as List)
            .single['timezone_info_id'],
        42,
      );
      expect(c.read(createEventSubmitterProvider).createdEventId, 500);
    });

    test('a resolved timezone is not looked up again; missing coordinates skip the lookup', () async {
      final repo = _FakeCreateEventRepository();
      final c = container(repo, _complete());
      await c.read(createEventSubmitterProvider.notifier).submit();
      expect(repo.timezoneCalls, 0);

      final repo2 = _FakeCreateEventRepository();
      final c2 = container(
        repo2,
        _complete().copyWith(
          place: () => const PlaceItem(id: 5),
          timezoneInfoId: () => null,
        ),
      );
      await c2.read(createEventSubmitterProvider.notifier).submit();
      expect(repo2.timezoneCalls, 0);
      final event = repo2.body!['event'] as Map<String, dynamic>;
      expect(
        (event['event_schedule_options_attributes'] as List).single.containsKey(
          'timezone_info_id',
        ),
        isFalse,
      );
    });

    test(
      'server rejection surfaces as a failure and creates nothing',
      () async {
        final repo = _FakeCreateEventRepository()
          ..failure = const ServerFailure(
            422,
            'Start time must be in the future',
          );
        final c = container(repo, _complete());
        expect(
          await c.read(createEventSubmitterProvider.notifier).submit(),
          isFalse,
        );
        final failure =
            c.read(createEventSubmitterProvider).failure as ServerFailure;
        expect(failure.message, 'Start time must be in the future');
        expect(c.read(createEventSubmitterProvider).createdEventId, isNull);
      },
    );

    test(
      'success without an event id in the response still completes',
      () async {
        final repo = _FakeCreateEventRepository()..createdId = null;
        final c = container(repo, _complete());
        expect(
          await c.read(createEventSubmitterProvider.notifier).submit(),
          isTrue,
        );
        expect(c.read(createEventSubmitterProvider).createdEventId, isNull);
      },
    );
  });
}
