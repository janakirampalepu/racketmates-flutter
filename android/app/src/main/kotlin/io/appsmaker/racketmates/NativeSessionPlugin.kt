package io.appsmaker.racketmates

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * `io.appsmaker.racketmates/native_session`: reads (`read`) and removes
 * (`clear`) the OAuth session the native Android app stored. The native app
 * keeps it as Gson JSON under `sessionDetails` in the
 * `EncryptedSharedPreferences` file `ten_mates-app-preference`, with the
 * default AndroidKeyStore master key; this app has the same application id and
 * signing key, so the key and the file survive the update.
 */
class NativeSessionPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    /** Null when the native app never wrote the file (a fresh install). */
    private fun preferences() = try {
        val file = File(context.applicationInfo.dataDir, "shared_prefs/$FILE.xml")
        if (!file.exists()) {
            null
        } else {
            val masterKey = MasterKey.Builder(context, MasterKey.DEFAULT_MASTER_KEY_ALIAS)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            EncryptedSharedPreferences.create(
                context,
                FILE,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
            )
        }
    } catch (e: Exception) {
        null // key lost or file unreadable: the user signs in again
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "read" -> result.success(
                preferences()?.getString(KEY, null)?.takeIf { it.isNotBlank() },
            )
            "clear" -> {
                try {
                    preferences()?.edit()?.remove(KEY)?.apply()
                } catch (e: Exception) {
                    // best effort
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "io.appsmaker.racketmates/native_session"

        /** Native `AppConstants.SHARED_PREFERENCE_NAME`. */
        private const val FILE = "ten_mates-app-preference"

        /** Native `SharePrefKeys.SESSION_TOKEN`. */
        private const val KEY = "sessionDetails"
    }
}
