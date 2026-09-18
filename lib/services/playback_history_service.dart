import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class PlaybackHistoryService extends ChangeNotifier {
  static final PlaybackHistoryService _instance = PlaybackHistoryService._internal();
  factory PlaybackHistoryService() => _instance;
  PlaybackHistoryService._internal() {
    _loadHistory();
  }

  static const String _storageKey = 'abhi_suno_playback_history';
  static const String _lastSongKey = 'abhi_suno_last_played_song';
  static const String _lastPosKey = 'abhi_suno_last_played_position_ms';

  SongModel? _lastPlayedSong;
  Duration _lastPosition = Duration.zero;
  final List<SongModel> _recentHistory = [];
  bool _isLoaded = false;

  SongModel? get lastPlayedSong => _lastPlayedSong;
  Duration get lastPosition => _lastPosition;
  List<SongModel> get recentHistory => List.unmodifiable(_recentHistory);
  bool get isLoaded => _isLoaded;

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastSongRaw = prefs.getString(_lastSongKey);
      if (lastSongRaw != null && lastSongRaw.isNotEmpty) {
        _lastPlayedSong = SongModel.fromJson(json.decode(lastSongRaw));
      }

      final posMs = prefs.getInt(_lastPosKey) ?? 0;
      _lastPosition = Duration(milliseconds: posMs);

      final historyRaw = prefs.getString(_storageKey);
      if (historyRaw != null && historyRaw.isNotEmpty) {
        final List<dynamic> list = json.decode(historyRaw);
        _recentHistory.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _recentHistory.add(SongModel.fromJson(item));
          }
        }
      }
    } catch (_) {}
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> recordSongPlay(SongModel song, {Duration? position}) async {
    _lastPlayedSong = song;
    if (position != null) {
      _lastPosition = position;
    }

    _recentHistory.removeWhere((s) => s.id == song.id);
    _recentHistory.insert(0, song);
    if (_recentHistory.length > 25) {
      _recentHistory.removeRange(25, _recentHistory.length);
    }

    notifyListeners();
    await _saveHistory();
  }

  Future<void> updatePosition(Duration position) async {
    _lastPosition = position;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastPosKey, position.inMilliseconds);
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastPlayedSong != null) {
        await prefs.setString(_lastSongKey, json.encode(_lastPlayedSong!.toJson()));
      }
      await prefs.setInt(_lastPosKey, _lastPosition.inMilliseconds);

      final historyData = json.encode(_recentHistory.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, historyData);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    _recentHistory.clear();
    _lastPlayedSong = null;
    _lastPosition = Duration.zero;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_lastSongKey);
      await prefs.remove(_lastPosKey);
    } catch (_) {}
  }
}
