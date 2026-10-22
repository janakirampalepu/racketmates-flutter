package io.appsmaker.racketmates

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.CancellationSignal
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `io.appsmaker.racketmates/location`: permission while the app is in use and
 * one position fix from the platform location manager (no Google services
 * needed). Methods: permissionStatus, requestPermission, currentPosition,
 * openSettings.
 */
class LocationPlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var pendingPermission: MethodChannel.Result? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, NAME)
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun granted(): Boolean =
        ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED

    private fun prefs() = activity.getSharedPreferences(PREFS, android.content.Context.MODE_PRIVATE)

    private fun status(): String {
        if (granted()) return "granted"
        // Android only reports "not granted": remember whether we asked.
        return if (prefs().getBoolean(ASKED, false)) "denied" else "notDetermined"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "permissionStatus" -> result.success(status())
            "requestPermission" -> request(result)
            "currentPosition" -> currentPosition(result)
            "openSettings" -> {
                activity.startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}"))
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun request(result: MethodChannel.Result) {
        if (granted()) {
            result.success("granted")
            return
        }
        if (pendingPermission != null) {
            result.error("busy", "A permission request is already open", null)
            return
        }
        pendingPermission = result
        prefs().edit().putBoolean(ASKED, true).apply()
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
            REQUEST_CODE,
        )
    }

    /** Called by the activity with the system's answer. */
    fun onPermissionResult(requestCode: Int) {
        if (requestCode != REQUEST_CODE) return
        pendingPermission?.success(status())
        pendingPermission = null
    }

    @Suppress("MissingPermission")
    private fun currentPosition(result: MethodChannel.Result) {
        if (!granted()) {
            result.success(null)
            return
        }
        val manager = activity.getSystemService(LocationManager::class.java)
        val provider = listOf(LocationManager.FUSED_PROVIDER, LocationManager.NETWORK_PROVIDER, LocationManager.GPS_PROVIDER)
            .firstOrNull { runCatching { manager.isProviderEnabled(it) }.getOrDefault(false) }
        if (provider == null) {
            result.success(null)
            return
        }
        val signal = CancellationSignal()
        manager.getCurrentLocation(provider, signal, ContextCompat.getMainExecutor(activity)) { location: Location? ->
            result.success(location?.let { mapOf("latitude" to it.latitude, "longitude" to it.longitude) })
        }
    }

    companion object {
        const val NAME = "io.appsmaker.racketmates/location"
        private const val PREFS = "location_plugin"
        private const val ASKED = "location_permission_asked"
        private const val REQUEST_CODE = 4712
    }
}
