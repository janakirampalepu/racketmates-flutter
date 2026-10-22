import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/app/config/environment_config.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/native_session.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/chat/chat_api.dart';
import 'package:racketmates/common/chat/chat_client.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/common/chat/chat_repository.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/notifications/push_platform.dart';

import '../../support/fakes.dart';

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

const _user = SessionToken(
  accessToken: 'a',
  refreshToken: 'r',
  user: SessionTokenUser(id: 7, uid: 'uid-7'),
);

ProviderContainer _container({
  FakeChatClient? client,
  FakeChatRepository? repository,
  FakePushPlatform? push,
  String appId = 'app',
  SessionToken? session = _user,
}) {
  final c = ProviderContainer(
    overrides: [
      environmentConfigProvider.overrideWithValue(
        EnvironmentConfig(
          environment: AppEnvironment.qa,
          apiBaseUrl: 'https://api.example.test',
          apiVersion: 'v',
          oauthClientId: 'id',
          oauthClientSecret: 'secret',
          sendbirdAppId: appId,
        ),
      ),
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
      authApiProvider.overrideWithValue(FakeAuthApi()),
      nativeSessionSourceProvider.overrideWithValue(FakeNativeSessionSource()),
      chatClientProvider.overrideWithValue(client ?? FakeChatClient()),
      chatRepositoryProvider.overrideWithValue(
        repository ?? FakeChatRepository(),
      ),
      pushPlatformProvider.overrideWithValue(push ?? FakePushPlatform()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<ProviderContainer> _signedIn({
  FakeChatClient? client,
  FakeChatRepository? repository,
  FakePushPlatform? push,
  String appId = 'app',
}) async {
  final c = _container(
    client: client,
    repository: repository,
    push: push,
    appId: appId,
  );
  await c.read(sessionControllerProvider.notifier).restore();
  return c;
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('ChatRepository contracts', () {
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

    test('token is read from the response', () async {
      adapter.body = {'token': 'abc', 'expires_at': 1};
      expect(await repo.sendbirdToken(), 'abc');
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, 'current_session/sendbird_token');
    });

    test('a token wrapped in data is accepted', () async {
      adapter.body = {
        'data': {'token': 'wrapped'},
      };
      expect(await repo.sendbirdToken(), 'wrapped');
    });

    test('a missing or empty token is a parse failure', () async {
      adapter.body = {'expires_at': 1};
      await expectLater(repo.sendbirdToken(), throwsA(isA<ParseFailure>()));
      adapter.body = {'token': ''};
      await expectLater(repo.sendbirdToken(), throwsA(isA<ParseFailure>()));
      adapter.body = ['x'];
      await expectLater(repo.sendbirdToken(), throwsA(isA<ParseFailure>()));
    });

    test('server errors become failures', () async {
      adapter
        ..status = 500
        ..body = {'error_message': 'down'};
      await expectLater(repo.sendbirdToken(), throwsA(isA<AppFailure>()));
      await expectLater(repo.setupDefaultRooms(), throwsA(isA<AppFailure>()));
    });

    test('default rooms are set up with a POST', () async {
      await repo.setupDefaultRooms();
      final r = adapter.requests.single;
      expect(r.method, 'POST');
      expect(r.path, 'current_session/setup_default_chat_rooms');
    });
  });

  group('ChatController', () {
    test('connects with the user uid and a fresh token', () async {
      final client = FakeChatClient();
      final c = await _signedIn(client: client);
      await c.read(chatControllerProvider.notifier).connect();
      expect(c.read(chatControllerProvider), ChatStatus.connected);
      expect(client.connects.single.userId, 'uid-7');
      expect(client.connects.single.token, 'sb-token-1');
    });

    test('a build without a Sendbird app id is unavailable', () async {
      final client = FakeChatClient();
      final c = await _signedIn(client: client, appId: '');
      await c.read(chatControllerProvider.notifier).connect();
      expect(c.read(chatControllerProvider), ChatStatus.unavailable);
      expect(client.inits, 0);
    });

    test('an expired token is replaced once', () async {
      final client = FakeChatClient()
        ..results = [
          ChatConnectResult.tokenInvalid,
          ChatConnectResult.connected,
        ];
      final repo = FakeChatRepository(tokens: ['old', 'new']);
      final c = await _signedIn(client: client, repository: repo);
      await c.read(chatControllerProvider.notifier).connect();
      expect(c.read(chatControllerProvider), ChatStatus.connected);
      expect(client.connects.map((e) => e.token), ['old', 'new']);
      expect(repo.tokenRequests, 2);
    });

    test('a token rejected twice fails', () async {
      final client = FakeChatClient()
        ..results = [ChatConnectResult.tokenInvalid];
      final c = await _signedIn(client: client);
      await c.read(chatControllerProvider.notifier).connect();
      expect(c.read(chatControllerProvider), ChatStatus.failed);
      expect(client.connects, hasLength(2));
    });

    test('failures: init, token request and connection', () async {
      var c = await _signedIn(client: FakeChatClient(initOk: false));
      await c.read(chatControllerProvider.notifier).connect();
      expect(c.read(chatControllerProvider), ChatStatus.failed);

      final repo = FakeChatRepository()..tokenFailure = const OfflineFailure();
      c = await _signedIn(repository: repo);
      await c.read(chatControllerProvider.notifier).connect();
      expect(c.read(chatControllerProvider), ChatStatus.failed);

      c = await _signedIn(
        client: FakeChatClient()..results = [ChatConnectResult.failed],
      );
      await c.read(chatControllerProvider.notifier).connect();
      expect(c.read(chatControllerProvider), ChatStatus.failed);
    });

    test('a failed connection can be retried', () async {
      final client = FakeChatClient()
        ..results = [ChatConnectResult.failed, ChatConnectResult.connected];
      final c = await _signedIn(client: client);
      final controller = c.read(chatControllerProvider.notifier);
      await controller.connect();
      expect(c.read(chatControllerProvider), ChatStatus.failed);
      await controller.connect();
      expect(c.read(chatControllerProvider), ChatStatus.connected);
    });

    test('connecting twice only connects once', () async {
      final client = FakeChatClient();
      final c = await _signedIn(client: client);
      final controller = c.read(chatControllerProvider.notifier);
      await Future.wait([controller.connect(), controller.connect()]);
      await controller.connect();
      expect(client.connects, hasLength(1));
    });

    test('nothing happens when signed out', () async {
      final client = FakeChatClient();
      final c = _container(client: client, session: null);
      await c.read(sessionControllerProvider.notifier).restore();
      await c.read(chatControllerProvider.notifier).connect();
      expect(c.read(chatControllerProvider), ChatStatus.idle);
      expect(client.inits, 0);
    });

    test(
      'after connecting the push token is registered and rooms set up',
      () async {
        final client = FakeChatClient();
        final repo = FakeChatRepository();
        final push = FakePushPlatform(available: true);
        final c = await _signedIn(client: client, repository: repo, push: push);
        await c.read(chatControllerProvider.notifier).connect();
        await _settle();
        expect(client.registered, ['device-token-1']);
        expect(repo.setups, 1);
        push.tokenController.add('device-token-2');
        await _settle();
        expect(client.registered, ['device-token-1', 'device-token-2']);
      },
    );

    test('a failing room setup does not break chat', () async {
      final repo = FakeChatRepository()..setupFailure = const OfflineFailure();
      final c = await _signedIn(repository: repo);
      await c.read(chatControllerProvider.notifier).connect();
      await _settle();
      expect(c.read(chatControllerProvider), ChatStatus.connected);
    });

    test('disconnect stops pushes, disconnects and resets', () async {
      final client = FakeChatClient();
      final push = FakePushPlatform(available: true);
      final c = await _signedIn(client: client, push: push);
      final controller = c.read(chatControllerProvider.notifier);
      await controller.connect();
      await _settle();
      await controller.disconnect();
      expect(c.read(chatControllerProvider), ChatStatus.idle);
      expect(client.unregistered, ['device-token-1']);
      expect(client.disconnects, 1);
      push.tokenController.add('late');
      await _settle();
      expect(client.registered, ['device-token-1']); // no longer listening
    });

    test('disconnecting while connecting abandons the connection', () async {
      final client = FakeChatClient();
      final c = await _signedIn(client: client);
      final controller = c.read(chatControllerProvider.notifier);
      final connecting = controller.connect();
      await controller.disconnect();
      await connecting;
      expect(c.read(chatControllerProvider), ChatStatus.idle);
    });

    test('unread count follows the client while connected', () async {
      final client = FakeChatClient()..unreadNow = 3;
      final c = await _signedIn(client: client);
      expect(c.read(chatUnreadProvider).value, isNull);
      final seen = <int>[];
      c.listen(chatUnreadProvider, (_, v) {
        if (v.hasValue) seen.add(v.requireValue);
      });
      await c.read(chatControllerProvider.notifier).connect();
      await _settle();
      client.unread.add(5);
      await _settle();
      expect(seen, containsAllInOrder([3, 5]));
    });
  });

  group('chat sync', () {
    test('connects on sign-in and disconnects on sign-out', () async {
      final client = FakeChatClient();
      final c = _container(client: client);
      c.listen(chatSyncProvider, (_, _) {});
      await c.read(sessionControllerProvider.notifier).restore();
      await _settle();
      expect(c.read(chatControllerProvider), ChatStatus.connected);
      await c.read(sessionControllerProvider.notifier).signOut();
      await _settle();
      expect(c.read(chatControllerProvider), ChatStatus.idle);
      expect(client.disconnects, greaterThanOrEqualTo(1));
    });
  });

  group('Sendbird push payload', () {
    test('the channel comes from the JSON payload', () {
      final route = routeForNotification({
        'sendbird': jsonEncode({
          'channel': {'channel_url': 'sendbird_group_channel_9'},
          'message': 'hi',
        }),
      });
      expect(
        route,
        isA<OpenChat>().having(
          (r) => r.channelUrl,
          'url',
          'sendbird_group_channel_9',
        ),
      );
    });

    test('a payload that is not JSON falls back to channel_url or none', () {
      expect(
        routeForNotification({'sendbird': 'nope', 'channel_url': 'c'}),
        isA<OpenChat>().having((r) => r.channelUrl, 'url', 'c'),
      );
      expect(
        routeForNotification({'sendbird': 'nope'}),
        isA<OpenChat>().having((r) => r.channelUrl, 'url', isNull),
      );
    });
  });
}
