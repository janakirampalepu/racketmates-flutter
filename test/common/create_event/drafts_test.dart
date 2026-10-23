import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/create_event/draft_codec.dart';
import 'package:racketmates/common/create_event/drafts_api.dart';
import 'package:racketmates/common/create_event/drafts_repository.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/create_event/scoring.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/users/models/app_user.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object body = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _venue = PlaceItem(id: 1, name: 'Central Courts');
const _ann = AppUser(id: 11, firstName: 'Ann', lastName: 'Lee');
const _bo = AppUser(id: 12, firstName: 'Bo', lastName: 'Chan');
const _coach = AppUser(id: 13, firstName: 'Cy', lastName: 'Park');
const _team = Team(id: 31, name: 'Smashers');
const _rival = Team(id: 32, name: 'Rivals');

EventDraft _drill() => EventDraft(
  eventType: 'et_practice_drill',
  sport: SportKey.tennis,
  place: _venue,
  start: DateTime(2026, 11, 2, 19),
  durationMinutes: 90,
  courtIds: const [10],
  invitees: const [_ann],
  playersLimit: 4,
  rsvpLimit: 4,
  notes: 'Bring balls',
  timezoneInfoId: 5,
);

Future<ResumedDraft> _resume(Map<String, dynamic> body, {int id = 77}) =>
    resumeDraft(
      parseDraftRequest(body),
      draftEventId: id,
      users: (ids) async => [
        for (final u in const [_ann, _bo, _coach])
          if (ids.contains(u.id)) u,
      ],
      place: (id) async => _venue,
      team: (id) async => id == 31 ? _team : _rival,
    );

