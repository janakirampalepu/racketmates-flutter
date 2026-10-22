import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/app.dart';
import 'package:racketmates/app/config/brand_config.dart';
import 'package:racketmates/app/theme/app_theme.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/app_metadata.dart';
import 'package:racketmates/common/auth/models/app_upgrade_check.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/screens/app_update/app_update_test_ids.dart';
import 'package:racketmates/screens/app_update/store_launcher.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/splash/repositories/startup_repository.dart';
import 'package:racketmates/screens/splash/splash_test_ids.dart';
import 'package:racketmates/screens/settings/settings_test_ids.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

import '../../support/app_harness.dart' show useTallScreen;
import '../../support/fakes.dart';

class _FakeLauncher implements StoreLauncher {
  int opened = 0;

  @override
  Future<void> openStorePage() async => opened++;
}

Widget _app({
  InMemoryTokenStore? store,
  AppMetadata? metadata,
  FakeStartupRepository? repo,
  _FakeLauncher? launcher,
}) => ProviderScope(
  overrides: [
    environmentConfigProvider.overrideWithValue(testConfig),
    appVersionProvider.overrideWithValue('1.0.0'),
    tokenStoreProvider.overrideWithValue(store ?? InMemoryTokenStore()),
    authApiProvider.overrideWithValue(FakeAuthApi()),
    ...contentOverrides(),
    scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository()),
    startupRepositoryProvider.overrideWithValue(
      repo ?? FakeStartupRepository(metadata: metadata),
    ),
    if (launcher != null) storeLauncherProvider.overrideWithValue(launcher),
  ],
  child: const RacketmatesApp(),
);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'splash exposes test ids and passes contrast guideline ($mode)',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.platformBrightnessTestValue =
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(_app());
        expect(find.bySemanticsIdentifier(SplashTestIds.root), findsOneWidget);
        expect(
          find.bySemanticsIdentifier(SplashTestIds.progress),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Loading'), findsOneWidget);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await tester.pumpAndSettle();
        handle.dispose();
      },
    );
  }

  testWidgets('no session: splash resolves to welcome', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier(WelcomeTestIds.root), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'persisted session: splash resolves to home, sign out returns to welcome',
    (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester); // the settings list is longer than a phone
      await tester.pumpWidget(_app(store: InMemoryTokenStore(token())));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier(HomeTestIds.root), findsOneWidget);

      await tester.tap(find.bySemanticsIdentifier(HomeTestIds.settingsButton));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier(SettingsTestIds.logout));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsIdentifier(SettingsTestIds.logoutConfirm),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier(WelcomeTestIds.root), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('mandatory upgrade: update screen without a way out', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final launcher = _FakeLauncher();
    await tester.pumpWidget(
      _app(
        store: InMemoryTokenStore(token()),
        launcher: launcher,
        metadata: const AppMetadata(
          appUpgradeCheck: AppUpgradeCheck(
            upgradeRequired: true,
            upgradeType: 'mandatory',
            newVersionNumber: '27.0.0',
            notes: 'Important fixes',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier(AppUpdateTestIds.root), findsOneWidget);
    expect(find.text('Important fixes'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier(AppUpdateTestIds.laterButton),
      findsNothing,
    );

    await tester.tap(find.bySemanticsIdentifier(AppUpdateTestIds.updateButton));
    expect(launcher.opened, 1);
    handle.dispose();
  });

  testWidgets('optional upgrade: Later remembers the version and continues', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakeStartupRepository(
      metadata: const AppMetadata(
        appUpgradeCheck: AppUpgradeCheck(
          upgradeRequired: true,
          upgradeType: 'optional',
          newVersionNumber: '27.0.0',
        ),
      ),
    );
    await tester.pumpWidget(
      _app(store: InMemoryTokenStore(token()), repo: repo),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier(AppUpdateTestIds.root), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier(AppUpdateTestIds.laterButton));
    await tester.pumpAndSettle();
    expect(repo.prompted, '27.0.0');
    expect(find.bySemanticsIdentifier(HomeTestIds.root), findsOneWidget);
    handle.dispose();
  });

  test('light and dark themes are Material 3 with the brand seed', () {
    const brand = BrandConfig.racketmates;
    expect(AppTheme.light(brand).useMaterial3, isTrue);
    expect(AppTheme.light(brand).brightness, Brightness.light);
    expect(AppTheme.dark(brand).brightness, Brightness.dark);
  });
}
