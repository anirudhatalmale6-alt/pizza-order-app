package com.pizzaorder.pizza_order_app

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pizzaorder/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareToLine") {
                val text = call.argument<String>("text") ?: ""
                val imagePath = call.argument<String>("imagePath")
                try {
                    if (imagePath != null) {
                        // Share image + text to LINE
                        val file = File(imagePath)
                        val uri: Uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "image/*"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            putExtra(Intent.EXTRA_TEXT, text)
                            setPackage("jp.naver.line.android")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(intent)
                        result.success(true)
                    } else {
                        // Text only to LINE
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                            setPackage("jp.naver.line.android")
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                } catch (e: Exception) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
