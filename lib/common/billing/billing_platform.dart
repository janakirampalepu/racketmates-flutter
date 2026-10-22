import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/billing/billing_models.dart';

/// The store behind the subscription: Google Play Billing on Android,
/// StoreKit 2 on iOS, both through the `io.appsmaker.racketmates/billing`
/// channel (the iOS backend call needs StoreKit's own JSON for the
/// transaction, which a generic plugin does not expose).
abstract class BillingPlatform {
  /// The store can sell here (Play services / App Store reachable).
  Future<bool> isAvailable();

  /// The plans for [ids] with the store's prices.
  Future<List<StorePlan>> plans(List<String> ids);

  /// Starts the store's purchase sheet. The outcome arrives on [updates].
  /// [accountId] is the user's uuid (Play `obfuscatedAccountId`, StoreKit
  /// `appAccountToken`) so the backend can match the purchase to the user.
  Future<void> purchase(String productId, {required String accountId});

  /// Purchases that are active for this store account.
  Future<List<PurchaseRecord>> activePurchases();

  /// Asks the store to sync (iOS `AppStore.sync`), then lists the active
  /// purchases.
  Future<List<PurchaseRecord>> restore();

  /// Tells the store the purchase is handled (Android acknowledges, iOS
  /// finishes the transaction). Returns whether the store accepted it.
  Future<bool> complete(PurchaseRecord record);

  /// Opens the store's code redemption (iOS sheet; Android opens the web page
  /// from Dart).
  Future<void> redeemCode();

  Stream<PurchaseUpdate> get updates;
}

class ChannelBillingPlatform implements BillingPlatform {
  ChannelBillingPlatform() {
    channel.setMethodCallHandler(_onCall);
  }

  static const channel = MethodChannel('io.appsmaker.racketmates/billing');

  final _updates = StreamController<PurchaseUpdate>.broadcast();

  Future<Object?> _onCall(MethodCall call) async {
    if (call.method != 'onPurchase') return null;
    final args = call.arguments;
    if (args is! Map) return null;
    final status = switch (args['status']) {
      'purchased' => PurchaseStatus.purchased,
      'pending' => PurchaseStatus.pending,
      'cancelled' => PurchaseStatus.cancelled,
      _ => PurchaseStatus.failed,
    };
    final record = args['purchase'];
    _updates.add(
      PurchaseUpdate(
        status,
        record: record is Map ? PurchaseRecord.fromMap(record) : null,
        message: args['message'] as String?,
      ),
    );
    return null;
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null; // no platform code (tests, unsupported platform)
    } on PlatformException {
      return null;
    }
  }

  List<PurchaseRecord> _records(List<Object?>? raw) => [
    for (final item in raw ?? const <Object?>[])
      if (item is Map) PurchaseRecord.fromMap(item),
  ];

  @override
  Future<bool> isAvailable() async =>
      await _invoke<bool>('isAvailable') ?? false;

  @override
  Future<List<StorePlan>> plans(List<String> ids) async {
    final raw = await _invoke<List<Object?>>('queryProducts', {'ids': ids});
    return [
      for (final item in raw ?? const <Object?>[])
        if (item is Map) StorePlan.fromMap(item),
    ];
  }

  @override
  Future<void> purchase(String productId, {required String accountId}) async {
    try {
      await channel.invokeMethod<void>('purchase', {
        'id': productId,
        'accountId': accountId,
      });
    } on MissingPluginException {
      _updates.add(const PurchaseUpdate(PurchaseStatus.failed));
    } on PlatformException catch (e) {
      _updates.add(PurchaseUpdate(PurchaseStatus.failed, message: e.message));
    }
  }

  @override
  Future<List<PurchaseRecord>> activePurchases() async =>
      _records(await _invoke<List<Object?>>('activePurchases'));

  @override
  Future<List<PurchaseRecord>> restore() async =>
      _records(await _invoke<List<Object?>>('restore'));

  @override
  Future<bool> complete(PurchaseRecord record) async =>
      await _invoke<bool>('complete', {'id': record.completionId}) ?? false;

  @override
  Future<void> redeemCode() => _invoke<void>('redeemCode');

  @override
  Stream<PurchaseUpdate> get updates => _updates.stream;
}

final billingPlatformProvider = Provider<BillingPlatform>(
  (ref) => ChannelBillingPlatform(),
);

/// Whether this device's store has restore (iOS; Play has none).
bool storeHasRestore(TargetPlatform platform) => platform == TargetPlatform.iOS;
