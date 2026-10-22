import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/token_refresher.dart';
import 'package:racketmates/common/auth/token_store.dart';

import '../../support/fakes.dart';

void main() {
  late InMemoryTokenStore store;

  TokenRefresher refresher(FakeAuthApi api) =>
      TokenRefresher(api: api, store: store, config: testConfig);

  setUp(() => store = InMemoryTokenStore(token()));

  test('success stores the new token and sends the refresh grant', () async {
    final api = FakeAuthApi(tokenResults: [token(access: 'access-2')]);
    final outcome = await refresher(api).refresh();
    expect(outcome, isA<Refreshed>());
    expect((await store.read())!.accessToken, 'access-2');
    expect(api.tokenBodies.single, {
      'client_id': 'client-id',
      'client_secret': 'client-secret',
      'grant_type': 'refresh_token',
      'refresh_token': 'refresh-1',
    });
  });

  test('HTTP 400 expires the session immediately', () async {
    final api = FakeAuthApi(tokenResults: [httpError(400)]);
    expect(await refresher(api).refresh(), isA<SessionExpired>());
    expect(api.tokenCalls, 1);
  });

  test('HTTP 401 is retried and expires after 5 attempts', () async {
    final api = FakeAuthApi(tokenResults: List.filled(5, httpError(401)));
    expect(await refresher(api).refresh(), isA<SessionExpired>());
    expect(api.tokenCalls, 5);
  });

  test('HTTP 401 then success recovers', () async {
    final api = FakeAuthApi(
      tokenResults: [
        httpError(401),
        httpError(401),
        token(access: 'access-3'),
      ],
    );
    final outcome = await refresher(api).refresh();
    expect(outcome, isA<Refreshed>());
    expect(api.tokenCalls, 3);
  });

  test('network and server errors keep the session (RefreshFailed)', () async {
    for (final error in [connectionError(), httpError(503)]) {
      final api = FakeAuthApi(tokenResults: [error]);
      expect(await refresher(api).refresh(), isA<RefreshFailed>());
      expect((await store.read())!.accessToken, 'access-1');
    }
  });

  test('missing session or refresh token expires without a call', () async {
    final api = FakeAuthApi();
    store = InMemoryTokenStore();
    expect(await refresher(api).refresh(), isA<SessionExpired>());
    store = InMemoryTokenStore(const SessionToken(accessToken: 'a'));
    expect(await refresher(api).refresh(), isA<SessionExpired>());
    expect(api.tokenCalls, 0);
  });

  test('concurrent callers share one in-flight refresh', () async {
    final api = FakeAuthApi(tokenResults: [token(access: 'access-2')]);
    final r = refresher(api);
    final results = await Future.wait([r.refresh(), r.refresh(), r.refresh()]);
    expect(results.whereType<Refreshed>(), hasLength(3));
    expect(api.tokenCalls, 1);
  });

  test('stale token already replaced skips the network call', () async {
    final api = FakeAuthApi();
    final outcome = await refresher(api).refresh(staleAccessToken: 'older');
    expect(outcome, isA<Refreshed>());
    expect(api.tokenCalls, 0);
  });

  test('token expiry rule is created_at + expires_in <= now', () {
    final t = token(createdAt: 1000, expiresIn: 100);
    expect(
      t.isExpiredAt(
        DateTime.fromMillisecondsSinceEpoch(1099 * 1000, isUtc: true),
      ),
      isFalse,
    );
    expect(
      t.isExpiredAt(
        DateTime.fromMillisecondsSinceEpoch(1100 * 1000, isUtc: true),
      ),
      isTrue,
    );
  });
}
