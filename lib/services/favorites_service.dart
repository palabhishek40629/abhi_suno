import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

import 'sync_service.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal() {
    _loadFavorites();
  }

  static const String _storageKey = 'abhi_suno_favorite_songs';
  final List<SongModel> _favoriteSongs = [];
  final Set<String> _favoriteIds = {};
  bool _isLoaded = false;

  List<SongModel> get favoriteSongs => List.unmodifiable(_favoriteSongs);
  bool get isLoaded => _isLoaded;

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_storageKey);
      if (encoded != null && encoded.isNotEmpty) {
        final List<dynamic> list = json.decode(encoded);
        _favoriteSongs.clear();
        _favoriteIds.clear();

        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final song = SongModel.fromJson(item);
            song.isFavorite = true;
            _favoriteSongs.add(song);
            _favoriteIds.add(song.id);
          }
        }
      }
    } catch (_) {}
    _isLoaded = true;
    notifyListeners();
  }

  bool isFavorite(String songId) {
    return _favoriteIds.contains(songId);
  }

  Future<bool> toggleFavorite(SongModel song) async {
    final bool willBeFavorite = !_favoriteIds.contains(song.id);

    if (willBeFavorite) {
      _favoriteIds.add(song.id);
      song.isFavorite = true;
      _favoriteSongs.removeWhere((s) => s.id == song.id);
      _favoriteSongs.insert(0, song);
    } else {
      _favoriteIds.remove(song.id);
      song.isFavorite = false;
      _favoriteSongs.removeWhere((s) => s.id == song.id);
    }

    notifyListeners();
    await _saveToStorage();
    SyncService().syncUserData();
    return willBeFavorite;
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_favoriteSongs.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }
}
