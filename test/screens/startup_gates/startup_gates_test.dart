import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/startup/downtime.dart';
import 'package:racketmates/screens/device_blocked/device_blocked_test_ids.dart';
import 'package:racketmates/screens/downtime/downtime_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

const _outage = Incident(name: 'API outage', message: 'We are working on it.');

Future<void> _resume(WidgetTester tester) async {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

void main() {
  group('rooted or jailbroken device', () {
    testWidgets('is stopped at launch and loses its session', (tester) async {
      final handle = tester.ensureSemantics();
      final store = InMemoryTokenStore(token());
      final downtime = FakeDowntimeRepository();
      await tester.pumpWidget(
        signedInApp(
          integrity: FakeDeviceIntegrity(compromised: true),
          tokenStore: store,
          downtime: downtime,
        ),
      );
      await tester.pumpAndSettle();

      expect(_id(DeviceBlockedTestIds.root), findsOneWidget);
      expect(find.text('Security Warning'), findsOneWidget);
      expect(find.textContaining('rooted or jailbroken'), findsOneWidget);
      expect(_id(HomeTestIds.root), findsNothing);
      expect(await store.read(), isNull);
      expect(downtime.checks, 0); // nothing else ran
      handle.dispose();
    });

    testWidgets('is stopped when the app is resumed', (tester) async {
      final handle = tester.ensureSemantics();
      final integrity = FakeDeviceIntegrity();
      final store = InMemoryTokenStore(token());
      await tester.pumpWidget(
        signedInApp(integrity: integrity, tokenStore: store),
      );
      await tester.pumpAndSettle();
      expect(_id(HomeTestIds.root), findsOneWidget);

      integrity.compromised =
          true; // rooted while the app was in the background
      await _resume(tester);
      expect(_id(DeviceBlockedTestIds.root), findsOneWidget);
      expect(_id(HomeTestIds.root), findsNothing);
      expect(await store.read(), isNull);
      handle.dispose();
    });

    testWidgets(
      'a development build runs on a simulator, production does not',
      (tester) async {
        final handle = tester.ensureSemantics();
        final integrity = FakeDeviceIntegrity();
        await tester.pumpWidget(signedInApp(integrity: integrity));
        await tester.pumpAndSettle();
        expect(integrity.checks, [true]); // the test config is a QA build
        handle.dispose();
      },
    );
  });

  group('downtime', () {
    testWidgets('shows the incident instead of the app', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        signedInApp(downtime: FakeDowntimeRepository(_outage)),
      );
      await tester.pumpAndSettle();

      expect(_id(DowntimeTestIds.root), findsOneWidget);
      expect(find.text('API outage'), findsOneWidget);
      expect(find.text('We are working on it.'), findsOneWidget);
      expect(_id(HomeTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets('a maintenance window says when the service is back', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        signedInApp(
          downtime: FakeDowntimeRepository(
            Incident(
              name: 'Maintenance',
              message: 'Upgrading.',
              scheduledUntil: DateTime(2030, 1, 2, 10, 30),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Upgrading. We will be back before'),
        findsOneWidget,
      );
      expect(find.textContaining('Jan 2, 2030'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an incident without texts still explains itself', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        signedInApp(downtime: FakeDowntimeRepository(const Incident(name: ''))),
      );
      await tester.pumpAndSettle();
      expect(find.text("We'll be right back"), findsOneWidget);
      expect(find.textContaining('unavailable right now'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
      'check again keeps waiting while it lasts, then restarts the app',
      (tester) async {
        final handle = tester.ensureSemantics();
        final repo = FakeDowntimeRepository(_outage);
        await tester.pumpWidget(signedInApp(downtime: repo));
        await tester.pumpAndSettle();
        expect(repo.checks, 1);

        await tester.tap(_id(DowntimeTestIds.checkAgain));
        await tester.pumpAndSettle();
        expect(repo.checks, 2);
        expect(_id(DowntimeTestIds.root), findsOneWidget);

        repo.incident = null;
        await tester.tap(_id(DowntimeTestIds.checkAgain));
        await tester.pumpAndSettle();
        expect(_id(DowntimeTestIds.root), findsNothing);
        expect(_id(HomeTestIds.root), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('a signed-out user is restarted to the welcome screen', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repo = FakeDowntimeRepository(_outage);
      await tester.pumpWidget(signedOutApp(downtime: repo));
      await tester.pumpAndSettle();
      expect(_id(DowntimeTestIds.root), findsOneWidget);
      repo.incident = null;
      await tester.tap(_id(DowntimeTestIds.checkAgain));
      await tester.pumpAndSettle();
      expect(_id(WelcomeTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
      'resuming into an outage shows it, resuming after it ends returns',
      (tester) async {
        final handle = tester.ensureSemantics();
        final repo = FakeDowntimeRepository();
        await tester.pumpWidget(signedInApp(downtime: repo));
        await tester.pumpAndSettle();
        expect(_id(HomeTestIds.root), findsOneWidget);

        repo.incident = _outage;
        await _resume(tester);
        expect(_id(DowntimeTestIds.root), findsOneWidget);

        repo.incident = null;
        await _resume(tester);
        expect(_id(DowntimeTestIds.root), findsNothing);
        expect(_id(HomeTestIds.root), findsOneWidget);
        handle.dispose();
      },
    );
  });

  group('session from the native app', () {
    testWidgets('a user who updates stays signed in', (tester) async {
      final handle = tester.ensureSemantics();
      final store = InMemoryTokenStore();
      final native = FakeNativeSessionSource(
        '{"access_token":"na","refresh_token":"nr","expires_in":7200,'
        '"created_at":1700000000,"user":{"id":7,"is_signed_up":true}}',
      );
      await tester.pumpWidget(
        signedInApp(tokenStore: store, nativeSession: native),
      );
      await tester.pumpAndSettle();

      expect(_id(HomeTestIds.root), findsOneWidget);
      expect((await store.read())?.refreshToken, 'nr');
      expect(native.clears, 1);
      handle.dispose();
    });

    testWidgets('an unusable one goes to the welcome screen', (tester) async {
      final handle = tester.ensureSemantics();
      final native = FakeNativeSessionSource('{"access_token":"a"}');
      await tester.pumpWidget(signedOutApp(nativeSession: native));
      await tester.pumpAndSettle();
      expect(_id(WelcomeTestIds.root), findsOneWidget);
      handle.dispose();
    });
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final blocked in [false, true]) {
      testWidgets(
        '${blocked ? 'device blocked' : 'downtime'} screen meets contrast '
        'and tap-target guidelines ($mode)',
        (tester) async {
          final handle = tester.ensureSemantics();
          tester.platformDispatcher.platformBrightnessTestValue =
              mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpWidget(
            blocked
                ? signedInApp(integrity: FakeDeviceIntegrity(compromised: true))
                : signedInApp(downtime: FakeDowntimeRepository(_outage)),
          );
          await tester.pumpAndSettle();
          expect(
            _id(blocked ? DeviceBlockedTestIds.root : DowntimeTestIds.root),
            findsOneWidget,
          );
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        },
      );
    }
  }
}
