package com.abhishekpal.abhisuno

import android.app.PictureInPictureParams
import android.util.Rational

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.MediaStore
import android.provider.Settings
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentValues
import androidx.core.app.NotificationCompat
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity: AudioServiceActivity() {
    private val SHARE_CHANNEL = "com.abhishekpal.abhisuno/share"
    private val NATIVE_CHANNEL = "com.abhishekpal.abhisuno/native"
    private val PICK_IMAGE_REQ = 2001
    private var imagePickCallback: MethodChannel.Result? = null

    private var initialSharedText: String? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleSendIntent(intent)
    }

    private fun handleSendIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type?.startsWith("text/") == true) {
            initialSharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        try {
            // Stop background audio playback when app is swiped away from Recents
            val stopIntent = Intent(this, com.ryanheise.audioservice.AudioService::class.java).apply {
                action = "com.ryanheise.audioservice.action.STOP"
            }
            startService(stopIntent)
        } catch (e: Exception) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handleSendIntent(intent)

        // Legacy Share Channel
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
                    startActivity(Intent.createChooser(sendIntent, title))
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SHARE_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Production Native Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                                "enterPip" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(16, 9))
                                .build()
                            val entered = enterPictureInPictureMode(params)
                            result.success(entered)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("PIP_ERROR", e.message, null)
                    }
                }
                "getAppVersion" -> {
                    try {
                        val pInfo = packageManager.getPackageInfo(packageName, 0)
                        result.success(pInfo.versionName)
                    } catch (e: Exception) {
                        result.success("4.1.0")
                    }

                }
                "getInitialSharedText" -> {
                    val text = initialSharedText
                    initialSharedText = null
                    result.success(text)
                }
                "getStorageInfo" -> {
                    try {
                        val dataPath = Environment.getDataDirectory().path
                        val stat = StatFs(dataPath)
                        val blockSize = stat.blockSizeLong
                        val totalBlocks = stat.blockCountLong
                        val availBlocks = stat.availableBlocksLong
                        val totalBytes = totalBlocks * blockSize
                        val freeBytes = availBlocks * blockSize
                        val map = HashMap<String, Long>()
                        map["totalBytes"] = totalBytes
                        map["freeBytes"] = freeBytes
                        result.success(map)
                    } catch (e: Exception) {
                        result.error("STORAGE_ERROR", e.message, null)
                    }
                }
                "pickProfileImage" -> {
                    try {
                        imagePickCallback = result
                        val pickIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "image/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(Intent.createChooser(pickIntent, "Select Profile Picture"), PICK_IMAGE_REQ)
                    } catch (e: Exception) {
                        result.error("PICK_ERROR", e.message, null)
                    }
                }
                "openInstallSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    try {
                        val file = File(filePath)
                        if (file.exists()) {
                            val pInfo = packageManager.getPackageArchiveInfo(filePath, 0)
                            if (pInfo != null && pInfo.packageName != packageName) {
                                result.error("SECURITY_VIOLATION", "APK package name does not match $packageName", null)
                                return@setMethodCallHandler
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                if (!packageManager.canRequestPackageInstalls()) {
                                    val settingsIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                        data = Uri.parse("package:$packageName")
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(settingsIntent)
                                }
                            }
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
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val values = ContentValues().apply {
                                    put(MediaStore.Audio.Media.DISPLAY_NAME, fileName)
                                    put(MediaStore.Audio.Media.MIME_TYPE, "audio/mp4")
                                    put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_MUSIC + "/AbhiSuno")
                                    put(MediaStore.Audio.Media.IS_PENDING, 1)
                                }
                                val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
                                if (uri != null) {
                                    contentResolver.openOutputStream(uri)?.use { out ->
                                        srcFile.inputStream().use { inp -> inp.copyTo(out) }
                                    }
                                    values.clear()
                                    values.put(MediaStore.Audio.Media.IS_PENDING, 0)
                                    contentResolver.update(uri, values, null, null)
                                    result.success(uri.toString())
                                    return@setMethodCallHandler
                                }
                            }
                            val musicDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
                            if (!musicDir.exists()) musicDir.mkdirs()
                            val destFile = File(musicDir, fileName)
                            srcFile.copyTo(destFile, overwrite = true)
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
                "updateDownloadNotification" -> {
                    val title = call.argument<String>("title") ?: "Song"
                    val progress = call.argument<Double>("progress") ?: 0.0
                    val isDone = call.argument<Boolean>("isDone") ?: false
                    showDownloadNotification(title, (progress * 100).toInt(), isDone)
                    result.success(true)
                }
                "dismissDownloadNotification" -> {
                    val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                    notificationManager.cancel(1099)
                    result.success(true)
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_IMAGE_REQ) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                try {
                    val uri = data.data!!
                    val inputStream = contentResolver.openInputStream(uri)
                    val profileFile = File(filesDir, "user_profile_avatar.png")
                    val outputStream = FileOutputStream(profileFile)
                    inputStream?.copyTo(outputStream)
                    inputStream?.close()
                    outputStream.close()
                    imagePickCallback?.success(profileFile.absolutePath)
                } catch (e: Exception) {
                    imagePickCallback?.error("COPY_FAIL", e.message, null)
                }
            } else {
                imagePickCallback?.success(null)
            }
            imagePickCallback = null
        }
    }
}
