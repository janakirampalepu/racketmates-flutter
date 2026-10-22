package io.appsmaker.racketmates

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `io.appsmaker.racketmates/push`: the Android side of push notifications.
 *
 * Firebase is configured by `google-services.json`, which comes from CI or a
 * developer machine and is never committed. Without it [initialize] answers
 * false and the rest of the app carries on without push.
 *
 * Methods: initialize, permissionStatus, requestPermission, token,
 * launchMessage, openSettings. Calls to Dart: onToken, onMessage, onOpened.
 */
class PushPlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var pendingPermission: MethodChannel.Result? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, NAME)
        channel.setMethodCallHandler(this)
        instance = this
    }

    fun dispose() {
        if (instance === this) instance = null
        channel.setMethodCallHandler(null)
    }

    private fun firebaseReady(): Boolean =
        FirebaseApp.getApps(activity).isNotEmpty() || FirebaseApp.initializeApp(activity) != null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> result.success(initialize())
            "permissionStatus" -> result.success(permissionStatus())
            "requestPermission" -> requestPermission(result)
            "token" -> fetchToken(result)
            "launchMessage" -> {
                result.success(messageFrom(activity.intent))
                activity.intent?.replaceExtras(android.os.Bundle())
            }
            "openSettings" -> {
                openSettings()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun initialize(): Boolean {
        if (!firebaseReady()) return false
        createChannel(activity)
        return true
    }

    private fun permissionStatus(): String {
        if (NotificationManagerCompat.from(activity).areNotificationsEnabled()) return "granted"
        // Android only reports "not granted": remember whether we asked.
        return if (prefs().getBoolean(ASKED, false)) "denied" else "notDetermined"
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(permissionStatus())
            return
        }
        if (pendingPermission != null) {
            result.error("busy", "A permission request is already open", null)
            return
        }
        pendingPermission = result
        prefs().edit().putBoolean(ASKED, true).apply()
        ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_CODE)
    }

    /** Called by the activity with the system's answer. */
    fun onPermissionResult(requestCode: Int) {
        if (requestCode != REQUEST_CODE) return
        pendingPermission?.success(permissionStatus())
        pendingPermission = null
    }

    private fun fetchToken(result: MethodChannel.Result) {
        if (!firebaseReady()) {
            result.success(null)
            return
        }
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            result.success(if (task.isSuccessful) task.result else null)
        }
    }

    private fun openSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            activity.startActivity(intent)
        } catch (_: Exception) {
            activity.startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    /** A notification tapped while the app was running (the activity is `singleTop`). */
    fun onNewIntent(intent: Intent?) {
        messageFrom(intent)?.let { channel.invokeMethod("onOpened", it) }
    }

    private fun prefs() = activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    companion object {
        const val NAME = "io.appsmaker.racketmates/push"
        const val CHANNEL_ID = "racketmates_default"
        private const val PREFS = "push_plugin"
        private const val ASKED = "notification_permission_asked"
        private const val REQUEST_CODE = 4711

        @Volatile
        private var instance: PushPlugin? = null

        /** True while an activity is on screen (messages then show inside the app). */
        @Volatile
        var foreground = false

        fun createChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java)
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        context.getString(R.string.push_channel_name),
                        NotificationManager.IMPORTANCE_HIGH,
                    ),
                )
            }
        }

        /** The payload of a notification the system delivered through [intent]'s extras, if any. */
        fun messageFrom(intent: Intent?): Map<String, Any?>? {
            val extras = intent?.extras ?: return null
            if (!extras.containsKey("google.message_id")) return null
            val data = HashMap<String, String>()
            for (key in extras.keySet()) {
                if (key.startsWith("google.") || key.startsWith("gcm.") || key == "from" || key == "collapse_key") continue
                extras.get(key)?.let { data[key] = it.toString() }
            }
            return mapOf("id" to extras.getString("google.message_id"), "data" to data)
        }

        fun emitToken(token: String) {
            instance?.channel?.invokeMethod("onToken", token)
        }

        /** Returns false when the app is not open to show it. */
        fun emitForeground(message: Map<String, Any?>): Boolean {
            val plugin = instance ?: return false
            if (!foreground) return false
            plugin.activity.runOnUiThread { plugin.channel.invokeMethod("onMessage", message) }
            return true
        }
    }
}