void main() {
  group('saving a draft', () {
    test('only the event type is needed', () {
      final body = buildCreateEventBody(
        const EventDraft(eventType: 'et_practice_drill'),
        asDraft: true,
        screen: CreateEventStep.sport,
      );
      final e = body['event'] as Map<String, dynamic>;
      expect(e['request_save_as_draft'], isTrue);
      expect(e['event_screen'], 'es_sports_type');
      expect(e.containsKey('sport_type'), isFalse);
      expect(e.containsKey('event_schedule_options_attributes'), isFalse);
      expect(e.containsKey('request_draft_event_id'), isFalse);
    });

    test('a draft without a type cannot be saved', () {
      expect(
        () => buildCreateEventBody(const EventDraft(), asDraft: true),
        throwsStateError,
      );
    });

    test('a real event still needs everything', () {
      expect(
        () => buildCreateEventBody(
          const EventDraft(eventType: 'et_practice_drill'),
        ),
        throwsStateError,
      );
    });

    test('a complete event is the same body with the draft flag off', () {
      final real = buildCreateEventBody(_drill())['event'] as Map;
      final draft =
          buildCreateEventBody(_drill(), asDraft: true)['event'] as Map;
      expect(real['request_save_as_draft'], isFalse);
      expect(draft['request_save_as_draft'], isTrue);
      expect(
        {...draft}..remove('request_save_as_draft'),
        {...real}..remove('request_save_as_draft'),
      );
    });

    test('a resumed draft names the draft it replaces, saved or created', () {
      final resumed = _drill().copyWith(draftEventId: () => 77);
      expect(
        (buildCreateEventBody(resumed, asDraft: true)['event']
            as Map)['request_draft_event_id'],
        77,
      );
      expect(
        (buildCreateEventBody(resumed)['event']
            as Map)['request_draft_event_id'],
        77,
      );
    });

    test(
      'a team event whose team is not chosen yet leaves out the originator',
      () {
        final body =
            buildCreateEventBody(
                  const EventDraft(
                    eventType: 'et_practice_drill',
                    forTeam: true,
                  ),
                  asDraft: true,
                )['event']
                as Map;
        expect(body.containsKey('originator_type'), isFalse);
        expect(body.containsKey('originator_id'), isFalse);
      },
    );

    test('a game without scoring or opponent yet is still a draft', () {
      final body =
          buildCreateEventBody(
                const EventDraft(
                  eventType: 'et_competitive',
                  sport: SportKey.tennis,
                  forTeam: true,
                  team: _team,
                  matches: [MatchDraft(matchType: MatchKeys.singles)],
                ),
                asDraft: true,
                screen: CreateEventStep.teamDynamics,
              )['event']
              as Map;
      expect(body.containsKey('scoring_format'), isFalse);
      expect(body['opponent_team_type'], 'ott_within_team');
      expect(body['event_screen'], 'es_event_dynamics_selection');
    });

    test('routes map back to wizard steps', () {
      for (final step in CreateEventStep.values) {
        expect(AppRoutes.stepForRoute(AppRoutes.routeForStep(step)), step);
      }
      expect(AppRoutes.stepForRoute('/home'), isNull);
    });
  });

  group('reading a draft back', () {
    test('what was saved is what comes back', () async {
      final body = buildCreateEventBody(
        _drill(),
        asDraft: true,
        screen: CreateEventStep.settings,
      );
      final snapshot = parseDraftRequest(body);
      expect(snapshot.eventType, 'et_practice_drill');
      expect(snapshot.sport, SportKey.tennis);
      expect(snapshot.inviteeIds, [11]);
      expect(snapshot.placeId, 1);
      expect(snapshot.start, DateTime(2026, 11, 2, 19));
      expect(snapshot.durationMinutes, 90);
      expect(snapshot.timezoneInfoId, 5);
      expect(snapshot.courtIds, [10]);
      expect(snapshot.notes, 'Bring balls');
      expect(snapshot.screen, 'es_general_settings');

      final resumed = await _resume(body);
      final d = resumed.draft;
      expect(d.eventType, 'et_practice_drill');
      expect(d.invitees.map((u) => u.id), [11]);
      expect(d.place?.name, 'Central Courts');
      expect(d.start, DateTime(2026, 11, 2, 19));
      expect(d.courtIds, [10]);
      expect(d.playersLimit, 4);
      expect(d.draftEventId, 77);
      expect(resumed.step, CreateEventStep.settings);
    });

    test(
      'the draft may be wrapped in event or not, and name lists either way',
      () {
        final flat = parseDraftRequest({
          'event_type': 'et_practice_drill',
          'event_schedule_options': [
            {'place_id': 1, 'start_time': '2026-11-02T19:00Z', 'duration': 60},
          ],
          'event_participants': [
            {
              'user': {'id': 11, 'first_name': 'Ann'},
              'is_coach': false,
            },
          ],
        });
        expect(flat.placeId, 1);
        expect(flat.inviteeIds, [11]);
        expect(flat.knownUsers[11]?.firstName, 'Ann');
      },
    );

    test('coaches and invited players are told apart', () async {
      final body = buildCreateEventBody(
        EventDraft(
          eventType: 'et_group_lesson',
          sport: SportKey.tennis,
          coaches: const [_coach],
          invitees: const [_ann],
        ),
        asDraft: true,
        screen: CreateEventStep.coaches,
      );
      final d = (await _resume(body)).draft;
      expect(d.coaches.map((u) => u.id), [13]);
      expect(d.invitees.map((u) => u.id), [11]);
    });

    test('a game keeps its matches, players, scoring and team', () async {
      final slotTop = const MatchSlot(
        MatchKeys.sideTop,
        MatchKeys.positionCenter,
      );
      final slotBottom = const MatchSlot(
        MatchKeys.sideBottom,
        MatchKeys.positionCenter,
      );
      final draft = EventDraft(
        eventType: 'et_competitive',
        sport: SportKey.tennis,
        forTeam: true,
        team: _team,
        opponent: OpponentKind.selectTeam,
        opponentTeam: _rival,
        opponentIsHome: true,
        scoring: const ScoringChoice(
          format: 'sf_best_of_3_sets',
          minimumScore: 2,
        ),
        matches: [
          MatchDraft(
            matchType: MatchKeys.singles,
            players: {slotTop: _ann, slotBottom: _bo},
          ),
        ],
        assignNow: true,
        courtIds: const [10],
        place: _venue,
        start: DateTime(2026, 11, 2, 19),
      );
      final resumed = await _resume(
        buildCreateEventBody(
          draft,
          asDraft: true,
          screen: CreateEventStep.assignPlayers,
        ),
      );
      final d = resumed.draft;
      expect(d.forTeam, isTrue);
      expect(d.team?.id, 31);
      expect(d.opponent, OpponentKind.selectTeam);
      expect(d.opponentTeam?.id, 32);
      expect(d.opponentIsHome, isTrue);
      expect(d.scoring?.format, 'sf_best_of_3_sets');
      expect(d.scoring?.minimumScore, 2);
      expect(d.assignNow, isTrue);
      expect(d.matches.single.matchType, MatchKeys.singles);
      expect(d.matches.single.players[slotTop]?.id, 11);
      expect(d.matches.single.players[slotBottom]?.id, 12);
      expect(d.courtIds, [10]);
      expect(resumed.step, CreateEventStep.assignPlayers);
    });

    test('a step the type no longer has falls back to the review', () async {
      final body = buildCreateEventBody(_drill(), asDraft: true);
      ((body['event'] as Map)['event_screen']);
      (body['event'] as Map<String, dynamic>)['event_screen'] =
          'es_courts_addition';
      expect((await _resume(body)).step, CreateEventStep.review);
      (body['event'] as Map<String, dynamic>)['event_screen'] = null;
      expect((await _resume(body)).step, CreateEventStep.review);
    });

    test('a type this build cannot create is not resumable', () {
      expect(
        () => parseDraftRequest({
          'event': {'event_type': 'et_future'},
        }),
        throwsA(isA<DraftNotResumable>()),
      );
      expect(() => parseDraftRequest({}), throwsA(isA<DraftNotResumable>()));
    });
  });

  group('drafts API', () {
    late _Adapter adapter;
    late DraftsRepositoryImpl repo;

    setUp(() {
      adapter = _Adapter();
      repo = DraftsRepositoryImpl(
        DraftsApi(
          Dio(BaseOptions(baseUrl: 'https://api.example.test'))
            ..httpClientAdapter = adapter,
        ),
      );
    });

    test('the list asks for the draft status', () async {
      adapter.body = {
        'schedule_items': [
          {
            'event_id': 5,
            'event_type': 'et_practice_drill',
            'sport_type': 'st_tennis',
            'courts_label': '2 courts',
            'last_updated_at': '2026-10-20T10:00:00Z',
          },
          null,
        ],
      };
      final list = await repo.list(userIds: ['7']);
      final q = adapter.requests.single.uri;
      expect(adapter.requests.single.path, 'schedule/drafts');
      expect(q.queryParametersAll['status'], ['es_draft']);
      expect(q.queryParametersAll['user_ids[]'], ['7']);
      expect(list.single.eventId, 5);
      expect(list.single.updatedAt, DateTime.utc(2026, 10, 20, 10));
    });

    test('a draft is read in the full view', () async {
      adapter.body = {
        'event': {'event_type': 'et_practice_drill'},
      };
      final body = await repo.request(5, hourFormat: 12);
      final q = adapter.requests.single.uri;
      expect(adapter.requests.single.path, 'events/5');
      expect(q.queryParametersAll['view_type'], ['full']);
      expect(q.queryParametersAll['hour_format'], ['12']);
      expect(body['event'], isA<Map<String, dynamic>>());
    });

    test('an answer that is not an object is a parse failure', () async {
      adapter.body = ['x'];
      await expectLater(
        repo.request(5, hourFormat: 12),
        throwsA(isA<ParseFailure>()),
      );
    });

    test('deleting is a DELETE of the event', () async {
      await repo.delete(5);
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, 'events/5');
    });

    test('server errors become failures', () async {
      adapter.status = 404;
      await expectLater(repo.delete(5), throwsA(isA<AppFailure>()));
    });
  });
}
