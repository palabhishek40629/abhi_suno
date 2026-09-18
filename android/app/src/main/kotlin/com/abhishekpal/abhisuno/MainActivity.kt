package com.abhishekpal.abhisuno

import android.content.Intent
import android.net.Uri
import android.os.Environment
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: AudioServiceActivity() {
    private val SHARE_CHANNEL = "com.abhishekpal.abhisuno/share"
    private val NATIVE_CHANNEL = "com.abhishekpal.abhisuno/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Legacy Share Channel for backwards compatibility
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareText") {
                val text = call.argument<String>("text") ?: ""
                val title = call.argument<String>("title") ?: "Share Song"
                try {
                    val sendIntent = Intent().apply {
                        action = Intent.ACTION_SEND
                        putExtra(Intent.EXTRA_TEXT, text)
                        type = "text/plain"
                    }
                    val shareIntent = Intent.createChooser(sendIntent, title)
                    startActivity(shareIntent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SHARE_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Production Native Channel: Version, APK Installer, Export Audio, Audio Sharing
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> {
                    try {
                        val pInfo = packageManager.getPackageInfo(packageName, 0)
                        result.success(pInfo.versionName)
                    } catch (e: Exception) {
                        result.success("3.3.0")
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    try {
                        val file = File(filePath)
                        if (file.exists()) {
                            val uri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.error("FILE_NOT_FOUND", "APK file not found at $filePath", null)
                        }
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.message, null)
                    }
                }
                "exportAudio" -> {
                    val srcPath = call.argument<String>("srcPath") ?: ""
                    val fileName = call.argument<String>("fileName") ?: "song.m4a"
                    try {
                        val srcFile = File(srcPath)
                        if (srcFile.exists()) {
                            val musicDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
                            if (!musicDir.exists()) musicDir.mkdirs()
                            val destFile = File(musicDir, fileName)
                            srcFile.copyTo(destFile, overwrite = true)
                            // Notify MediaScanner
                            val scanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE).apply {
                                data = Uri.fromFile(destFile)
                            }
                            sendBroadcast(scanIntent)
                            result.success(destFile.absolutePath)
                        } else {
                            result.error("SRC_NOT_FOUND", "Source audio file does not exist", null)
                        }
                    } catch (e: Exception) {
                        result.error("EXPORT_ERROR", e.message, null)
                    }
                }
                "shareAudio" -> {
                    val srcPath = call.argument<String>("srcPath") ?: ""
                    val title = call.argument<String>("title") ?: "Share Song"
                    try {
                        val file = File(srcPath)
                        if (file.exists()) {
                            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "audio/*"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(intent, title))
                            result.success(true)
                        } else {
                            result.error("FILE_NOT_FOUND", "Audio file not found", null)
                        }
                    } catch (e: Exception) {
                        result.error("SHARE_AUDIO_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
