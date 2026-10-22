package io.appsmaker.racketmates

import android.app.Activity
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `io.appsmaker.racketmates/billing`: Google Play Billing for the subscription
 * (the same flow as the native `SubscriptionPicker`: subscriptions only, the
 * first offer of the product, the user's uuid as the obfuscated account id).
 *
 * Methods: isAvailable, queryProducts{ids}, purchase{id, accountId},
 * activePurchases, restore, complete{id}, redeemCode. Call to Dart:
 * onPurchase{status, purchase?, message?}.
 */
class BillingPlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var client: BillingClient? = null
    private val products = HashMap<String, ProductDetails>()

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, NAME)
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        client?.endConnection()
        client = null
    }

    private fun billing(): BillingClient {
        client?.let { return it }
        val created = BillingClient.newBuilder(activity)
            .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
            .setListener { result, purchases -> onPurchasesUpdated(result, purchases) }
            .build()
        client = created
        return created
    }

    /** Runs [action] once connected to Play; [onFail] when Play cannot be reached. */
    private fun connected(onFail: () -> Unit, action: (BillingClient) -> Unit) {
        val c = billing()
        if (c.isReady) {
            action(c)
            return
        }
        c.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) action(c) else onFail()
            }

            override fun onBillingServiceDisconnected() {
                // Reconnected by the next call.
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> connected({ result.success(false) }) { result.success(true) }
            "queryProducts" -> queryProducts(call.argument<List<String>>("ids").orEmpty(), result)
            "purchase" -> purchase(call.argument<String>("id").orEmpty(), call.argument<String>("accountId").orEmpty(), result)
            "activePurchases", "restore" -> activePurchases(result)
            "complete" -> acknowledge(call.argument<String>("id").orEmpty(), result)
            "redeemCode" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    private fun queryProducts(ids: List<String>, result: MethodChannel.Result) {
        connected({ result.success(emptyList<Any>()) }) { c ->
            val list = ids.map {
                QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(it)
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build()
            }
            val params = QueryProductDetailsParams.newBuilder().setProductList(list).build()
            c.queryProductDetailsAsync(params) { _, details ->
                val found = details.productDetailsList
                found.forEach { products[it.productId] = it }
                activity.runOnUiThread { result.success(found.mapNotNull(::describe)) }
            }
        }
    }

    /** The price and period of the recurring phase of the product's first offer. */
    private fun describe(product: ProductDetails): Map<String, Any?>? {
        val phases = product.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList
        val phase = phases?.lastOrNull() ?: return null
        return mapOf(
            "id" to product.productId,
            "title" to product.name,
            "price" to phase.formattedPrice,
            "priceMicros" to phase.priceAmountMicros,
            "currency" to phase.priceCurrencyCode,
            "period" to if (phase.billingPeriod.contains("Y")) "year" else "month",
        )
    }

    private fun purchase(id: String, accountId: String, result: MethodChannel.Result) {
        val details = products[id]
        val offer = details?.subscriptionOfferDetails?.firstOrNull()
        if (details == null || offer == null) {
            result.error("unknown_product", "Product $id is not loaded", null)
            return
        }
        connected({ result.error("unavailable", "Google Play is not available", null) }) { c ->
            val builder = BillingFlowParams.newBuilder().setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(details)
                        .setOfferToken(offer.offerToken)
                        .build(),
                ),
            )
            if (accountId.isNotEmpty()) builder.setObfuscatedAccountId(accountId)
            val launched = c.launchBillingFlow(activity, builder.build())
            if (launched.responseCode == BillingClient.BillingResponseCode.OK) {
                result.success(null)
            } else {
                result.error("launch_failed", launched.debugMessage, null)
            }
        }
    }

    private fun onPurchasesUpdated(result: BillingResult, purchases: List<Purchase>?) {
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK ->
                purchases.orEmpty().forEach { p ->
                    when (p.purchaseState) {
                        Purchase.PurchaseState.PURCHASED -> emit("purchased", map(p), null)
                        Purchase.PurchaseState.PENDING -> emit("pending", null, null)
                        else -> emit("failed", null, null)
                    }
                }
            BillingClient.BillingResponseCode.USER_CANCELED -> emit("cancelled", null, null)
            else -> emit("failed", null, result.debugMessage)
        }
    }

    private fun emit(status: String, purchase: Map<String, Any?>?, message: String?) {
        activity.runOnUiThread {
            channel.invokeMethod("onPurchase", mapOf("status" to status, "purchase" to purchase, "message" to message))
        }
    }

    private fun map(p: Purchase): Map<String, Any?> = mapOf(
        "platform" to "android",
        "orderId" to p.orderId,
        "packageName" to p.packageName,
        "productId" to (p.products.firstOrNull() ?: ""),
        "purchaseTime" to p.purchaseTime,
        "purchaseState" to p.purchaseState,
        "purchaseToken" to p.purchaseToken,
        "autoRenewing" to p.isAutoRenewing,
        "acknowledged" to p.isAcknowledged,
    )

    private fun activePurchases(result: MethodChannel.Result) {
        connected({ result.success(emptyList<Any>()) }) { c ->
            val params = QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build()
            c.queryPurchasesAsync(params) { billingResult, list ->
                val active = if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    list.filter { it.purchaseState == Purchase.PurchaseState.PURCHASED }.map(::map)
                } else {
                    emptyList()
                }
                activity.runOnUiThread { result.success(active) }
            }
        }
    }

    private fun acknowledge(token: String, result: MethodChannel.Result) {
        if (token.isEmpty()) {
            result.success(false)
            return
        }
        connected({ result.success(false) }) { c ->
            val params = AcknowledgePurchaseParams.newBuilder().setPurchaseToken(token).build()
            c.acknowledgePurchase(params) { r ->
                activity.runOnUiThread { result.success(r.responseCode == BillingClient.BillingResponseCode.OK) }
            }
        }
    }

    companion object {
        const val NAME = "io.appsmaker.racketmates/billing"
    }
}
