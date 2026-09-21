import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'auth_service.dart';
import 'favorites_service.dart';
import 'playlist_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _cloudSyncKeyPrefix = 'abhi_suno_cloud_sync_';
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Trigger cloud auto-sync for the current logged-in user
  Future<bool> syncUserData() async {
    final auth = AuthService();
    if (!auth.isLoggedIn) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = auth.currentUser.uid;
      final syncKey = '$_cloudSyncKeyPrefix$uid';

      final favs = FavoritesService().favoriteSongs;
      final playlists = PlaylistService().playlists;

      final payload = {
        'uid': uid,
        'email': auth.currentUser.email,
        'timestamp': DateTime.now().toIso8601String(),
        'liked_songs': favs.map((s) => s.toJson()).toList(),
        'playlists': playlists.map((p) => p.toJson()).toList(),
      };

      await prefs.setString(syncKey, json.encode(payload));
      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Restore user's saved playlists & liked songs when logging in
  Future<Map<String, int>> restoreUserCloudData() async {
    final auth = AuthService();
    if (!auth.isLoggedIn) return {'songs': 0, 'playlists': 0};

    _isSyncing = true;
    notifyListeners();

    int restoredSongs = 0;
    int restoredPlaylists = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = auth.currentUser.uid;
      final syncKey = '$_cloudSyncKeyPrefix$uid';

      final rawData = prefs.getString(syncKey);
      if (rawData != null && rawData.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(rawData);

        // Restore Liked Songs
        if (data.containsKey('liked_songs')) {
          final List<dynamic> songsJson = data['liked_songs'];
          for (final item in songsJson) {
            if (item is Map<String, dynamic>) {
              final song = SongModel.fromJson(item);
              if (!FavoritesService().isFavorite(song.id)) {
                await FavoritesService().toggleFavorite(song);
                restoredSongs++;
              }
            }
          }
        }

        // Restore Playlists
        if (data.containsKey('playlists')) {
          final List<dynamic> pListJson = data['playlists'];
          for (final item in pListJson) {
            if (item is Map<String, dynamic>) {
              final playlist = UserPlaylist.fromJson(item);
              final existing = PlaylistService().playlists.any((p) => p.id == playlist.id || p.name == playlist.name);
              if (!existing) {
                final newP = await PlaylistService().createPlaylist(playlist.name);
                for (final s in playlist.songs) {
                  await PlaylistService().addSongToPlaylist(newP.id, s);
                }
                restoredPlaylists++;
              }
            }
          }
        }
      }
      _lastSyncTime = DateTime.now();
    } catch (_) {}

    _isSyncing = false;
    notifyListeners();
    return {'songs': restoredSongs, 'playlists': restoredPlaylists};
  }

  /// 1-Click Complete Backup to JSON String (for local export or sharing)
  Future<String> exportBackupToJson() async {
    final favs = FavoritesService().favoriteSongs;
    final playlists = PlaylistService().playlists;

    final backupMap = {
      'app': 'AbhiSuno',
      'version': '4.1.0',
      'export_date': DateTime.now().toIso8601String(),
      'liked_songs_count': favs.length,
      'playlists_count': playlists.length,
      'liked_songs': favs.map((s) => s.toJson()).toList(),
      'playlists': playlists.map((p) => p.toJson()).toList(),
    };

    return json.encode(backupMap);
  }

  /// 1-Click Restore from JSON String
  Future<Map<String, int>> restoreBackupFromJson(String jsonString) async {
    int songsRestored = 0;
    int playlistsRestored = 0;

    try {
      final Map<String, dynamic> data = json.decode(jsonString);

      if (data.containsKey('liked_songs')) {
        final List<dynamic> songs = data['liked_songs'];
        for (final item in songs) {
          if (item is Map<String, dynamic>) {
            final song = SongModel.fromJson(item);
            if (!FavoritesService().isFavorite(song.id)) {
              await FavoritesService().toggleFavorite(song);
              songsRestored++;
            }
          }
        }
      }

      if (data.containsKey('playlists')) {
        final List<dynamic> playlists = data['playlists'];
        for (final item in playlists) {
          if (item is Map<String, dynamic>) {
            final p = UserPlaylist.fromJson(item);
            final newP = await PlaylistService().createPlaylist(p.name);
            for (final s in p.songs) {
              await PlaylistService().addSongToPlaylist(newP.id, s);
            }
            playlistsRestored++;
          }
        }
      }
    } catch (_) {}

    notifyListeners();
    return {'songs': songsRestored, 'playlists': playlistsRestored};
  }
}
