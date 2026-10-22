import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';

import '../../support/fakes.dart';

void main() {
  ProviderContainer container(InMemoryTokenStore store, FakeAuthApi api) {
    final c = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        authApiProvider.overrideWithValue(api),
        environmentConfigProvider.overrideWithValue(testConfig),
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
}
