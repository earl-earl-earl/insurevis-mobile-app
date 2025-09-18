package com.example.insurevis

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import java.io.OutputStream
import android.content.ContentResolver
import android.content.Intent
import android.app.Activity
import android.provider.DocumentsContract

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

        // Separate channel for file writing to content URIs (SAF)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "insurevis/file_writer").setMethodCallHandler { call, result ->
            when (call.method) {
                "writeToUri" -> {
                    try {
                        val args = call.arguments as Map<String, Any>
                        val uriString = args["uri"] as String
                        val bytes = args["bytes"] as ByteArray

                        val uri = Uri.parse(uriString)
                        val resolver: ContentResolver = this.contentResolver
                        var out: OutputStream? = null
                        try {
                            out = resolver.openOutputStream(uri)
                            if (out == null) throw Exception("Could not open output stream for URI: $uriString")
                            out.write(bytes)
                            out.flush()
                        } finally {
                            out?.close()
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WRITE_ERROR", e.message, null)
                    }
                }
                "pickDirectory" -> {
                    // Launch ACTION_OPEN_DOCUMENT_TREE and return the tree URI via a pending result
                    try {
                        if (pendingDirectoryResult != null) {
                            result.error("PENDING", "Another pickDirectory in progress", null)
                            return@setMethodCallHandler
                        }

                        pendingDirectoryResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                        intent.addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                        intent.addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
                        startActivityForResult(intent, REQUEST_CODE_PICK_DIR)
                    } catch (e: Exception) {
                        pendingDirectoryResult = null
                        result.error("PICK_ERROR", e.message, null)
                    }
                }
                "saveFileToTree" -> {
                    try {
                        val args = call.arguments as Map<String, Any>
                        val treeUriString = args["treeUri"] as String
                        val fileName = args["fileName"] as String
                        val bytes = args["bytes"] as ByteArray

                        val treeUri = Uri.parse(treeUriString)
                        // Create document inside the tree
                        val newFileUri = DocumentsContract.createDocument(contentResolver, treeUri, "application/pdf", fileName)
                            ?: throw Exception("Could not create document in tree: $treeUriString")

                        var out: OutputStream? = null
                        try {
                            out = contentResolver.openOutputStream(newFileUri)
                            if (out == null) throw Exception("Could not open output stream for new file")
                            out.write(bytes)
                            out.flush()
                        } finally {
                            out?.close()
                        }

                        result.success(newFileUri.toString())
                    } catch (e: Exception) {
                        result.error("SAVE_TREE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private var pendingDirectoryResult: MethodChannel.Result? = null
    private val REQUEST_CODE_PICK_DIR = 1001

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_PICK_DIR) {
            val res = pendingDirectoryResult
            pendingDirectoryResult = null
            if (res == null) return

            if (resultCode == Activity.RESULT_OK && data != null) {
                try {
                    val treeUri = data.data
                    if (treeUri != null) {
                        // Persist permissions
                        val takeFlags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                        contentResolver.takePersistableUriPermission(treeUri, takeFlags)
                        res.success(treeUri.toString())
                    } else {
                        res.success(null)
                    }
                } catch (e: Exception) {
                    res.error("ACTIVITY_RESULT_ERROR", e.message, null)
                }
            } else {
                res.success(null)
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
