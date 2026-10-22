import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/chat/chat_api.dart';
import 'package:racketmates/common/chat/chat_repository.dart';
import 'package:racketmates/common/chat/event_chat.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/session/access.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object body = {
    'chat_room': {'id': 3, 'channel_url': 'sendbird_group_channel_3'},
  };

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

AccessInfo _perm(String access, [String? message]) =>
    AccessInfo(access: access, message: message);

EventDetails _event({
  Map<String, AccessInfo>? permissions,
  ChatRoomRef? players,
  ChatRoomRef? captains,
  String? originatorType,
  List<EventTeamRef>? teams,
  List<CurrentUserEventDetail>? mine,
  List<EventParticipant>? participants,
}) => EventDetails(
  id: 101,
  originatorType: originatorType,
  userPermissions: permissions,
  playerChatRoom: players,
  captainsChatRoom: captains,
  eventTeams: teams,
  currentUserEventDetails: mine,
  eventParticipants: participants,
);

void main() {
  group('chat room API contracts', () {
    late _Adapter adapter;
    late ChatRepositoryImpl repo;

    setUp(() {
      adapter = _Adapter();
      repo = ChatRepositoryImpl(
        ChatApi(
          Dio(BaseOptions(baseUrl: 'https://api.example.test'))
            ..httpClientAdapter = adapter,
        ),
      );
    });

    test('players chat room: PUT with the team id', () async {
      expect(
        await repo.playersChatRoom(101, teamId: 9),
        'sendbird_group_channel_3',
      );
      final r = adapter.requests.single;
      expect(r.method, 'PUT');
      expect(r.path, 'events/101/setup_players_chat_room');
      expect(r.data, {'team_id': 9});
    });

    test('players chat room without a team sends a null team id', () async {
      await repo.playersChatRoom(101);
      expect(adapter.requests.single.data, {'team_id': null});
    });

    test('captains chat room: PUT without a body', () async {
      await repo.captainsChatRoom(101);
      final r = adapter.requests.single;
      expect(r.method, 'PUT');
      expect(r.path, 'events/101/setup_captains_chat_room');
    });

    test('one-to-one room: POST the two uids as a direct room', () async {
      await repo.directChatRoom(ownUid: 'a', otherUid: 'b');
      final r = adapter.requests.single;
      expect(r.method, 'POST');
      expect(r.path, 'chat_rooms');
      expect(r.data, {
        'chat_room': {
          'chat_room_type': 'crt_direct',
          'uids': ['a', 'b'],
        },
      });
    });

    test(
      'player search excludes the user and wants signed-up players',
      () async {
        adapter.body = {
          'users': [
            {'id': 5, 'uid': 'u5', 'first_name': 'Ann'},
          ],
        };
        final players = await repo.searchPlayers(' an ', excludeUserId: 7);
        final r = adapter.requests.single;
        expect(r.path, 'users');
        expect(r.uri.queryParametersAll['search'], ['an']);
        expect(r.uri.queryParametersAll['exclude_user_ids[]'], ['7']);
        expect(r.uri.queryParametersAll['is_signed_up'], ['true']);
        expect(players.single.uid, 'u5');
      },
    );

    test('an answer without a channel is a parse failure', () async {
      adapter.body = {
        'chat_room': {'id': 1},
      };
      await expectLater(
        repo.captainsChatRoom(101),
        throwsA(isA<ParseFailure>()),
      );
      adapter.body = {};
      await expectLater(
        repo.directChatRoom(ownUid: 'a', otherUid: 'b'),
        throwsA(isA<ParseFailure>()),
      );
    });

    test('server errors become failures', () async {
      adapter
        ..status = 403
        ..body = {'error_message': 'no'};
      await expectLater(repo.playersChatRoom(101), throwsA(isA<AppFailure>()));
    });
  });

  group('eventChatOptions', () {
    test('rooms whose permission is missing or not available are hidden', () {
      expect(eventChatOptions(_event(), subscribed: true), isEmpty);
      expect(
        eventChatOptions(
          _event(
            permissions: {
              'event.show_players_chat_room': _perm('up_not_available'),
            },
          ),
          subscribed: true,
        ),
        isEmpty,
      );
    });

    test('players first, then captains, each with its access rule', () {
      final options = eventChatOptions(
        _event(
          permissions: {
            'event.show_captains_chat_room': _perm('up_disabled', 'Not yet'),
            'event.show_players_chat_room': _perm('up_enabled'),
          },
        ),
        subscribed: true,
      );
      expect(options.map((o) => o.kind), [
        EventChatKind.players,
        EventChatKind.captains,
      ]);
      expect(options[0].decision, AccessDecision.allowed);
      expect(options[1].decision, AccessDecision.blocked);
      expect(options[1].message, 'Not yet');
    });

    test('a room that needs a subscription offers it to free users only', () {
      final event = _event(
        permissions: {
          'event.show_players_chat_room': _perm('up_requires_subscription'),
        },
      );
      expect(
        eventChatOptions(event, subscribed: false).single.decision,
        AccessDecision.needsSubscription,
      );
      expect(
        eventChatOptions(event, subscribed: true).single.decision,
        AccessDecision.allowed,
      );
    });

    test('an existing room carries its channel', () {
      final options = eventChatOptions(
        _event(
          permissions: {
            'event.show_players_chat_room': _perm('up_enabled'),
            'event.show_captains_chat_room': _perm('up_enabled'),
          },
          players: const ChatRoomRef(id: 1, channelUrl: 'players-url'),
          captains: const ChatRoomRef(id: 2, channelUrl: ''),
        ),
        subscribed: true,
      );
      expect(options[0].channelUrl, 'players-url');
      expect(options[1].channelUrl, isNull); // empty means not created yet
    });

    test("the user's team room is used when the event has none of its own", () {
      final options = eventChatOptions(
        _event(
          permissions: {'event.show_players_chat_room': _perm('up_enabled')},
          originatorType: 'team',
          teams: const [
            EventTeamRef(
              team: EventTeamIdRef(id: 1),
              playersChatRoom: ChatRoomRef(channelUrl: 'team-1'),
            ),
            EventTeamRef(
              team: EventTeamIdRef(id: 2),
              playersChatRoom: ChatRoomRef(channelUrl: 'team-2'),
            ),
          ],
          mine: const [CurrentUserEventDetail(teamId: 2)],
        ),
        subscribed: true,
      );
      expect(options.single.channelUrl, 'team-2');
    });
  });

  group('loginTeamId', () {
    test('own participation first', () {
      expect(
        loginTeamId(
          _event(
            originatorType: 'team',
            mine: const [CurrentUserEventDetail(teamId: 4)],
            teams: const [EventTeamRef(team: EventTeamIdRef(id: 1))],
          ),
          7,
        ),
        4,
      );
    });

    test('then the participant list entry of the user', () {
      expect(
        loginTeamId(
          _event(
            originatorType: 'team',
            participants: const [
              EventParticipant(userId: 8, teamId: 1),
              EventParticipant(userId: 7, teamId: 3),
            ],
          ),
          7,
        ),
        3,
      );
    });

    test('then the first team of a team event', () {
      expect(
        loginTeamId(
          _event(
            originatorType: 'team',
            teams: const [
              EventTeamRef(team: EventTeamIdRef(id: 5)),
              EventTeamRef(team: EventTeamIdRef(id: 6)),
            ],
          ),
          7,
        ),
        5,
      );
    });

    test('events without teams have none', () {
      expect(
        loginTeamId(
          _event(teams: const [EventTeamRef(team: EventTeamIdRef(id: 5))]),
          7,
        ),
        isNull,
      );
    });
  });

  test('the event JSON carries the chat rooms and teams', () {
    final event = EventDetails.fromJson({
      'id': 1,
      'player_chat_room': {'id': 1, 'channel_url': 'p'},
      'captains_chat_room': {'id': 2, 'channel_url': 'c'},
      'event_teams': [
        {
          'team': {'id': 9},
          'players_chat_room': {'id': 3, 'channel_url': 't'},
        },
      ],
      'current_user_event_details': [
        {'team_id': 9},
      ],
      'event_participants': [
        {'user_id': 7, 'team_id': 9},
      ],
    });
    expect(event.playerChatRoom?.channelUrl, 'p');
    expect(event.captainsChatRoom?.channelUrl, 'c');
    expect(event.eventTeams?.single.team?.id, 9);
    expect(event.eventTeams?.single.playersChatRoom?.channelUrl, 't');
    expect(event.currentUserEventDetails?.single.teamId, 9);
    expect(event.eventParticipants?.single.teamId, 9);
  });
}
