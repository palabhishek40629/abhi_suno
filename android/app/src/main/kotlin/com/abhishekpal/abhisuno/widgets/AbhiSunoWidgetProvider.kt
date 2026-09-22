package com.abhishekpal.abhisuno.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.view.KeyEvent
import android.widget.RemoteViews
import com.abhishekpal.abhisuno.MainActivity
import com.abhishekpal.abhisuno.R
import java.io.File

abstract class BaseMusicWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_PLAY_PAUSE = "com.abhishekpal.abhisuno.ACTION_PLAY_PAUSE"
        const val ACTION_NEXT = "com.abhishekpal.abhisuno.ACTION_NEXT"
        const val ACTION_PREV = "com.abhishekpal.abhisuno.ACTION_PREV"
        const val ACTION_LIKE = "com.abhishekpal.abhisuno.ACTION_LIKE"
        const val ACTION_DOWNLOAD = "com.abhishekpal.abhisuno.ACTION_DOWNLOAD"

        var cachedTitle: String = "Abhi Suno"
        var cachedArtist: String = "Your Music, Your Way"
        var cachedLyricsLine: String = "संगीत के बोल यहाँ दिखाई देंगे..."
        var cachedIsPlaying: Boolean = false
        var cachedArtPath: String? = null

        fun updateAllWidgets(
            context: Context,
            title: String?,
            artist: String?,
            isPlaying: Boolean?,
            lyricsLine: String?,
            artPath: String?
        ) {
            if (!title.isNullOrEmpty()) cachedTitle = title
            if (!artist.isNullOrEmpty()) cachedArtist = artist
            if (!lyricsLine.isNullOrEmpty()) cachedLyricsLine = lyricsLine
            if (isPlaying != null) cachedIsPlaying = isPlaying
            if (!artPath.isNullOrEmpty()) cachedArtPath = artPath

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val providers = arrayOf(
                RadiantStudioWidgetProvider::class.java,
                ClassicPlayerWidgetProvider::class.java,
                RetroVinylWidgetProvider::class.java,
                MinimalPillWidgetProvider::class.java,
                KaraokeLyricsWidgetProvider::class.java,
                MusicHubWidgetProvider::class.java
            )

            for (providerClass in providers) {
                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, providerClass))
                if (ids.isNotEmpty()) {
                    val intent = Intent(context, providerClass).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    }
                    context.sendBroadcast(intent)
                }
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return

        when (action) {
            ACTION_PLAY_PAUSE -> {
                sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            }
            ACTION_NEXT -> {
                sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_NEXT)
            }
            ACTION_PREV -> {
                sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            }
            ACTION_LIKE, ACTION_DOWNLOAD -> {
                // Forward action to MainActivity/Flutter if open or launch intent
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    this.action = action
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                }
                context.startActivity(launchIntent)
            }
        }
    }

    private fun sendMediaKeyEvent(context: Context, keyCode: Int) {
        try {
            val downIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                setPackage(context.packageName)
                putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
            }
            context.sendBroadcast(downIntent)

            val upIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                setPackage(context.packageName)
                putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_UP, keyCode))
            }
            context.sendBroadcast(upIntent)
        } catch (e: Exception) {}
    }

    protected fun getPendingIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, javaClass).apply {
            this.action = action
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }

    protected fun getAppOpenIntent(context: Context, extraTab: String? = null, requestCode: Int = 100): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            if (extraTab != null) {
                putExtra("launch_tab", extraTab)
            }
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }

    protected fun loadArtBitmap(): Bitmap? {
        val path = cachedArtPath ?: return null
        return try {
            val file = File(path)
            if (file.exists()) BitmapFactory.decodeFile(file.absolutePath) else null
        } catch (e: Exception) {
            null
        }
    }
}

