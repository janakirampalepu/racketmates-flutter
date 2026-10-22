import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/billing/billing_models.dart';
import 'package:racketmates/common/billing/billing_platform.dart';
import 'package:racketmates/common/billing/product_ids.dart';
import 'package:racketmates/common/billing/subscription_repository.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/session/session_info_controller.dart';

/// What the last purchase came to; the subscription screen shows it once.
class PurchaseOutcomeNotifier extends Notifier<PurchaseOutcome?> {
  @override
  PurchaseOutcome? build() => null;

  // Riverpod 3 notifiers expose state through a setter on the notifier itself.
  // ignore: use_setters_to_change_properties
  void set(PurchaseOutcome? outcome) => state = outcome;
}

final purchaseOutcomeProvider =
    NotifierProvider<PurchaseOutcomeNotifier, PurchaseOutcome?>(
      PurchaseOutcomeNotifier.new,
    );

/// Whether this build and device can sell subscriptions.
final billingSupportedProvider = Provider<bool>(
  (ref) => billingSupportedIn(ref.watch(environmentConfigProvider).environment),
);

/// Finishes purchases with the store and links them to the user on the
/// backend; access itself always comes from `session_info`, never from the
/// purchase (native `PurchaseManager` / `SubscriptionPicker`).
class BillingService {
  BillingService(this._ref);

  final Ref _ref;
  final Set<String> _linked = {};
  bool _syncing = false;

  BillingPlatform get _platform => _ref.read(billingPlatformProvider);

  /// A purchase just made (or restored): finish it, link it, refresh access.
  /// Finishing comes first so the store never refunds a purchase for being
  /// left unacknowledged, whatever the backend says. Returns whether the
  /// backend accepted it.
  Future<bool> handle(PurchaseRecord purchase) async {
    var record = purchase;
    if (!record.acknowledged && await _platform.complete(record)) {
      record = record.acknowledgedCopy();
    }
    return link(record);
  }

  Future<bool> link(PurchaseRecord purchase) async {
    try {
      await _ref.read(subscriptionRepositoryProvider).link(purchase);
    } on AppFailure {
      return false; // found again by the next sync
    }
    _linked.add(purchase.key);
    if (_ref.mounted) {
      await _ref.read(sessionInfoControllerProvider.notifier).refresh();
    }
    return true;
  }

  bool _known(PurchaseRecord purchase) {
    final subscription = _ref.read(sessionInfoControllerProvider).subscription;
    final known = purchase.isApple
        ? subscription?.originalTransactionIds
        : subscription?.purchaseTokens;
    return _linked.contains(purchase.key) ||
        (known ?? const <String>[]).contains(purchase.key);
  }

  /// Purchases made elsewhere (another install, a family device, a restore by
  /// the store) that the backend may not know yet: acknowledge any the store
  /// still waits for and link the unknown ones (native `queryPurchasesAsync`
  /// after the session refresh).
  Future<void> syncActive() async {
    if (_syncing || _ref.read(sessionControllerProvider) is! SignedIn) return;
    _syncing = true;
    try {
      if (!await _platform.isAvailable()) return;
      for (var record in await _platform.activePurchases()) {
        if (!record.acknowledged &&
            !record.isApple &&
            await _platform.complete(record)) {
          record = record.acknowledgedCopy();
        }
        if (!_known(record)) await link(record);
      }
    } finally {
      _syncing = false;
    }
  }
}

final billingServiceProvider = Provider<BillingService>(BillingService.new);

/// Wires billing into the running app (watched once by the app): reacts to the
/// store's purchase updates and looks for purchases the backend does not know
/// whenever `session_info` has been loaded.
final billingSyncProvider = Provider<void>((ref) {
  if (!ref.watch(billingSupportedProvider)) return;
  final service = ref.read(billingServiceProvider);
  final outcome = ref.read(purchaseOutcomeProvider.notifier);

  final subscription = ref.watch(billingPlatformProvider).updates.listen((
    update,
  ) async {
    // A purchase that arrives while nobody is signed in stays with the store
    // and is delivered again after sign-in.
    if (ref.read(sessionControllerProvider) is! SignedIn) return;
    switch (update.status) {
      case PurchaseStatus.purchased:
        final record = update.record;
        if (record == null) {
          outcome.set(PurchaseOutcome.failed);
          return;
        }
        final linked = await service.handle(record);
        if (ref.mounted) {
          outcome.set(
            linked ? PurchaseOutcome.success : PurchaseOutcome.linkFailed,
          );
        }
      case PurchaseStatus.pending:
        outcome.set(PurchaseOutcome.pending);
      case PurchaseStatus.cancelled:
        outcome.set(PurchaseOutcome.cancelled);
      case PurchaseStatus.failed:
        outcome.set(PurchaseOutcome.failed);
    }
  });
  ref.onDispose(() => unawaited(subscription.cancel()));

  ref.listen(sessionInfoControllerProvider, (previous, next) {
    if (next.loaded) unawaited(service.syncActive());
  }, fireImmediately: true);
});

/// The ids to sell on this device.
final productIdsProvider = Provider<({String monthly, String yearly})>(
  (ref) => productIdsFor(
    ref.watch(environmentConfigProvider).environment,
    defaultTargetPlatform,
  ),
);
