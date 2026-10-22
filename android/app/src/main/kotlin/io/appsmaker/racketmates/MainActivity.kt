package io.appsmaker.racketmates

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var push: PushPlugin? = null
    private var billing: BillingPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        DeviceIntegrityPlugin(applicationContext).register(messenger)
        NativeSessionPlugin(applicationContext).register(messenger)
        push = PushPlugin(this).also { it.register(messenger) }
        billing = BillingPlugin(this).also { it.register(messenger) }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        push?.dispose()
        push = null
        billing?.dispose()
        billing = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        push?.onNewIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        PushPlugin.foreground = true
    }

    override fun onPause() {
        PushPlugin.foreground = false
        super.onPause()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        push?.onPermissionResult(requestCode)
    }
}
