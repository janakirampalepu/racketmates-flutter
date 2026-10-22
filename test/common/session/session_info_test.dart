import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/native_session.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/auth/token_refresher.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/session/session_api.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/common/session/session_info_repository.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      options.method == 'GET'
          ? jsonEncode(apiFixture('current_session_info'))
          : '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProviderContainer _container({
  FakeSessionInfoRepository? repo,
  String? deviceTimezone = 'America/New_York',
  SessionToken? signedIn,
}) {
  final c = ProviderContainer(
    overrides: [
      environmentConfigProvider.overrideWithValue(testConfig),
      tokenStoreProvider.overrideWithValue(
        InMemoryTokenStore(signedIn ?? token()),
      ),
      authApiProvider.overrideWithValue(FakeAuthApi()),
      nativeSessionSourceProvider.overrideWithValue(FakeNativeSessionSource()),
      sessionInfoRepositoryProvider.overrideWithValue(
        repo ?? FakeSessionInfoRepository(),
      ),
      deviceTimezoneOrNullProvider.overrideWith((ref) async => deviceTimezone),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

SessionInfoResponse _response({String? timezone, bool full = true}) =>
    SessionInfoResponse(
      user: SessionInfoUser(
        id: 7,
        hasFullFeatureAccess: full,
        timezoneIdentifier: timezone,
      ),
    );

Future<void> _signIn(ProviderContainer c) =>
    c.read(sessionControllerProvider.notifier).restore();

void main() {
  group('models', () {
    final response = SessionInfoResponse.fromJson(
      apiFixture('current_session_info'),
    );

    test('user, permissions and subscription are read', () {
      final u = response.user!;
      expect(u.id, 7);
      expect(u.roles, ['ur_player', 'ur_coach']);
      expect(u.timezoneIdentifier, 'America/Chicago');
      expect(u.supportChatRoomUrl, 'sendbird_group_channel_1');
      expect(u.permission('teams.create')?.access, 'up_requires_subscription');
      expect(u.permission('teams.create')?.message, 'Upgrade to create teams');
      expect(u.permission('league.create')?.access, 'up_not_available');
      expect(u.permission('nothing.here'), isNull);
      expect(response.subscription?.purchaseTokens, ['tok-1']);
    });

    test('trial and subscription flags', () {
      final u = response.user!;
      expect(u.isSubscribed, isFalse);
      expect(u.isTrial, isTrue); // no store subscription, 12 days left
      expect(u.isTrialEnded, isFalse);

      const ended = SessionInfoUser(
        hasFullFeatureAccess: false,
        trialRemainingDays: 0,
      );
      expect(ended.isTrial, isFalse);
      expect(ended.isTrialEnded, isTrue);

      const subscribed = SessionInfoUser(
        hasFullFeatureAccess: true,
        subscribedDeviceType: 'dt_android',
        trialRemainingDays: 5,
      );
      expect(subscribed.isSubscribed, isTrue);
      expect(subscribed.isTrial, isFalse); // bought, so no longer a trial
      expect(subscribed.isTrialEnded, isFalse);
      expect(const SessionInfoUser().isSubscribed, isFalse);
    });
  });

  group('repository', () {
    test(
      'asks for this app and version, and writes the zone as JSON',
      () async {
        final adapter = _Adapter();
        final repo = SessionInfoRepositoryImpl(
          SessionApi(
            Dio(BaseOptions(baseUrl: 'https://api.example.test'))
              ..httpClientAdapter = adapter,
          ),
          appType: 'android',
          version: '26.6.2',
        );
        final info = await repo.fetch();
        expect(info.user?.id, 7);
        final get = adapter.requests.single;
        expect(get.method, 'GET');
        expect(get.path, 'current_session/session_info');
        expect(get.uri.queryParameters, {
          'app_type': 'android',
          'version': '26.6.2',
        });

        await repo.updateTimeZone('Europe/Paris');
        final put = adapter.requests.last;
        expect(put.method, 'PUT');
        expect(put.path, 'current_session/update_time_zone');
        expect(put.data, {'timezone_identifier': 'Europe/Paris'});
      },
    );
  });

  group('access decision', () {
    AccessInfo info(String access) => AccessInfo(access: access);

    test('follows the native states', () {
      expect(decideAccess(null, subscribed: false), AccessDecision.allowed);
      expect(
        decideAccess(info('up_enabled'), subscribed: false),
        AccessDecision.allowed,
      );
      expect(
        decideAccess(info('up_not_available'), subscribed: true),
        AccessDecision.hidden,
      );
      expect(
        decideAccess(info('up_disabled'), subscribed: true),
        AccessDecision.blocked,
      );
      expect(
        decideAccess(info('up_requires_subscription'), subscribed: false),
        AccessDecision.needsSubscription,
      );
      // Subscribed users get through a subscription gate.
      expect(
        decideAccess(info('up_requires_subscription'), subscribed: true),
        AccessDecision.allowed,
      );
      expect(
        decideAccess(info('something_new'), subscribed: false),
        AccessDecision.allowed,
      );
    });
  });

  group('timezone rule', () {
    test('out of date when empty or different', () {
      expect(timezoneNeedsUpdate(server: null, device: 'A'), isTrue);
      expect(timezoneNeedsUpdate(server: '', device: 'A'), isTrue);
      expect(timezoneNeedsUpdate(server: 'B', device: 'A'), isTrue);
      expect(timezoneNeedsUpdate(server: 'A', device: 'A'), isFalse);
    });
  });

  group('controller', () {
    test('refresh stores the answer', () async {
      final repo = FakeSessionInfoRepository(
        response: SessionInfoResponse.fromJson(
          apiFixture('current_session_info'),
        ),
      );
      final c = _container(repo: repo);
      await _signIn(c);
      expect(c.read(sessionInfoControllerProvider).loaded, isFalse);
      await c.read(sessionInfoControllerProvider.notifier).refresh();
      final state = c.read(sessionInfoControllerProvider);
      expect(state.loaded, isTrue);
      expect(state.isSubscribed, isFalse);
      expect(state.user?.supportChatRoomUrl, 'sendbird_group_channel_1');
      expect(state.subscription?.purchaseTokens, ['tok-1']);
    });

    test('nothing is asked while signed out', () async {
      final repo = FakeSessionInfoRepository();
      final c = _container(repo: repo);
      // Not restored yet: still SessionRestoring.
      await c.read(sessionInfoControllerProvider.notifier).refresh();
      expect(repo.fetches, 0);
    });

    test('a refresh already running is not repeated', () async {
      final repo = FakeSessionInfoRepository();
      final c = _container(repo: repo);
      await _signIn(c);
      final controller = c.read(sessionInfoControllerProvider.notifier);
      await Future.wait([controller.refresh(), controller.refresh()]);
      expect(repo.fetches, 1);
      await controller.refresh(); // a later one is fine
      expect(repo.fetches, 2);
    });

    test('a failure keeps what was known', () async {
      final repo = FakeSessionInfoRepository(
        response: _response(timezone: 'America/New_York'),
      );
      final c = _container(repo: repo);
      await _signIn(c);
      final controller = c.read(sessionInfoControllerProvider.notifier);
      await controller.refresh();
      repo.fetchFailure = const OfflineFailure();
      await controller.refresh();
      expect(c.read(sessionInfoControllerProvider).loaded, isTrue);
      expect(repo.timezoneUpdates, isEmpty);
    });

    test('a different device zone is sent', () async {
      final repo = FakeSessionInfoRepository(
        response: _response(timezone: 'America/Chicago'),
      );
      final c = _container(repo: repo, deviceTimezone: 'Europe/Paris');
      await _signIn(c);
      await c.read(sessionInfoControllerProvider.notifier).refresh();
      expect(repo.timezoneUpdates, ['Europe/Paris']);
    });

    test('the same zone is left alone', () async {
      final repo = FakeSessionInfoRepository(
        response: _response(timezone: 'Europe/Paris'),
      );
      final c = _container(repo: repo, deviceTimezone: 'Europe/Paris');
      await _signIn(c);
      await c.read(sessionInfoControllerProvider.notifier).refresh();
      expect(repo.timezoneUpdates, isEmpty);
    });

    test('a user without a zone gets the device zone', () async {
      final repo = FakeSessionInfoRepository(response: _response());
      final c = _container(repo: repo, deviceTimezone: 'Asia/Tokyo');
      await _signIn(c);
      await c.read(sessionInfoControllerProvider.notifier).refresh();
      expect(repo.timezoneUpdates, ['Asia/Tokyo']);
    });

    test(
      'a device that cannot tell its zone never overwrites the server',
      () async {
        final repo = FakeSessionInfoRepository(
          response: _response(timezone: 'America/Chicago'),
        );
        final c = _container(repo: repo, deviceTimezone: null);
        await _signIn(c);
        await c.read(sessionInfoControllerProvider.notifier).refresh();
        expect(repo.timezoneUpdates, isEmpty);
      },
    );

    test('a failed zone update does not lose the session info', () async {
      final repo = FakeSessionInfoRepository(response: _response())
        ..updateFailure = const OfflineFailure();
      final c = _container(repo: repo, deviceTimezone: 'Asia/Tokyo');
      await _signIn(c);
      await c.read(sessionInfoControllerProvider.notifier).refresh();
      expect(repo.timezoneUpdates, ['Asia/Tokyo']);
      expect(c.read(sessionInfoControllerProvider).loaded, isTrue);
    });
  });

  group('sync', () {
    test('a session starting loads it; a new token loads it again; sign-out forgets it', () async {
      final repo = FakeSessionInfoRepository(
        response: _response(timezone: 'America/New_York'),
      );
      final c = _container(repo: repo);
      c.listen(sessionInfoSyncProvider, (_, _) {});
      await _signIn(c);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repo.fetches, 1);
      expect(c.read(sessionInfoControllerProvider).loaded, isTrue);

      await c
          .read(sessionControllerProvider.notifier)
          .signedIn(token(access: 'access-2'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repo.fetches, 2);

      await c.read(sessionControllerProvider.notifier).expire();
      expect(c.read(sessionControllerProvider), isA<SignedOut>());
      expect(c.read(sessionInfoControllerProvider).loaded, isFalse);
    });
  });

  group('token refresh', () {
    test('tells the app a new token is stored', () async {
      final store = InMemoryTokenStore(token());
      final refreshed = <String?>[];
      final refresher = TokenRefresher(
        api: FakeAuthApi(tokenResults: [token(access: 'new')]),
        store: store,
        config: testConfig,
        onRefreshed: (t) => refreshed.add(t.accessToken),
      );
      final outcome = await refresher.refresh();
      expect(outcome, isA<Refreshed>());
      expect(refreshed, ['new']);
      // A failed refresh reports nothing.
      final failing = TokenRefresher(
        api: FakeAuthApi(
          tokenResults: [
            DioException(
              requestOptions: RequestOptions(),
              response: Response(
                requestOptions: RequestOptions(),
                statusCode: 500,
              ),
            ),
          ],
        ),
        store: InMemoryTokenStore(token()),
        config: testConfig,
        onRefreshed: (t) => refreshed.add('unexpected'),
      );
      expect(await failing.refresh(), isA<RefreshFailed>());
      expect(refreshed, ['new']);
    });
  });
}
