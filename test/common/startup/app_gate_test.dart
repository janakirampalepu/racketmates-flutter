import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/app/config/environment_config.dart';
import 'package:racketmates/app/router/app_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/native_session.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/security/device_integrity.dart';
import 'package:racketmates/common/startup/app_gate.dart';
import 'package:racketmates/common/startup/downtime.dart';

import '../../support/fakes.dart';

const _outage = Incident(name: 'API outage', message: 'Down');

ProviderContainer _container({
  FakeDeviceIntegrity? integrity,
  FakeDowntimeRepository? downtime,
  InMemoryTokenStore? store,
  EnvironmentConfig config = testConfig,
}) {
  final c = ProviderContainer(
    overrides: [
      environmentConfigProvider.overrideWithValue(config),
      tokenStoreProvider.overrideWithValue(
        store ?? InMemoryTokenStore(token()),
      ),
      authApiProvider.overrideWithValue(FakeAuthApi()),
      nativeSessionSourceProvider.overrideWithValue(FakeNativeSessionSource()),
      deviceIntegrityProvider.overrideWithValue(
        integrity ?? FakeDeviceIntegrity(),
      ),
      downtimeRepositoryProvider.overrideWithValue(
        downtime ?? FakeDowntimeRepository(),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('device check', () {
    test('a clean device is let through', () async {
      final c = _container();
      expect(await c.read(appGateCheckerProvider).checkDevice(), isFalse);
      expect(c.read(appGateProvider), isNull);
    });

    test('a rooted device ends the session and blocks', () async {
      final store = InMemoryTokenStore(token());
      final c = _container(
        integrity: FakeDeviceIntegrity(compromised: true),
        store: store,
      );
      await c.read(sessionControllerProvider.notifier).restore();
      expect(c.read(sessionControllerProvider), isA<SignedIn>());

      expect(await c.read(appGateCheckerProvider).checkDevice(), isTrue);
      expect(c.read(appGateProvider), isA<DeviceBlocked>());
      expect(c.read(sessionControllerProvider), isA<SignedOut>());
      expect(await store.read(), isNull);
    });

    test('a blocked device stays blocked without checking again', () async {
      final integrity = FakeDeviceIntegrity(compromised: true);
      final c = _container(integrity: integrity);
      final checker = c.read(appGateCheckerProvider);
      await checker.checkDevice();
      integrity.compromised = false;
      expect(await checker.checkDevice(), isTrue);
      expect(integrity.checks, hasLength(1));
    });

    test('simulators are only allowed outside production', () async {
      EnvironmentConfig config(AppEnvironment e) => EnvironmentConfig(
        environment: e,
        apiBaseUrl: 'https://x.test',
        apiVersion: 'v',
        oauthClientId: 'i',
        oauthClientSecret: 's',
      );
      final dev = FakeDeviceIntegrity();
      await _container(
        integrity: dev,
        config: config(AppEnvironment.qa),
      ).read(appGateCheckerProvider).checkDevice();
      final prod = FakeDeviceIntegrity();
      await _container(
        integrity: prod,
        config: config(AppEnvironment.production),
      ).read(appGateCheckerProvider).checkDevice();
      expect(dev.checks, [true]);
      expect(prod.checks, [false]);
    });
  });

  group('downtime check', () {
    test('an incident sets the gate', () async {
      final c = _container(downtime: FakeDowntimeRepository(_outage));
      expect(
        (await c.read(appGateCheckerProvider).checkDowntime())?.name,
        'API outage',
      );
      final gate = c.read(appGateProvider);
      expect(gate, isA<Downtime>());
      expect((gate as Downtime).incident.message, 'Down');
    });

    test('the gate is cleared when the incident is over', () async {
      final repo = FakeDowntimeRepository(_outage);
      final c = _container(downtime: repo);
      final checker = c.read(appGateCheckerProvider);
      await checker.checkDowntime();
      repo.incident = null;
      expect(await checker.checkDowntime(), isNull);
      expect(c.read(appGateProvider), isNull);
    });

    test('a blocked device is never replaced by a downtime', () async {
      final c = _container(
        integrity: FakeDeviceIntegrity(compromised: true),
        downtime: FakeDowntimeRepository(_outage),
      );
      final checker = c.read(appGateCheckerProvider);
      await checker.checkDevice();
      await checker.checkDowntime();
      expect(c.read(appGateProvider), isA<DeviceBlocked>());
    });
  });

  group('on resume', () {
    test('does nothing while the app is still starting', () async {
      final repo = FakeDowntimeRepository(_outage);
      final integrity = FakeDeviceIntegrity(compromised: true);
      final c = _container(integrity: integrity, downtime: repo);
      expect(c.read(sessionControllerProvider), isA<SessionRestoring>());
      await c.read(appGateCheckerProvider).checkOnResume();
      expect(integrity.checks, isEmpty);
      expect(repo.checks, 0);
    });

    test('checks the device first, then downtime', () async {
      final repo = FakeDowntimeRepository(_outage);
      final c = _container(downtime: repo);
      await c.read(sessionControllerProvider.notifier).restore();
      await c.read(appGateCheckerProvider).checkOnResume();
      expect(c.read(appGateProvider), isA<Downtime>());

      final blocked = _container(
        integrity: FakeDeviceIntegrity(compromised: true),
        downtime: FakeDowntimeRepository(_outage),
      );
      await blocked.read(sessionControllerProvider.notifier).restore();
      await blocked.read(appGateCheckerProvider).checkOnResume();
      expect(blocked.read(appGateProvider), isA<DeviceBlocked>());
    });
  });

  group('router redirect', () {
    String? redirect(String location, {AppGate? gate, SessionState? session}) =>
        computeRedirect(
          location: location,
          session: session ?? const SignedOut(),
          mandatoryUpgrade: false,
          gate: gate,
        );

    test('a blocked device can only see its screen', () {
      expect(
        redirect(AppRoutes.home, gate: const DeviceBlocked()),
        AppRoutes.deviceBlocked,
      );
      expect(
        redirect(AppRoutes.deviceBlocked, gate: const DeviceBlocked()),
        isNull,
      );
      expect(
        redirect(AppRoutes.welcome, gate: const DeviceBlocked()),
        AppRoutes.deviceBlocked,
      );
    });

    test('a downtime can only see its screen', () {
      const gate = Downtime(_outage);
      expect(redirect(AppRoutes.home, gate: gate), AppRoutes.downtime);
      expect(redirect(AppRoutes.downtime, gate: gate), isNull);
    });

    test('they come before a mandatory upgrade and a restoring session', () {
      expect(
        computeRedirect(
          location: AppRoutes.appUpdate,
          session: const SessionRestoring(),
          mandatoryUpgrade: true,
          gate: const DeviceBlocked(),
        ),
        AppRoutes.deviceBlocked,
      );
    });

    test('without a gate nothing changes', () {
      expect(redirect(AppRoutes.welcome), isNull);
    });
  });
}
