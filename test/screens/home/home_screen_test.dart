import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/app.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/splash/repositories/startup_repository.dart';

import '../../support/fakes.dart';

Widget _app(FakeUserRepository users) => ProviderScope(
  overrides: [
    environmentConfigProvider.overrideWithValue(testConfig),
    appVersionProvider.overrideWithValue('1.0.0'),
    tokenStoreProvider.overrideWithValue(
      InMemoryTokenStore(
        const SessionToken(
          accessToken: 'a',
          refreshToken: 'r',
          user: SessionTokenUser(id: 7),
        ),
      ),
    ),
    authApiProvider.overrideWithValue(FakeAuthApi()),
    startupRepositoryProvider.overrideWithValue(FakeStartupRepository()),
    userRepositoryProvider.overrideWithValue(users),
  ],
  child: const RacketmatesApp(),
);

void main() {
  testWidgets(
    'profile is fetched after a restored session and greets the user',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(FakeUserRepository()));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier(HomeTestIds.root), findsOneWidget);
      expect(find.text('Hi, Sam'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('home still renders when the profile cannot be fetched', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(FakeUserRepository(failure: const OfflineFailure())),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier(HomeTestIds.root), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    handle.dispose();
  });
}