// 1. Radiant Studio Widget (4x2)
class RadiantStudioWidgetProvider : BaseMusicWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_radiant_studio)

            views.setTextViewText(R.id.widget_title, cachedTitle)
            views.setTextViewText(R.id.widget_artist, cachedArtist)

            val playIcon = if (cachedIsPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            views.setImageViewResource(R.id.btn_play_pause, playIcon)

            val artBmp = loadArtBitmap()
            if (artBmp != null) {
                views.setImageViewBitmap(R.id.widget_album_art, artBmp)
            } else {
                views.setImageViewResource(R.id.widget_album_art, R.mipmap.ic_launcher)
            }

            views.setOnClickPendingIntent(R.id.widget_studio_root, getAppOpenIntent(context, requestCode = 101))
            views.setOnClickPendingIntent(R.id.btn_play_pause, getPendingIntent(context, ACTION_PLAY_PAUSE, 201))
            views.setOnClickPendingIntent(R.id.btn_prev, getPendingIntent(context, ACTION_PREV, 202))
            views.setOnClickPendingIntent(R.id.btn_next, getPendingIntent(context, ACTION_NEXT, 203))
            views.setOnClickPendingIntent(R.id.btn_like, getPendingIntent(context, ACTION_LIKE, 204))
            views.setOnClickPendingIntent(R.id.btn_download, getPendingIntent(context, ACTION_DOWNLOAD, 205))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// 2. Classic Player Widget (4x1)
class ClassicPlayerWidgetProvider : BaseMusicWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_classic_player)

            views.setTextViewText(R.id.widget_title, cachedTitle)
            views.setTextViewText(R.id.widget_artist, cachedArtist)

            val playIcon = if (cachedIsPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            views.setImageViewResource(R.id.btn_play_pause, playIcon)

            val artBmp = loadArtBitmap()
            if (artBmp != null) {
                views.setImageViewBitmap(R.id.widget_album_art, artBmp)
            } else {
                views.setImageViewResource(R.id.widget_album_art, R.mipmap.ic_launcher)
            }

            views.setOnClickPendingIntent(R.id.widget_classic_root, getAppOpenIntent(context, requestCode = 102))
            views.setOnClickPendingIntent(R.id.btn_play_pause, getPendingIntent(context, ACTION_PLAY_PAUSE, 211))
            views.setOnClickPendingIntent(R.id.btn_prev, getPendingIntent(context, ACTION_PREV, 212))
            views.setOnClickPendingIntent(R.id.btn_next, getPendingIntent(context, ACTION_NEXT, 213))
            views.setOnClickPendingIntent(R.id.btn_like, getPendingIntent(context, ACTION_LIKE, 214))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// 3. Retro Vinyl Widget (3x3)
class RetroVinylWidgetProvider : BaseMusicWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_retro_vinyl)

            views.setTextViewText(R.id.widget_title, cachedTitle)
            views.setTextViewText(R.id.widget_artist, cachedArtist)

            val playIcon = if (cachedIsPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            views.setImageViewResource(R.id.btn_play_pause, playIcon)

            val artBmp = loadArtBitmap()
            if (artBmp != null) {
                views.setImageViewBitmap(R.id.widget_album_art, artBmp)
            } else {
                views.setImageViewResource(R.id.widget_album_art, R.mipmap.ic_launcher)
            }

            views.setOnClickPendingIntent(R.id.widget_vinyl_root, getAppOpenIntent(context, requestCode = 103))
            views.setOnClickPendingIntent(R.id.btn_play_pause, getPendingIntent(context, ACTION_PLAY_PAUSE, 221))
            views.setOnClickPendingIntent(R.id.btn_prev, getPendingIntent(context, ACTION_PREV, 222))
            views.setOnClickPendingIntent(R.id.btn_next, getPendingIntent(context, ACTION_NEXT, 223))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// 4. Minimalist Pill Widget (2x1)
class MinimalPillWidgetProvider : BaseMusicWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_minimal_pill)

            views.setTextViewText(R.id.widget_title, cachedTitle)
            views.setTextViewText(R.id.widget_artist, cachedArtist)

            val playIcon = if (cachedIsPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            views.setImageViewResource(R.id.btn_play_pause, playIcon)

            val artBmp = loadArtBitmap()
            if (artBmp != null) {
                views.setImageViewBitmap(R.id.widget_album_art, artBmp)
            } else {
                views.setImageViewResource(R.id.widget_album_art, R.mipmap.ic_launcher)
            }

            views.setOnClickPendingIntent(R.id.widget_pill_root, getAppOpenIntent(context, requestCode = 104))
            views.setOnClickPendingIntent(R.id.btn_play_pause, getPendingIntent(context, ACTION_PLAY_PAUSE, 231))
            views.setOnClickPendingIntent(R.id.btn_next, getPendingIntent(context, ACTION_NEXT, 232))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// 5. Live Karaoke Lyrics Widget (4x2)
class KaraokeLyricsWidgetProvider : BaseMusicWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_karaoke_lyrics)

            views.setTextViewText(R.id.widget_title, cachedTitle)
            views.setTextViewText(R.id.widget_artist, cachedArtist)
            views.setTextViewText(R.id.widget_lyrics_line, cachedLyricsLine)

            val playIcon = if (cachedIsPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            views.setImageViewResource(R.id.btn_play_pause, playIcon)

            val artBmp = loadArtBitmap()
            if (artBmp != null) {
                views.setImageViewBitmap(R.id.widget_album_art, artBmp)
            } else {
                views.setImageViewResource(R.id.widget_album_art, R.mipmap.ic_launcher)
            }

            views.setOnClickPendingIntent(R.id.widget_lyrics_root, getAppOpenIntent(context, requestCode = 105))
            views.setOnClickPendingIntent(R.id.btn_play_pause, getPendingIntent(context, ACTION_PLAY_PAUSE, 241))
            views.setOnClickPendingIntent(R.id.btn_next, getPendingIntent(context, ACTION_NEXT, 242))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// 6. Music Hub Widget (4x2)
class MusicHubWidgetProvider : BaseMusicWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_music_hub)

            views.setTextViewText(R.id.widget_title, cachedTitle)
            views.setTextViewText(R.id.widget_artist, cachedArtist)

            val playIcon = if (cachedIsPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            views.setImageViewResource(R.id.btn_play_pause, playIcon)

            val artBmp = loadArtBitmap()
            if (artBmp != null) {
                views.setImageViewBitmap(R.id.widget_album_art, artBmp)
            } else {
                views.setImageViewResource(R.id.widget_album_art, R.mipmap.ic_launcher)
            }

            views.setOnClickPendingIntent(R.id.widget_hub_root, getAppOpenIntent(context, requestCode = 106))
            views.setOnClickPendingIntent(R.id.btn_play_pause, getPendingIntent(context, ACTION_PLAY_PAUSE, 251))
            views.setOnClickPendingIntent(R.id.btn_next, getPendingIntent(context, ACTION_NEXT, 252))

            // 1-Tap Hub Quick Launch Shortcuts
            views.setOnClickPendingIntent(R.id.btn_hub_downloads, getAppOpenIntent(context, "downloads", 301))
            views.setOnClickPendingIntent(R.id.btn_hub_favorites, getAppOpenIntent(context, "favorites", 302))
            views.setOnClickPendingIntent(R.id.btn_hub_explore, getAppOpenIntent(context, "explore", 303))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
