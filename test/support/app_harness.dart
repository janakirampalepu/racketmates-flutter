import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/app.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/screens/splash/repositories/startup_repository.dart';

import 'fakes.dart';

/// The whole app with a restored signed-in session (user id 7) and fake
/// repositories; starts at the splash and lands on home.
Widget signedInApp({
  FakeScheduleRepository? schedule,
  FakeUserRepository? users,
}) => ProviderScope(
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
    userRepositoryProvider.overrideWithValue(users ?? FakeUserRepository()),
    scheduleRepositoryProvider.overrideWithValue(
      schedule ?? FakeScheduleRepository(),
    ),
    hourFormatProvider.overrideWithValue(12),
  ],
  child: const RacketmatesApp(),
);

/// Makes the test viewport tall so long lists build all their children.
void useTallScreen(WidgetTester tester, {double height = 4000}) {
  tester.view.physicalSize = Size(800, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
