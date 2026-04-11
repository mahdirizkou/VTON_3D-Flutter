package com.example.vton_auth

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.example.vton_auth/camerakit"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openCameraKit" -> {
                        val lensGroupId =
                            call.argument<String>("lensGroupId") ?: BuildConfig.LENS_GROUP_ID
                        val lensId =
                            call.argument<String>("lensId") ?: BuildConfig.LENS_ID

                        val intent = Intent(this, CameraKitActivity::class.java).apply {
                            putExtra("lens_group_id", lensGroupId)
                            putExtra("lens_id", lensId)
                        }
                        startActivity(intent)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
