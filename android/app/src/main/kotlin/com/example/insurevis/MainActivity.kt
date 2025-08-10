package com.example.insurevis

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CAMERA_BUFFER_CHANNEL = "camera_buffer_optimization"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAMERA_BUFFER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initBufferOptimization" -> {
                    initBufferOptimization()
                    result.success(null)
                }
                "clearBuffers" -> {
                    clearBuffers()
                    result.success(null)
                }
                "optimizeMemory" -> {
                    optimizeMemory()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initBufferOptimization() {
        // Configure camera buffer settings
        try {
            // Force garbage collection
            System.gc()
            // Additional Android-specific optimizations can be added here
        } catch (e: Exception) {
            // Handle any errors silently
        }
    }

    private fun clearBuffers() {
        try {
            // Force garbage collection to clear memory
            System.gc()
            // Sleep briefly to allow GC to complete
            Thread.sleep(50)
        } catch (e: Exception) {
            // Handle any errors silently
        }
    }

    private fun optimizeMemory() {
        try {
            // Request memory optimization
            System.gc()
            Runtime.getRuntime().gc()
        } catch (e: Exception) {
            // Handle any errors silently
        }
    }
}
