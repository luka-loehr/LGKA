package com.lgka

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Use consistent edge-to-edge approach across all Android versions
        // This avoids deprecated API usage while maintaining compatibility
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
} 