import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/router/app_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/auth/models/app_upgrade_check.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/screens/splash/usecases/decide_startup_destination.dart';

import '../../support/fakes.dart';

const _mandatory = AppUpgradeCheck(
  upgradeRequired: true,
  upgradeType: 'mandatory',
  newVersionNumber: '27.0.0',
);
const _optional = AppUpgradeCheck(
  upgradeRequired: true,
  upgradeType: 'optional',
  newVersionNumber: '27.0.0',
);

void main() {
  group('decideStartupDestination', () {
    test('signed in / out without an upgrade', () {
      expect(
        decideStartupDestination(signedIn: true, upgrade: null),
        StartupDestination.home,
      );
      expect(
        decideStartupDestination(signedIn: false, upgrade: null),
        StartupDestination.welcome,
      );
    });

    test('mandatory upgrade always prompts', () {
      expect(
        decideStartupDestination(
          signedIn: true,
          upgrade: _mandatory,
          lastPromptedVersion: '27.0.0',
        ),
        StartupDestination.appUpdate,
      );
    });

    test('optional upgrade prompts once per offered version', () {
      expect(
        decideStartupDestination(signedIn: true, upgrade: _optional),
        StartupDestination.appUpdate,
      );
      expect(
        decideStartupDestination(
          signedIn: true,
          upgrade: _optional,
          lastPromptedVersion: '27.0.0',
        ),
        StartupDestination.home,
      );
      expect(
        decideStartupDestination(
          signedIn: true,
          upgrade: _optional,
          lastPromptedVersion: '26.9.0',
        ),
        StartupDestination.appUpdate,
      );
    });

    test('upgrade_required false never prompts', () {
      const none = AppUpgradeCheck(
        upgradeRequired: false,
        upgradeType: 'mandatory',
      );
      expect(
        decideStartupDestination(signedIn: false, upgrade: none),
        StartupDestination.welcome,
      );
    });
  });

  group('computeRedirect', () {
    final signedIn = SignedIn(token());

    test('mandatory upgrade locks navigation', () {
      expect(
        computeRedirect(
          location: AppRoutes.home,
          session: signedIn,
          mandatoryUpgrade: true,
        ),
        AppRoutes.appUpdate,
      );
      expect(
        computeRedirect(
          location: AppRoutes.appUpdate,
          session: signedIn,
          mandatoryUpgrade: true,
        ),
        isNull,
      );
    });

    test('only the splash shows while restoring', () {
      expect(
        computeRedirect(
          location: AppRoutes.home,
          session: const SessionRestoring(),
          mandatoryUpgrade: false,
        ),
        AppRoutes.splash,
      );
      expect(
        computeRedirect(
          location: AppRoutes.splash,
          session: const SessionRestoring(),
          mandatoryUpgrade: false,
        ),
        isNull,
      );
    });

    test('signed-out users cannot open protected routes', () {
      expect(
        computeRedirect(
          location: AppRoutes.home,
          session: const SignedOut(),
          mandatoryUpgrade: false,
        ),
        AppRoutes.welcome,
      );
      expect(
        computeRedirect(
          location: AppRoutes.welcome,
          session: const SignedOut(),
          mandatoryUpgrade: false,
        ),
        isNull,
      );
    });

    test('signed-in users skip welcome and keep home', () {
      expect(
        computeRedirect(
          location: AppRoutes.welcome,
          session: signedIn,
          mandatoryUpgrade: false,
        ),
        AppRoutes.home,
      );
      expect(
        computeRedirect(
          location: AppRoutes.home,
          session: signedIn,
          mandatoryUpgrade: false,
        ),
        isNull,
      );
    });

    test('logout while on a protected route moves to welcome', () {
      expect(
        computeRedirect(
          location: AppRoutes.home,
          session: const SignedOut(),
          mandatoryUpgrade: false,
        ),
        AppRoutes.welcome,
      );
    });
  });
}
