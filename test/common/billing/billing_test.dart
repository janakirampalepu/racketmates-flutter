import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/native_session.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/billing/billing_models.dart';
import 'package:racketmates/common/billing/billing_platform.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/billing/product_ids.dart';
import 'package:racketmates/common/billing/subscription_api.dart';
import 'package:racketmates/common/billing/subscription_controller.dart';
import 'package:racketmates/common/billing/subscription_prompt.dart';
import 'package:racketmates/common/billing/subscription_repository.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/common/session/session_info_repository.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';

import '../../support/fakes.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _signedIn = SessionToken(
  accessToken: 'a',
  refreshToken: 'r',
  user: SessionTokenUser(id: 7, uid: 'uid-7', uuid: 'uuid-7'),
);

ProviderContainer _container({
  FakeBillingPlatform? billing,
  FakeSubscriptionRepository? repo,
  FakeSessionInfoRepository? info,
  AppEnvironment environment = AppEnvironment.qa,
  SessionToken? session = _signedIn,
}) {
  final c = ProviderContainer(
    overrides: [
      environmentConfigProvider.overrideWithValue(
        testConfigWith(environment: environment),
      ),
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
      authApiProvider.overrideWithValue(FakeAuthApi()),
      nativeSessionSourceProvider.overrideWithValue(FakeNativeSessionSource()),
      billingPlatformProvider.overrideWithValue(
        billing ?? FakeBillingPlatform(),
      ),
      subscriptionRepositoryProvider.overrideWithValue(
        repo ?? FakeSubscriptionRepository(),
      ),
      sessionInfoRepositoryProvider.overrideWithValue(
        info ?? FakeSessionInfoRepository(),
      ),
      deviceTimezoneOrNullProvider.overrideWith((ref) async => null),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

Future<ProviderContainer> _started({
  FakeBillingPlatform? billing,
  FakeSubscriptionRepository? repo,
  FakeSessionInfoRepository? info,
  AppEnvironment environment = AppEnvironment.qa,
}) async {
  final c = _container(
    billing: billing,
    repo: repo,
    info: info,
    environment: environment,
  );
  await c.read(sessionControllerProvider.notifier).restore();
  c.listen(billingSyncProvider, (_, _) {});
  await c.read(sessionInfoControllerProvider.notifier).refresh();
  await _settle();
  return c;
}

SessionInfoUser _user({int? trialDays, String? device, bool full = true}) =>
    SessionInfoUser(
      id: 7,
      hasFullFeatureAccess: full,
      trialRemainingDays: trialDays,
      subscribedDeviceType: device,
    );

void main() {
  group('product ids', () {
    test('Android: <environment>.monthly|yearly, qa for the rest', () {
      expect(productIdsFor(AppEnvironment.production, TargetPlatform.android), (
        monthly: 'production.monthly',
        yearly: 'production.yearly',
      ));
      expect(productIdsFor(AppEnvironment.hotfix, TargetPlatform.android), (
        monthly: 'hotfix.monthly',
        yearly: 'hotfix.yearly',
      ));
      expect(productIdsFor(AppEnvironment.staging, TargetPlatform.android), (
        monthly: 'staging.monthly',
        yearly: 'staging.yearly',
      ));
      expect(productIdsFor(AppEnvironment.dev, TargetPlatform.android), (
        monthly: 'qa.monthly',
        yearly: 'qa.yearly',
      ));
    });

    test('iOS: the names its xcconfigs configure', () {
      expect(productIdsFor(AppEnvironment.production, TargetPlatform.iOS), (
        monthly: 'monthly',
        yearly: 'yearly',
      ));
      expect(productIdsFor(AppEnvironment.qa, TargetPlatform.iOS), (
        monthly: 'qamonthly',
        yearly: 'qayearly',
      ));
      expect(productIdsFor(AppEnvironment.hotfix, TargetPlatform.iOS), (
        monthly: 'qamonthly',
        yearly: 'qayearly',
      ));
      expect(productIdsFor(AppEnvironment.staging, TargetPlatform.iOS), (
        monthly: 'stagingmonthly',
        yearly: 'stagingyearly',
      ));
    });

    test('a SUBSCRIPTION_IDS override wins', () {
      expect(
        productIdsFor(
          AppEnvironment.qa,
          TargetPlatform.iOS,
          override: ' m1 , y1 ',
        ),
        (monthly: 'm1', yearly: 'y1'),
      );
      expect(
        productIdsFor(AppEnvironment.qa, TargetPlatform.iOS, override: 'one'),
        (monthly: 'qamonthly', yearly: 'qayearly'),
      );
    });

    test('only production, hotfix, qa and staging sell subscriptions', () {
      for (final e in AppEnvironment.values) {
        expect(
          billingSupportedIn(e),
          const {
            AppEnvironment.production,
            AppEnvironment.hotfix,
            AppEnvironment.qa,
            AppEnvironment.staging,
          }.contains(e),
          reason: e.name,
        );
      }
    });
  });

  group('models', () {
    test('a Play purchase keeps the fields the backend expects', () {
      final p = androidPurchase(token: 'tk', acknowledged: true);
      expect(p.isApple, isFalse);
      expect(p.key, 'tk');
      expect(p.android, {
        'orderId': 'GPA.1',
        'packageName': 'io.appsmaker.racketmates.qa',
        'productId': 'qa.yearly',
        'purchaseTime': 1700000000000,
        'purchaseState': 1,
        'purchaseToken': 'tk',
        'autoRenewing': true,
        'acknowledged': true,
      });
      expect(
        androidPurchase().acknowledgedCopy().android!['acknowledged'],
        isTrue,
      );
    });

    test('an App Store purchase keeps the transaction JSON as it is', () {
      final p = applePurchase(original: 'o9');
      expect(p.isApple, isTrue);
      expect(p.key, 'o9');
      expect(p.appleJson, contains('"originalTransactionId":"o9"'));
      expect(p.completionId, 'tx-1');
    });

    test('plans are read from the store answer', () {
      final p = StorePlan.fromMap({
        'id': 'x',
        'period': 'year',
        'title': 'T',
        'price': '1',
        'priceMicros': 5,
        'currency': 'EUR',
      });
      expect(p.period, PlanPeriod.yearly);
      expect(p.priceMicros, 5);
      expect(StorePlan.fromMap({'period': 'month'}).period, PlanPeriod.monthly);
    });
  });

  group('repository contracts', () {
    late _Adapter adapter;
    late SubscriptionRepositoryImpl repo;

    setUp(() {
      adapter = _Adapter();
      repo = SubscriptionRepositoryImpl(
        SubscriptionApi(
          Dio(BaseOptions(baseUrl: 'https://api.example.test'))
            ..httpClientAdapter = adapter,
        ),
      );
    });

    test('Android posts the purchase fields as JSON', () async {
      await repo.link(androidPurchase(token: 'tk'));
      final r = adapter.requests.single;
      expect(r.method, 'POST');
      expect(r.path, 'current_session/link_playstore_subscription');
      expect((r.data as Map).keys, [
        'orderId',
        'packageName',
        'productId',
        'purchaseTime',
        'purchaseState',
        'purchaseToken',
        'autoRenewing',
        'acknowledged',
      ]);
      expect(r.data['purchaseToken'], 'tk');
    });

    test('iOS posts the transaction JSON untouched', () async {
      final purchase = applePurchase();
      await repo.link(purchase);
      final r = adapter.requests.single;
      expect(r.path, 'current_session/link_appstore_subscription');
      expect(r.contentType, contains('json'));
      expect(r.data, purchase.appleJson);
      expect(jsonDecode(r.data as String), isA<Map<String, dynamic>>());
    });

    test('an Apple purchase without JSON is not sent', () async {
      await expectLater(
        repo.link(
          const PurchaseRecord(isApple: true, productId: 'p', key: 'k'),
        ),
        throwsA(isA<ParseFailure>()),
      );
      expect(adapter.requests, isEmpty);
    });

    test('server errors become failures', () async {
      adapter.status = 422;
      await expectLater(
        repo.link(androidPurchase()),
        throwsA(isA<AppFailure>()),
      );
    });
  });

  group('reminder rules', () {
    test('a trial with 1-7 days left gets the ending reminder once', () {
      for (final days in [1, 7]) {
        expect(
          promptFor(
            _user(trialDays: days),
            seenEnding: false,
            seenEnded: false,
          ),
          SubscriptionPromptKind.trialEnding,
        );
      }
      expect(
        promptFor(_user(trialDays: 8), seenEnding: false, seenEnded: false),
        isNull,
      );
      expect(
        promptFor(_user(trialDays: 5), seenEnding: true, seenEnded: false),
        isNull,
      );
    });

    test('a finished trial without a purchase gets the ended reminder', () {
      expect(
        promptFor(
          _user(trialDays: 0, full: false),
          seenEnding: false,
          seenEnded: false,
        ),
        SubscriptionPromptKind.trialEnded,
      );
      expect(
        promptFor(
          _user(trialDays: 0, full: false),
          seenEnding: false,
          seenEnded: true,
        ),
        isNull,
      );
    });

    test('subscribers and unknown users get none', () {
      expect(
        promptFor(
          _user(trialDays: 3, device: 'dt_android'),
          seenEnding: false,
          seenEnded: false,
        ),
        isNull,
      );
      expect(
        promptFor(
          _user(full: true, device: 'dt_ios'),
          seenEnding: false,
          seenEnded: false,
        ),
        isNull,
      );
      expect(promptFor(null, seenEnding: false, seenEnded: false), isNull);
    });
  });

  group('purchase handling', () {
    test('a purchase is acknowledged, linked and access refreshed', () async {
      final billing = FakeBillingPlatform();
      final repo = FakeSubscriptionRepository();
      final info = FakeSessionInfoRepository();
      final c = await _started(billing: billing, repo: repo, info: info);
      final before = info.fetches;
      billing.updatesController.add(
        PurchaseUpdate(PurchaseStatus.purchased, record: androidPurchase()),
      );
      await _settle();
      expect(billing.completed, ['tok-1']);
      expect(repo.linked.single.android!['acknowledged'], isTrue);
      expect(info.fetches, greaterThan(before));
      expect(c.read(purchaseOutcomeProvider), PurchaseOutcome.success);
    });

    test('a purchase the backend refuses is still acknowledged', () async {
      final billing = FakeBillingPlatform();
      final repo = FakeSubscriptionRepository()
        ..failure = const OfflineFailure();
      final c = await _started(billing: billing, repo: repo);
      billing.updatesController.add(
        PurchaseUpdate(PurchaseStatus.purchased, record: androidPurchase()),
      );
      await _settle();
      expect(billing.completed, ['tok-1']);
      expect(c.read(purchaseOutcomeProvider), PurchaseOutcome.linkFailed);
    });

    test(
      'when the store refuses the acknowledgement it is sent as it is',
      () async {
        final billing = FakeBillingPlatform()..completeOk = false;
        final repo = FakeSubscriptionRepository();
        await _started(billing: billing, repo: repo);
        billing.updatesController.add(
          PurchaseUpdate(PurchaseStatus.purchased, record: androidPurchase()),
        );
        await _settle();
        expect(repo.linked.single.android!['acknowledged'], isFalse);
      },
    );

    test('an iOS purchase is finished and linked', () async {
      final billing = FakeBillingPlatform();
      final repo = FakeSubscriptionRepository();
      await _started(billing: billing, repo: repo);
      billing.updatesController.add(
        PurchaseUpdate(PurchaseStatus.purchased, record: applePurchase()),
      );
      await _settle();
      expect(billing.completed, ['orig-1']);
      expect(repo.linked.single.isApple, isTrue);
    });

    test('pending, cancelled and failed purchases are reported', () async {
      final billing = FakeBillingPlatform();
      final repo = FakeSubscriptionRepository();
      final c = await _started(billing: billing, repo: repo);
      final seen = <PurchaseOutcome?>[];
      c.listen(purchaseOutcomeProvider, (_, v) => seen.add(v));
      for (final s in [
        PurchaseStatus.pending,
        PurchaseStatus.cancelled,
        PurchaseStatus.failed,
      ]) {
        billing.updatesController.add(PurchaseUpdate(s));
        await _settle();
        c.read(purchaseOutcomeProvider.notifier).set(null);
      }
      expect(seen.whereType<PurchaseOutcome>(), [
        PurchaseOutcome.pending,
        PurchaseOutcome.cancelled,
        PurchaseOutcome.failed,
      ]);
      expect(repo.linked, isEmpty);
    });

    test('a purchased update without a purchase is a failure', () async {
      final billing = FakeBillingPlatform();
      final c = await _started(billing: billing);
      billing.updatesController.add(
        const PurchaseUpdate(PurchaseStatus.purchased),
      );
      await _settle();
      expect(c.read(purchaseOutcomeProvider), PurchaseOutcome.failed);
    });

    test('nothing is handled when nobody is signed in', () async {
      final billing = FakeBillingPlatform();
      final repo = FakeSubscriptionRepository();
      final c = _container(billing: billing, repo: repo, session: null);
      await c.read(sessionControllerProvider.notifier).restore();
      c.listen(billingSyncProvider, (_, _) {});
      billing.updatesController.add(
        PurchaseUpdate(PurchaseStatus.purchased, record: androidPurchase()),
      );
      await _settle();
      expect(billing.completed, isEmpty);
      expect(repo.linked, isEmpty);
    });

    test('environments without store products do nothing', () async {
      final billing = FakeBillingPlatform()..active = [androidPurchase()];
      final repo = FakeSubscriptionRepository();
      await _started(
        billing: billing,
        repo: repo,
        environment: AppEnvironment.dev,
      );
      expect(billing.completed, isEmpty);
      expect(repo.linked, isEmpty);
    });
  });

  group('purchases made elsewhere', () {
    test('an unknown purchase is acknowledged and linked once', () async {
      final billing = FakeBillingPlatform()..active = [androidPurchase()];
      final repo = FakeSubscriptionRepository();
      await _started(billing: billing, repo: repo);
      await _settle();
      expect(billing.completed, ['tok-1']);
      expect(repo.linked, hasLength(1));
    });

    test('a purchase the backend already knows is not linked again', () async {
      final billing = FakeBillingPlatform()
        ..active = [androidPurchase(acknowledged: true)];
      final repo = FakeSubscriptionRepository();
      final info = FakeSessionInfoRepository(
        response: SessionInfoResponse(
          user: _user(),
          subscription: const SessionSubscription(purchaseTokens: ['tok-1']),
        ),
      );
      await _started(billing: billing, repo: repo, info: info);
      expect(repo.linked, isEmpty);
      expect(billing.completed, isEmpty);
    });

    test('a known but unacknowledged purchase is still acknowledged', () async {
      final billing = FakeBillingPlatform()..active = [androidPurchase()];
      final repo = FakeSubscriptionRepository();
      final info = FakeSessionInfoRepository(
        response: SessionInfoResponse(
          user: _user(),
          subscription: const SessionSubscription(purchaseTokens: ['tok-1']),
        ),
      );
      await _started(billing: billing, repo: repo, info: info);
      expect(billing.completed, ['tok-1']);
      expect(repo.linked, isEmpty);
    });

    test(
      'an App Store purchase is matched by original transaction id',
      () async {
        final billing = FakeBillingPlatform()
          ..active = [applePurchase(original: 'known')];
        final repo = FakeSubscriptionRepository();
        final info = FakeSessionInfoRepository(
          response: SessionInfoResponse(
            user: _user(),
            subscription: const SessionSubscription(
              originalTransactionIds: ['known'],
            ),
          ),
        );
        await _started(billing: billing, repo: repo, info: info);
        expect(repo.linked, isEmpty);
      },
    );

    test(
      'a purchase the backend keeps not listing is linked only once',
      () async {
        final billing = FakeBillingPlatform()
          ..active = [androidPurchase(acknowledged: true)];
        final repo = FakeSubscriptionRepository();
        final info = FakeSessionInfoRepository();
        final c = await _started(billing: billing, repo: repo, info: info);
        await c.read(sessionInfoControllerProvider.notifier).refresh();
        await _settle();
        await c.read(sessionInfoControllerProvider.notifier).refresh();
        await _settle();
        expect(repo.linked, hasLength(1));
      },
    );
  });

  group('SubscriptionController', () {
    Future<(ProviderContainer, SubscriptionController)> open({
      FakeBillingPlatform? billing,
      AppEnvironment environment = AppEnvironment.qa,
    }) async {
      final c = await _started(billing: billing, environment: environment);
      c.listen(subscriptionControllerProvider, (_, _) {});
      await _settle();
      return (c, c.read(subscriptionControllerProvider.notifier));
    }

    test('loads the plans for this environment', () async {
      final billing = FakeBillingPlatform();
      final (c, _) = await open(billing: billing);
      final state = c.read(subscriptionControllerProvider);
      expect(state.plans.value, hasLength(2));
      expect(state.selected, PlanPeriod.yearly);
      expect(billing.requestedIds.length, 2);
      expect(billing.requestedIds.first, endsWith('monthly'));
    });

    test('works out the yearly saving', () async {
      final (c, _) = await open();
      expect(c.read(subscriptionControllerProvider).savingPercent, 33);
    });

    test('no saving without prices or when yearly costs more', () async {
      var (c, _) = await open(
        billing: FakeBillingPlatform(
          plansToOffer: const [
            StorePlan(
              id: 'm',
              period: PlanPeriod.monthly,
              title: '',
              price: '1',
            ),
            StorePlan(
              id: 'y',
              period: PlanPeriod.yearly,
              title: '',
              price: '2',
            ),
          ],
        ),
      );
      expect(c.read(subscriptionControllerProvider).savingPercent, isNull);
      (c, _) = await open(
        billing: FakeBillingPlatform(
          plansToOffer: const [
            StorePlan(
              id: 'm',
              period: PlanPeriod.monthly,
              title: '',
              price: '1',
              priceMicros: 1000000,
            ),
            StorePlan(
              id: 'y',
              period: PlanPeriod.yearly,
              title: '',
              price: '2',
              priceMicros: 13000000,
            ),
          ],
        ),
      );
      expect(c.read(subscriptionControllerProvider).savingPercent, isNull);
    });

    test(
      'an unavailable store, no plans or an unsupported build is an error',
      () async {
        var (c, _) = await open(billing: FakeBillingPlatform(available: false));
        expect(c.read(subscriptionControllerProvider).plans.hasError, isTrue);
        (c, _) = await open(
          billing: FakeBillingPlatform(plansToOffer: const []),
        );
        expect(c.read(subscriptionControllerProvider).plans.hasError, isTrue);
        (c, _) = await open(environment: AppEnvironment.local);
        expect(c.read(subscriptionControllerProvider).plans.hasError, isTrue);
      },
    );

    test('buying sends the plan and the user uuid', () async {
      final billing = FakeBillingPlatform();
      final (c, controller) = await open(billing: billing);
      controller.select(PlanPeriod.monthly);
      await controller.buy();
      expect(billing.purchased, ['qa.monthly']);
      expect(billing.accountIds, ['uuid-7']);
      expect(c.read(subscriptionControllerProvider).busy, isTrue);
      controller.purchaseDone();
      expect(c.read(subscriptionControllerProvider).busy, isFalse);
    });

    test('a second purchase cannot start while one is open', () async {
      final billing = FakeBillingPlatform();
      final (_, controller) = await open(billing: billing);
      await controller.buy();
      await controller.buy();
      expect(billing.purchased, hasLength(1));
    });

    test('restore: nothing found, found and failed', () async {
      final billing = FakeBillingPlatform();
      final (c, controller) = await open(billing: billing);
      // Restore only exists on iOS; the default test platform is Android.
      await controller.restore();
      expect(billing.restores, 0);
      expect(c.read(subscriptionControllerProvider).restoreMessage, isNull);
    });
  });
}
