package com.pizzaorder.pizza_order_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pizzaorder/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareToLine") {
                val text = call.argument<String>("text") ?: ""
                try {
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                        setPackage("jp.naver.line.android")
                    }
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    // LINE not installed, fall back
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
