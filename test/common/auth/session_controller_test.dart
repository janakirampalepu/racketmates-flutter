import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/native_session.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';

import '../../support/fakes.dart';

void main() {
  ProviderContainer container(
    InMemoryTokenStore store,
    FakeAuthApi api, {
    FakeNativeSessionSource? native,
  }) {
    final c = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        authApiProvider.overrideWithValue(api),
        environmentConfigProvider.overrideWithValue(testConfig),
        nativeSessionSourceProvider.overrideWithValue(
          native ?? FakeNativeSessionSource(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('starts restoring; restore finds the persisted session', () async {
    final c = container(InMemoryTokenStore(token()), FakeAuthApi());
    expect(c.read(sessionControllerProvider), isA<SessionRestoring>());
    await c.read(sessionControllerProvider.notifier).restore();
    expect(c.read(sessionControllerProvider), isA<SignedIn>());
  });

  test('restore without a session is signed out', () async {
    final c = container(InMemoryTokenStore(), FakeAuthApi());
    await c.read(sessionControllerProvider.notifier).restore();
    expect(c.read(sessionControllerProvider), isA<SignedOut>());
  });

  test('signOut clears locally and revokes the token best-effort', () async {
    final store = InMemoryTokenStore(token());
    final api = FakeAuthApi();
    final c = container(store, api);
    final session = c.read(sessionControllerProvider.notifier);
    await session.restore();
    await session.signOut();
    expect(c.read(sessionControllerProvider), isA<SignedOut>());
    expect(await store.read(), isNull);
    expect(api.revokeBodies.single['token'], 'access-1');
  });

  test('expire clears locally without remote calls', () async {
    final store = InMemoryTokenStore(token());
    final api = FakeAuthApi();
    final c = container(store, api);
    final session = c.read(sessionControllerProvider.notifier);
    await session.restore();
    await session.expire();
    expect(c.read(sessionControllerProvider), isA<SignedOut>());
    expect(api.revokeBodies, isEmpty);
  });

  group('native session', () {
    const nativeJson =
        '{"access_token":"native-a","token_type":"Bearer","expires_in":7200,'
        '"refresh_token":"native-r","created_at":1700000000,'
        '"user":{"id":7,"uid":"u-7","is_signed_up":true}}';

    test(
      'is imported when nothing is stored, then removed from the native app',
      () async {
        final store = InMemoryTokenStore();
        final native = FakeNativeSessionSource(nativeJson);
        final c = container(store, FakeAuthApi(), native: native);
        await c.read(sessionControllerProvider.notifier).restore();

        final state = c.read(sessionControllerProvider);
        expect(state, isA<SignedIn>());
        expect((state as SignedIn).token.refreshToken, 'native-r');
        expect(state.token.user?.id, 7);
        // Stored for next time; the native copy is gone.
        expect((await store.read())?.accessToken, 'native-a');
        expect(native.clears, 1);
      },
    );

    test('is not read when a session is already stored', () async {
      final native = FakeNativeSessionSource(nativeJson);
      final c = container(
        InMemoryTokenStore(token()),
        FakeAuthApi(),
        native: native,
      );
      await c.read(sessionControllerProvider.notifier).restore();
      expect(
        (c.read(sessionControllerProvider) as SignedIn).token.accessToken,
        'access-1',
      );
      expect(native.reads, 0);
      expect(native.clears, 0);
    });

    test('one that cannot be used signs out and is discarded', () async {
      final store = InMemoryTokenStore();
      final native = FakeNativeSessionSource(
        '{"access_token":"a","user":{"is_signed_up":false}}',
      );
      final c = container(store, FakeAuthApi(), native: native);
      await c.read(sessionControllerProvider.notifier).restore();
      expect(c.read(sessionControllerProvider), isA<SignedOut>());
      expect(await store.read(), isNull);
      expect(native.clears, 1);
    });

    test('nothing to import signs out', () async {
      final native = FakeNativeSessionSource();
      final c = container(InMemoryTokenStore(), FakeAuthApi(), native: native);
      await c.read(sessionControllerProvider.notifier).restore();
      expect(c.read(sessionControllerProvider), isA<SignedOut>());
      expect(native.clears, 0);
    });
  });
}
