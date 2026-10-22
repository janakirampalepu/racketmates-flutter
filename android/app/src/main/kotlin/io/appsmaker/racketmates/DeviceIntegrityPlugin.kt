package io.appsmaker.racketmates

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** `io.appsmaker.racketmates/device_integrity`: `isCompromised` -> Boolean. */
class DeviceIntegrityPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isCompromised" -> Thread {
                val compromised = try {
                    RootChecks.isCompromised(context)
                } catch (e: Exception) {
                    false // a failing check must not lock everyone out
                }
                android.os.Handler(context.mainLooper).post { result.success(compromised) }
            }.start()
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "io.appsmaker.racketmates/device_integrity"
    }
}
