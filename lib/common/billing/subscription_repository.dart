import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/billing/billing_models.dart';
import 'package:racketmates/common/billing/subscription_api.dart';
import 'package:racketmates/common/errors/app_failure.dart';

abstract class SubscriptionRepository {
  /// Tells the backend about [purchase] so it can grant access.
  Future<void> link(PurchaseRecord purchase);
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  const SubscriptionRepositoryImpl(this.api);

  final SubscriptionApi api;

  @override
  Future<void> link(PurchaseRecord purchase) async {
    try {
      if (purchase.isApple) {
        final json = purchase.appleJson;
        if (json == null || json.isEmpty) throw const ParseFailure();
        await api.linkAppstore(json);
      } else {
        await api.linkPlaystore(purchase.android ?? const {});
      }
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) =>
      SubscriptionRepositoryImpl(SubscriptionApi(ref.watch(apiDioProvider))),
);
