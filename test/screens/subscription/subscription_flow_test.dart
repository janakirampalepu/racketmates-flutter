import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/common/billing/billing_models.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/links/external_links.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';
import 'package:racketmates/screens/settings/settings_test_ids.dart';
import 'package:racketmates/screens/subscription/subscription_test_ids.dart';
import 'package:racketmates/screens/teams/teams_test_ids.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

Finder _id(String id) => find.bySemanticsIdentifier(id);

FakeSessionInfoRepository _info({
  int? trialDays,
  String? device,
  bool full = true,
  Map<String, AccessInfo>? permissions,
}) => FakeSessionInfoRepository(
  response: SessionInfoResponse(
    user: SessionInfoUser(
      id: 7,
      hasFullFeatureAccess: full,
      trialRemainingDays: trialDays,
      subscribedDeviceType: device,
      userPermissions: permissions,
      timezoneIdentifier: 'America/New_York',
    ),
  ),
);

Future<void> _openFromSettings(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(_id(HomeTestIds.settingsButton));
  await tester.pumpAndSettle();
  await tester.tap(_id(SettingsTestIds.subscriptionTile));
  await tester.pumpAndSettle();
}

void main() {
  group('the offer', () {
    testWidgets('shows both plans, the saving and the yearly price per month', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp(sessionInfo: _info(full: false)));
      await _openFromSettings(tester);
      expect(_id(SubscriptionTestIds.root), findsOneWidget);
      expect(find.text(r'$39.99'), findsOneWidget);
      expect(find.text(r'$4.99'), findsOneWidget);
      expect(find.text('Save 33%'), findsOneWidget);
      expect(find.text(r'$3.33/month'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('buying sends the chosen plan and ends on the success screen', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final billing = FakeBillingPlatform();
      final repo = FakeSubscriptionRepository();
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: _info(full: false),
          billing: billing,
          subscriptions: repo,
        ),
      );
      await _openFromSettings(tester);
      await tester.tap(_id(SubscriptionTestIds.monthly));
      await tester.pump();
      await tester.tap(_id(SubscriptionTestIds.upgrade));
      await tester.pump();
      expect(billing.purchased, ['qa.monthly']);
      expect(billing.accountIds, ['uuid-7']);
      billing.updatesController.add(
        PurchaseUpdate(
          PurchaseStatus.purchased,
          record: androidPurchase(productId: 'qa.monthly'),
        ),
      );
      await tester.pumpAndSettle();
      expect(_id(SubscriptionTestIds.successRoot), findsOneWidget);
      expect(repo.linked.single.android!['productId'], 'qa.monthly');
      await tester.tap(_id(SubscriptionTestIds.successContinue));
      await tester.pumpAndSettle();
      expect(_id(HomeTestIds.root), findsOneWidget);
      handle.dispose();
    });

    for (final c in [
      (PurchaseStatus.cancelled, 'The purchase was cancelled.'),
      (
        PurchaseStatus.pending,
        'Your purchase is waiting for approval. Access starts once it is approved.',
      ),
      (
        PurchaseStatus.failed,
        'The purchase did not complete. Please try again.',
      ),
    ]) {
      testWidgets('a ${c.$1.name} purchase says so and can be tried again', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        final billing = FakeBillingPlatform();
        await tester.pumpWidget(
          signedInApp(sessionInfo: _info(full: false), billing: billing),
        );
        await _openFromSettings(tester);
        await tester.tap(_id(SubscriptionTestIds.upgrade));
        await tester.pump();
        billing.updatesController.add(PurchaseUpdate(c.$1));
        await tester.pumpAndSettle();
        expect(find.text(c.$2), findsOneWidget);
        expect(_id(SubscriptionTestIds.successRoot), findsNothing);
        await tester.tap(_id(SubscriptionTestIds.upgrade));
        await tester.pump();
        expect(billing.purchased, hasLength(2));
        handle.dispose();
      });
    }

    testWidgets('a purchase the backend refused explains what happens next', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final billing = FakeBillingPlatform();
      final repo = FakeSubscriptionRepository()
        ..failure = const OfflineFailure();
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: _info(full: false),
          billing: billing,
          subscriptions: repo,
        ),
      );
      await _openFromSettings(tester);
      await tester.tap(_id(SubscriptionTestIds.upgrade));
      await tester.pump();
      billing.updatesController.add(
        PurchaseUpdate(PurchaseStatus.purchased, record: androidPurchase()),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be activated yet'), findsOneWidget);
      expect(billing.completed, ['tok-1']);
      handle.dispose();
    });

    testWidgets('an unavailable store shows an error and retry', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final billing = FakeBillingPlatform(available: false);
      await tester.pumpWidget(
        signedInApp(sessionInfo: _info(full: false), billing: billing),
      );
      await _openFromSettings(tester);
      expect(_id(SubscriptionTestIds.error), findsOneWidget);
      billing.available = true;
      await tester.tap(_id(SubscriptionTestIds.retry));
      await tester.pumpAndSettle();
      expect(_id(SubscriptionTestIds.yearly), findsOneWidget);
      handle.dispose();
    });

    testWidgets('terms, privacy and redeem open their pages (Android)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final links = FakeExternalLinks();
      await tester.pumpWidget(
        signedInApp(sessionInfo: _info(full: false), links: links),
      );
      await _openFromSettings(tester);
      await tester.ensureVisible(_id(SubscriptionTestIds.terms));
      await tester.tap(_id(SubscriptionTestIds.terms));
      await tester.tap(_id(SubscriptionTestIds.privacy));
      await tester.tap(_id(SubscriptionTestIds.redeem));
      expect(links.opened, [
        SubscriptionLinks.termsAndroid,
        SubscriptionLinks.privacy,
        SubscriptionLinks.redeemAndroid,
      ]);
      expect(_id(SubscriptionTestIds.restore), findsNothing);
      handle.dispose();
    });

    testWidgets('iOS: restore finds, links and reports', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final billing = FakeBillingPlatform();
      final repo = FakeSubscriptionRepository();
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: _info(full: false),
          billing: billing,
          subscriptions: repo,
        ),
      );
      await _openFromSettings(tester);
      await tester.ensureVisible(_id(SubscriptionTestIds.restore));
      await tester.tap(_id(SubscriptionTestIds.restore));
      await tester.pumpAndSettle();
      expect(
        find.text('No active subscription was found for this store account.'),
        findsOneWidget,
      );
      billing.restorable = [applePurchase()];
      await tester.tap(_id(SubscriptionTestIds.restore));
      await tester.pumpAndSettle();
      expect(find.text('Subscription restored.'), findsOneWidget);
      expect(repo.linked.single.isApple, isTrue);
      debugDefaultTargetPlatformOverride = null;
      handle.dispose();
    });

    testWidgets('iOS: redeem opens the store sheet', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final billing = FakeBillingPlatform();
      await tester.pumpWidget(
        signedInApp(sessionInfo: _info(full: false), billing: billing),
      );
      await _openFromSettings(tester);
      await tester.ensureVisible(_id(SubscriptionTestIds.redeem));
      await tester.tap(_id(SubscriptionTestIds.redeem));
      expect(billing.redeemed, 1);
      debugDefaultTargetPlatformOverride = null;
      handle.dispose();
    });

    for (final dark in [false, true]) {
      testWidgets('meets guidelines (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(signedInApp(sessionInfo: _info(full: false)));
        await _openFromSettings(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('entry points', () {
    testWidgets('a subscriber manages the subscription in the store', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final links = FakeExternalLinks();
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: _info(device: 'dt_android'),
          links: links,
        ),
      );
      await _openFromSettings(tester);
      expect(_id(SubscriptionTestIds.root), findsNothing);
      expect(links.opened, [SubscriptionLinks.manageAndroid]);
      handle.dispose();
    });

    testWidgets('builds without store products have no subscription entry', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(signedInApp(environment: AppEnvironment.local));
      await tester.pumpAndSettle();
      await tester.tap(_id(HomeTestIds.settingsButton));
      await tester.pumpAndSettle();
      expect(_id(SettingsTestIds.subscriptionTile), findsNothing);
      handle.dispose();
    });

    testWidgets('a feature that needs a subscription offers the plans', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: _info(
            full: false,
            trialDays: 30,
            permissions: const {
              'teams.create': AccessInfo(access: 'up_requires_subscription'),
            },
          ),
          promptStore: InMemoryPromptStore(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_id(MainShellTestIds.navTeams));
      await tester.pumpAndSettle();
      await tester.tap(_id(TeamsTestIds.create));
      await tester.pumpAndSettle();
      await tester.tap(_id(TeamsTestIds.accessDialogUpgrade));
      await tester.pumpAndSettle();
      expect(_id(SubscriptionTestIds.root), findsOneWidget);
      handle.dispose();
    });
  });

  group('trial reminders', () {
    testWidgets(
      'a trial with days left opens the offer once and is not repeated',
      (tester) async {
        final handle = tester.ensureSemantics();
        useTallScreen(tester);
        final store = InMemoryPromptStore(allSeen: false);
        await tester.pumpWidget(
          signedInApp(
            sessionInfo: _info(full: true, trialDays: 5),
            promptStore: store,
          ),
        );
        await tester.pumpAndSettle();
        expect(_id(SubscriptionTestIds.root), findsOneWidget);
        await tester.tap(_id(SubscriptionTestIds.close));
        await tester.pumpAndSettle();
        expect(_id(HomeTestIds.root), findsOneWidget);
        expect(store.seenKeys, {'trialEnding:7'});
        handle.dispose();
      },
    );

    testWidgets('a reminder already closed does not come back', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      final store = InMemoryPromptStore(allSeen: false)
        ..seenKeys.add('trialEnding:7');
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: _info(full: true, trialDays: 5),
          promptStore: store,
        ),
      );
      await tester.pumpAndSettle();
      expect(_id(SubscriptionTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets('a finished trial opens the offer', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: _info(full: false, trialDays: 0),
          promptStore: InMemoryPromptStore(allSeen: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(_id(SubscriptionTestIds.root), findsOneWidget);
      handle.dispose();
    });

    testWidgets('subscribers and long trials are left alone', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(
        signedInApp(
          sessionInfo: _info(device: 'dt_ios', trialDays: 0),
          promptStore: InMemoryPromptStore(allSeen: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(_id(SubscriptionTestIds.root), findsNothing);
      handle.dispose();
    });

    testWidgets('builds without store products never remind', (tester) async {
      final handle = tester.ensureSemantics();
      useTallScreen(tester);
      await tester.pumpWidget(
        signedInApp(
          environment: AppEnvironment.dev,
          sessionInfo: _info(full: false, trialDays: 0),
          promptStore: InMemoryPromptStore(allSeen: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(_id(SubscriptionTestIds.root), findsNothing);
      handle.dispose();
    });
  });
}
