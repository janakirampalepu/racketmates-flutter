package io.appsmaker.racketmates

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        DeviceIntegrityPlugin(applicationContext).register(messenger)
        NativeSessionPlugin(applicationContext).register(messenger)
    }
}
