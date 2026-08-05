package com.trigrid.game

import android.content.pm.ActivityInfo
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyDeviceOrientationPolicy()
        preferBalancedRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        preferBalancedRefreshRate()
    }

    private fun preferBalancedRefreshRate() {
        val layoutParams = window.attributes
        layoutParams.preferredRefreshRate = 60.0f
        window.attributes = layoutParams
    }

    private fun applyDeviceOrientationPolicy() {
        requestedOrientation = if (resources.configuration.smallestScreenWidthDp >= 600) {
            ActivityInfo.SCREEN_ORIENTATION_FULL_USER
        } else {
            ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        }
    }
}
