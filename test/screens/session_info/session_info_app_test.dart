import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/common/startup/downtime.dart';
import 'package:racketmates/screens/create_team/create_team_test_ids.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/teams/teams_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

SessionInfoResponse _info({
  Map<String, AccessInfo>? permissions,
  bool subscribed = false,
  String? timezone = 'America/New_York',
}) => SessionInfoResponse(
  user: SessionInfoUser(
    id: 7,
    hasFullFeatureAccess: subscribed,
    timezoneIdentifier: timezone,
    userPermissions: permissions,
  ),
);

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

Future<void> _openTeams(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(MainShellTestIds.navTeams));
  await tester.pumpAndSettle();
}

void main() {
  group('loading', () {
    testWidgets('session_info is loaded when the app starts signed in', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repo = FakeSessionInfoRepository(response: _info());
      await tester.pumpWidget(signedInApp(sessionInfo: repo));
      await tester.pumpAndSettle();
      expect(_id(HomeTestIds.root), findsOneWidget);
      expect(repo.fetches, 1);
      expect(repo.timezoneUpdates, isEmpty); // the zone already matches
      handle.dispose();
    });

    testWidgets('the zone follows the device when it has changed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repo = FakeSessionInfoRepository(
        response: _info(timezone: 'America/Chicago'),
      );
      await tester.pumpWidget(
        signedInApp(sessionInfo: repo, deviceTimezone: 'Europe/Paris'),
      );
      await tester.pumpAndSettle();
      expect(repo.timezoneUpdates, ['Europe/Paris']);
      handle.dispose();
    });

    testWidgets('nothing is loaded when signed out', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = FakeSessionInfoRepository();
      await tester.pumpWidget(signedOutApp(sessionInfo: repo));
      await tester.pumpAndSettle();
      expect(repo.fetches, 0);
      handle.dispose();
    });

    testWidgets('it is reloaded when the app is resumed', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = FakeSessionInfoRepository(response: _info());
      await tester.pumpWidget(signedInApp(sessionInfo: repo));
      await tester.pumpAndSettle();
      await _resume(tester);
      expect(repo.fetches, 2);
      handle.dispose();
    });

    testWidgets('it is not loaded when resuming into an outage', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repo = FakeSessionInfoRepository(response: _info());
      final downtime = FakeDowntimeRepository();
      await tester.pumpWidget(
        signedInApp(sessionInfo: repo, downtime: downtime),
      );
      await tester.pumpAndSettle();
      downtime.incident = const Incident(name: 'Outage');
      await _resume(tester);
      expect(repo.fetches, 1);
      handle.dispose();
    });

    testWidgets('a failing session_info does not disturb the app', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repo = FakeSessionInfoRepository(response: _info())
        ..fetchFailure = const OfflineFailure();
      await tester.pumpWidget(signedInApp(sessionInfo: repo));
      await tester.pumpAndSettle();
      expect(_id(HomeTestIds.root), findsOneWidget);
      handle.dispose();
    });
  });

  group('create team permission', () {
    Future<void> openWith(
      WidgetTester tester,
      Map<String, AccessInfo>? permissions, {
      bool subscribed = false,
    }) async {
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: FakeSessionInfoRepository(
            response: _info(permissions: permissions, subscribed: subscribed),
          ),
        ),
      );
      await _openTeams(tester);
    }

    testWidgets('allowed or unknown opens the form', (tester) async {
      final handle = tester.ensureSemantics();
      await openWith(tester, null);
      await tester.tap(_id(TeamsTestIds.create));
      await tester.pumpAndSettle();
      expect(_id(CreateTeamTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('not available hides the button', (tester) async {
      final handle = tester.ensureSemantics();
      await openWith(tester, {
        'teams.create': const AccessInfo(access: 'up_not_available'),
      });
      expect(_id(TeamsTestIds.root), findsOneWidget);
      expect(_id(TeamsTestIds.create), findsNothing);
      handle.dispose();
    });

    testWidgets(
      'a subscription gate explains itself without opening the form',
      (tester) async {
        final handle = tester.ensureSemantics();
        await openWith(tester, {
          'teams.create': const AccessInfo(
            access: 'up_requires_subscription',
            message: 'Upgrade to create teams',
          ),
        });
        await tester.tap(_id(TeamsTestIds.create));
        await tester.pumpAndSettle();
        expect(find.text('Upgrade to create teams'), findsOneWidget);
        expect(_id(CreateTeamTestIds.root), findsNothing);
        await tester.tap(_id(TeamsTestIds.accessDialogClose));
        await tester.pumpAndSettle();
        expect(_id(TeamsTestIds.accessDialog), findsNothing);
        handle.dispose();
      },
    );

    testWidgets('a subscription gate without a message uses the local text', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openWith(tester, {
        'teams.create': const AccessInfo(access: 'up_requires_subscription'),
      });
      await tester.tap(_id(TeamsTestIds.create));
      await tester.pumpAndSettle();
      expect(find.text('This feature needs a subscription.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a subscriber passes the subscription gate', (tester) async {
      final handle = tester.ensureSemantics();
      await openWith(tester, {
        'teams.create': const AccessInfo(access: 'up_requires_subscription'),
      }, subscribed: true);
      await tester.tap(_id(TeamsTestIds.create));
      await tester.pumpAndSettle();
      expect(_id(CreateTeamTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a disabled feature shows the server message', (tester) async {
      final handle = tester.ensureSemantics();
      await openWith(tester, {
        'teams.create': const AccessInfo(
          access: 'up_disabled',
          message: 'Team creation is paused',
        ),
      }, subscribed: true);
      await tester.tap(_id(TeamsTestIds.create));
      await tester.pumpAndSettle();
      expect(find.text('Team creation is paused'), findsOneWidget);
      expect(_id(CreateTeamTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets('a disabled feature without a message says so', (tester) async {
      final handle = tester.ensureSemantics();
      await openWith(tester, {
        'teams.create': const AccessInfo(access: 'up_disabled'),
      });
      await tester.tap(_id(TeamsTestIds.create));
      await tester.pumpAndSettle();
      expect(find.text("This isn't available right now."), findsOneWidget);
      handle.dispose();
    });
  });
}
