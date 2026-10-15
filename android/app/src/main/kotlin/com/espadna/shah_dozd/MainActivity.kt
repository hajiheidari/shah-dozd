package com.espadna.shah_dozd

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AdsBridge.register(this, flutterEngine)
        // While roles are being dealt the window is marked secure: no
        // screenshots and a blank app-switcher thumbnail (lib/app/privacy.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "shahdozd/privacy").setMethodCallHandler { call, result ->
            if (call.method == "secure") {
                if (call.arguments == true) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
