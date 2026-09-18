import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class UserPlaylist {
  final String id;
  final String name;
  final List<SongModel> songs;

  UserPlaylist({required this.id, required this.name, required this.songs});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songs': songs.map((s) => s.toJson()).toList(),
      };

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    return UserPlaylist(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'My Playlist',
      songs: (json['songs'] as List<dynamic>? ?? [])
          .map((item) => SongModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlaylistService extends ChangeNotifier {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal() {
    _loadPlaylists();
  }

  static const String _storageKey = 'abhi_suno_custom_playlists';
  List<UserPlaylist> _playlists = [];
  List<UserPlaylist> get playlists => List.unmodifiable(_playlists);

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(data);
        _playlists = jsonList.map((item) => UserPlaylist.fromJson(item as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(_playlists.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> createPlaylist(String name) async {
    final cleanName = name.trim().isEmpty ? 'New Playlist' : name.trim();
    final newP = UserPlaylist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanName,
      songs: [],
    );
    _playlists.insert(0, newP);
    await _savePlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      if (!_playlists[index].songs.any((s) => s.id == song.id)) {
        _playlists[index].songs.add(song);
        await _savePlaylists();
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index].songs.removeWhere((s) => s.id == songId);
      await _savePlaylists();
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylists();
  }
}
