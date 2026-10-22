import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

part 'subscription_api.g.dart';

/// Links a store purchase to the user (native `UserApiServices`,
/// `TenmatesAPIs`).
@RestApi()
abstract class SubscriptionApi {
  factory SubscriptionApi(Dio dio, {String? baseUrl}) = _SubscriptionApi;

  /// The Play purchase: orderId, packageName, productId, purchaseTime,
  /// purchaseState, purchaseToken, autoRenewing, acknowledged.
  @POST('current_session/link_playstore_subscription')
  Future<void> linkPlaystore(@Body() Map<String, dynamic> body);

  /// The StoreKit transaction's JSON representation, sent as it is.
  @POST('current_session/link_appstore_subscription')
  @Headers({'Content-Type': 'application/json'})
  Future<void> linkAppstore(@Body() String rawJson);
}
