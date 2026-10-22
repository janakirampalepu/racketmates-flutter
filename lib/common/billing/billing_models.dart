/// A subscription the store offers (monthly or yearly).
enum PlanPeriod { monthly, yearly }

class StorePlan {
  const StorePlan({
    required this.id,
    required this.period,
    required this.title,
    required this.price,
    this.priceMicros,
    this.currencyCode,
  });

  factory StorePlan.fromMap(Map<Object?, Object?> map) {
    final period = map['period'] == 'year'
        ? PlanPeriod.yearly
        : PlanPeriod.monthly;
    return StorePlan(
      id: map['id'] as String? ?? '',
      period: period,
      title: map['title'] as String? ?? '',
      price: map['price'] as String? ?? '',
      priceMicros: (map['priceMicros'] as num?)?.toInt(),
      currencyCode: map['currency'] as String?,
    );
  }

  final String id;
  final PlanPeriod period;
  final String title;

  /// The price as the store formats it (`$4.99`).
  final String price;

  /// The price in millionths of the currency, when the store says.
  final int? priceMicros;
  final String? currencyCode;
}

/// A purchase as the store reports it, with what the backend needs to link it
/// to the user. Android sends the fields of the Play purchase; iOS sends the
/// StoreKit transaction's JSON representation untouched (both exactly as the
/// native apps do).
class PurchaseRecord {
  const PurchaseRecord({
    required this.isApple,
    required this.productId,
    required this.key,
    this.android,
    this.appleJson,
    this.acknowledged = false,
    this.completionId,
  });

  factory PurchaseRecord.fromMap(Map<Object?, Object?> map) {
    final apple = map['platform'] == 'ios';
    if (apple) {
      final original = map['originalTransactionId']?.toString() ?? '';
      return PurchaseRecord(
        isApple: true,
        productId: map['productId'] as String? ?? '',
        key: original,
        appleJson: map['json'] as String?,
        completionId: map['transactionId']?.toString(),
      );
    }
    final token = map['purchaseToken'] as String? ?? '';
    return PurchaseRecord(
      isApple: false,
      productId: map['productId'] as String? ?? '',
      key: token,
      acknowledged: map['acknowledged'] as bool? ?? false,
      completionId: token,
      android: {
        'orderId': map['orderId'],
        'packageName': map['packageName'],
        'productId': map['productId'],
        'purchaseTime': map['purchaseTime'],
        'purchaseState': map['purchaseState'],
        'purchaseToken': token,
        'autoRenewing': map['autoRenewing'],
        'acknowledged': map['acknowledged'],
      },
    );
  }

  final bool isApple;
  final String productId;

  /// Identifies the purchase to the backend: the Play purchase token, or the
  /// StoreKit original transaction id (what `session_info` lists).
  final String key;
  final Map<String, dynamic>? android;
  final String? appleJson;
  final bool acknowledged;

  /// What the store needs to finish the purchase (Android acknowledges the
  /// purchase token, iOS finishes the transaction id).
  final String? completionId;

  /// The same purchase after the store accepted the acknowledgement.
  PurchaseRecord acknowledgedCopy() => PurchaseRecord(
    isApple: isApple,
    productId: productId,
    key: key,
    android: android == null ? null : {...android!, 'acknowledged': true},
    appleJson: appleJson,
    acknowledged: true,
    completionId: completionId,
  );
}

enum PurchaseStatus { purchased, pending, cancelled, failed }

/// The store reporting what became of a purchase.
class PurchaseUpdate {
  const PurchaseUpdate(this.status, {this.record, this.message});

  final PurchaseStatus status;
  final PurchaseRecord? record;
  final String? message;
}

/// What the subscription screen should tell the user (set by the billing
/// sync, read once).
enum PurchaseOutcome { success, pending, cancelled, failed, linkFailed }
