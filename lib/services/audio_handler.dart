import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
export 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'cache_manager.dart';
import 'playback_history_service.dart';
import 'audio_providers/unified_audio_repository.dart';
import 'audio_providers/jiosaavn_adapter.dart';
import 'party_room_service.dart';

class AbhiAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final UnifiedAudioRepository _audioRepo = UnifiedAudioRepository();
  final CacheManager _cacheManager = CacheManager();
  final PlaybackHistoryService _historyService = PlaybackHistoryService();

  SongModel? _currentSong;
  final List<SongModel> _playlist = [];
  final List<SongModel> _originalPlaylist = [];
  int _currentIndex = -1;

  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _crossfadeEnabled = true;
  int _crossfadeSeconds = 4;
  bool _loudnessNormalizer = true;
  bool _hasPreloadedNext = false;

  SongModel? get currentSong => _currentSong;
  List<SongModel> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  AudioPlayer get player => _player;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get crossfadeEnabled => _crossfadeEnabled;
  bool get loudnessNormalizer => _loudnessNormalizer;
  bool get isPlaying => playbackState.value.playing;

  final StreamController<SongModel?> _currentSongSubject = StreamController<SongModel?>.broadcast();
  Stream<SongModel?> get currentSongStream => _currentSongSubject.stream;

  final StreamController<List<SongModel>> _playlistSubject = StreamController<List<SongModel>>.broadcast();
  Stream<List<SongModel>> get playlistStream => _playlistSubject.stream;

  final StreamController<bool> _shuffleSubject = StreamController<bool>.broadcast();
  Stream<bool> get shuffleStream => _shuffleSubject.stream;

  final StreamController<bool> _repeatSubject = StreamController<bool>.broadcast();
  Stream<bool> get repeatStream => _repeatSubject.stream;

  AbhiAudioHandler() {
    _init();
  }

  void _init() {
    _cacheManager.init();
    _loadPreferences();

    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState] ?? AudioProcessingState.idle,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex >= 0 ? _currentIndex : null,
      ));
    });

    _player.positionStream.listen((pos) {
      if (_currentSong != null && pos.inSeconds > 0 && pos.inSeconds % 5 == 0) {
        _historyService.updatePosition(pos);
      }

      final dur = _player.duration;
      if (dur != null && dur > Duration.zero) {
        // 1. Smart Pre-loading: when song reaches 70%, pre-resolve next track stream URL
        final progressRatio = pos.inMilliseconds / dur.inMilliseconds;
        if (progressRatio >= 0.70 && !_hasPreloadedNext) {
          _hasPreloadedNext = true;
          _preloadNextSong();
        }

        // 2. Seamless DJ Crossfade: gentle fade-out in the last 3-5 seconds
        if (_crossfadeEnabled && pos >= dur - Duration(seconds: _crossfadeSeconds)) {
          final remainingMs = (dur - pos).inMilliseconds;
          final totalCrossMs = _crossfadeSeconds * 1000;
          final fadeVol = (remainingMs / totalCrossMs).clamp(0.05, 1.0);
          _player.setVolume(fadeVol);
        }
      }
    });

    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final procState = const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[state.processingState] ?? AudioProcessingState.idle;

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        processingState: procState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex >= 0 ? _currentIndex : null,
      ));

      if (state.processingState == ProcessingState.completed) {
        if (_isRepeat) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          skipToNext();
        }
      }
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _crossfadeEnabled = prefs.getBool('audio_crossfade_enabled') ?? true;
      _crossfadeSeconds = prefs.getInt('audio_crossfade_seconds') ?? 4;
      _loudnessNormalizer = prefs.getBool('audio_loudness_normalizer') ?? true;
    } catch (_) {}
  }

  Future<void> setCrossfade(bool enabled, int seconds) async {
    _crossfadeEnabled = enabled;
    _crossfadeSeconds = seconds.clamp(2, 8);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_crossfade_enabled', enabled);
    await prefs.setInt('audio_crossfade_seconds', _crossfadeSeconds);
  }

  Future<void> setLoudnessNormalizer(bool enabled) async {
    _loudnessNormalizer = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_loudness_normalizer', enabled);
    _applyVolumeNormalization(_currentSong);
  }

  void _applyVolumeNormalization(SongModel? song) {
    if (!_loudnessNormalizer || song == null) {
      _player.setVolume(1.0);
      return;
    }
    // Vintage/Retro tracks (70s-90s) are mastered quieter, boost to 1.15
    final lowerTitle = '${song.title} ${song.artist} ${song.album}'.toLowerCase();
    if (lowerTitle.contains('kishore') ||
        lowerTitle.contains('lata') ||
        lowerTitle.contains('rafi') ||
        lowerTitle.contains('mukesh') ||
        lowerTitle.contains('90s') ||
        lowerTitle.contains('retro')) {
      _player.setVolume(1.15);
    } else if (lowerTitle.contains('remix') || lowerTitle.contains('bass') || lowerTitle.contains('dj')) {
      _player.setVolume(0.92);
    } else {
      _player.setVolume(1.0);
    }
  }

  Future<void> _preloadNextSong() async {
    if (_playlist.isEmpty || _currentIndex < 0) return;
    final nextIndex = (_currentIndex + 1) % _playlist.length;
    final nextSong = _playlist[nextIndex];
    if (nextSong.streamUrl == null || nextSong.streamUrl!.isEmpty) {
      try {
        final query = '${nextSong.title} ${nextSong.artist}';
        final url = await _audioRepo.resolveAudioStreamUrl(nextSong.id, query: query, quality: '320kbps');
        if (url != null) {
          nextSong.streamUrl = url;
          _audioRepo.cacheStreamUrl(nextSong.id, url);
        }
      } catch (_) {}
    }
  }

  // ============================================================================
  // PLAYBACK DECISION FLOW (Immediately Stops Current Track First!)
  // ============================================================================
  int _playGeneration = 0;

  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    final gen = ++_playGeneration;
    try {
      // 1. Immediately stop previous track audio synchronously
      _player.stop();

      _hasPreloadedNext = false;
      _applyVolumeNormalization(song);

      final previousSong = _currentSong;
      if (previousSong != null && previousSong.id != song.id) {
        _cacheManager.demoteCurrentToRecent(previousSong.id);
      }

      if (queue != null && queue.isNotEmpty) {
        _originalPlaylist.clear();
        _originalPlaylist.addAll(queue);

        _playlist.clear();
        _playlist.addAll(queue);

        if (_isShuffle) {
          _applyShuffleQueue(song);
        } else {
          _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
          if (_currentIndex == -1) {
            _playlist.insert(0, song);
            _currentIndex = 0;
          }
        }
        _playlistSubject.add(List.unmodifiable(_playlist));
      } else {
        final idx = _playlist.indexWhere((s) => s.id == song.id);
        if (idx != -1) {
          _currentIndex = idx;
        } else {
          _playlist.add(song);
          _originalPlaylist.add(song);
          _currentIndex = _playlist.length - 1;
          _playlistSubject.add(List.unmodifiable(_playlist));
          _autoFetchMoreSongs(song);
        }
      }

      // 2. IMMEDIATELY update current song & media item so UI switches in 0ms!
      _currentSong = song;
      _currentSongSubject.add(_currentSong);
      _historyService.recordSongPlay(song);
      _historyService.updatePosition(Duration.zero);
      PartyRoomService().onLocalSongChanged(song);

      final item = MediaItem(
        id: song.id,
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: song.duration > Duration.zero ? song.duration : null,
        artUri: (song.localThumbnailPath != null && File(song.localThumbnailPath!).existsSync())
            ? Uri.file(song.localThumbnailPath!)
            : (song.thumbnailUrl.isNotEmpty ? Uri.tryParse(song.thumbnailUrl) : null),
      );
      mediaItem.add(item);

      // 3. Resolve audio source
      AudioSource? source;
      if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
        source = AudioSource.file(song.localFilePath!);
      } else {
        final cachedFile = await _cacheManager.getCachedSongFile(song.id);
        if (cachedFile != null && await cachedFile.exists() && await cachedFile.length() > 10000) {
          source = AudioSource.file(cachedFile.path);
        } else {
          // Fast check: If offline and not cached or downloaded, avoid lengthy 12-second network timeout hang
          if (!ConnectivityService().isOnline) {
            playbackState.add(playbackState.value.copyWith(
              processingState: AudioProcessingState.idle,
              playing: false,
            ));
            return;
          }

          String? audioUrl = song.streamUrl;
          if (audioUrl == null || audioUrl.isEmpty) {
            final songQuery = '${song.title} ${song.artist}'.trim();
            audioUrl = await _audioRepo.resolveAudioStreamUrl(song.id, query: songQuery, quality: '320kbps');
            if (audioUrl == null || audioUrl.isEmpty) {
              try {
                final cleanQ = songQuery.replaceAll(RegExp(r'\(.*?\)'), '').trim();
                final matches = await JioSaavnAdapter().searchSongs(cleanQ, limit: 1);
                if (matches.isNotEmpty && matches.first.streamUrl != null && matches.first.streamUrl!.isNotEmpty) {
                  audioUrl = matches.first.streamUrl;
                  _audioRepo.cacheStreamUrl(song.id, audioUrl!);
                }
              } catch (_) {}
            }
            song.streamUrl = audioUrl;
          }

          if (audioUrl != null && audioUrl.isNotEmpty) {
            if (audioUrl.startsWith('http://')) {
              audioUrl = audioUrl.replaceFirst('http://', 'https://');
            }
            source = AudioSource.uri(Uri.parse(audioUrl));
          }
        }
      }

      // Discard stale audio operations if user tapped another track
      if (gen != _playGeneration) return;

      if (source != null) {
        try {
          // 4. CRITICAL: Always start every track from 0:00 without double-buffering latency!
          await _player.setAudioSource(source, initialPosition: Duration.zero);
          if (gen != _playGeneration) return;
          await _player.play();
        } catch (e) {
          // Automatic 160kbps & 96kbps stream fallback if 320kbps encounters network/CDN error
          bool fallbackSuccess = false;
          final currentUrl = song.streamUrl;
          if (currentUrl != null && currentUrl.contains('_320.mp4')) {
            try {
              final url160 = currentUrl.replaceAll('_320.mp4', '_160.mp4');
              song.streamUrl = url160;
              await _player.setAudioSource(AudioSource.uri(Uri.parse(url160)), initialPosition: Duration.zero);
              if (gen != _playGeneration) return;
              await _player.play();
              fallbackSuccess = true;
            } catch (_) {
              try {
                final url96 = currentUrl.replaceAll('_320.mp4', '_96.mp4');
                song.streamUrl = url96;
                await _player.setAudioSource(AudioSource.uri(Uri.parse(url96)), initialPosition: Duration.zero);
                if (gen != _playGeneration) return;
                await _player.play();
                fallbackSuccess = true;
              } catch (_) {}
            }
          }

          if (!fallbackSuccess) {
            // Fresh search match on JioSaavn as ultimate safety net
            try {
              final freshMatches = await JioSaavnAdapter().searchSongs('${song.title} ${song.artist}', limit: 2);
              if (freshMatches.isNotEmpty && freshMatches.first.streamUrl != null && freshMatches.first.streamUrl!.isNotEmpty) {
                final freshUrl = freshMatches.first.streamUrl!;
                song.streamUrl = freshUrl;
                _audioRepo.cacheStreamUrl(song.id, freshUrl);
                await _player.setAudioSource(AudioSource.uri(Uri.parse(freshUrl)), initialPosition: Duration.zero);
                if (gen != _playGeneration) return;
                await _player.play();
                fallbackSuccess = true;
              }
            } catch (_) {}
          }

          if (!fallbackSuccess) {
            // Gracefully reset processing state so UI is never frozen in infinite buffering
            playbackState.add(playbackState.value.copyWith(
              processingState: AudioProcessingState.idle,
              playing: false,
            ));
          }
        }
      } else {
        // CRITICAL FIX: If audio source could not be resolved, reset loading state immediately!
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.idle,
          playing: false,
        ));
      }
    } catch (_) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ));
    }
  }

  void _applyShuffleQueue(SongModel current) {
    _playlist.clear();
    final remaining = _originalPlaylist.where((s) => s.id != current.id).toList();
    final random = Random();
    for (int i = remaining.length - 1; i > 0; i--) {
      int n = random.nextInt(i + 1);
      final temp = remaining[i];
      remaining[i] = remaining[n];
      remaining[n] = temp;
    }
    _playlist.add(current);
    _playlist.addAll(remaining);
    _currentIndex = 0;
  }

  Future<void> toggleShuffle() async {
    _isShuffle = !_isShuffle;
    _shuffleSubject.add(_isShuffle);
    if (_currentSong != null) {
      if (_isShuffle) {
        _applyShuffleQueue(_currentSong!);
      } else {
        _playlist.clear();
        _playlist.addAll(_originalPlaylist);
        _currentIndex = _playlist.indexWhere((s) => s.id == _currentSong!.id);
      }
      _playlistSubject.add(List.unmodifiable(_playlist));
    }
  }

  Future<void> toggleRepeat() async {
    _isRepeat = !_isRepeat;
    _repeatSubject.add(_isRepeat);
  }

  @override
  Future<void> play() async {
    if (_currentSong == null && _playlist.isNotEmpty) {
      await playSong(_playlist.first);
      return;
    }
    if (_currentSong != null && (_player.audioSource == null || _player.processingState == ProcessingState.idle)) {
      await playSong(_currentSong!);
      return;
    }
    await _player.play();
    PartyRoomService().onLocalResume();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    PartyRoomService().onLocalPause();
  }

  @override
  Future<void> stop() async => await _player.stop();

  @override
  Future<void> seek(Duration position) async => await _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) {
      if (_currentSong != null) await _autoFetchMoreSongs(_currentSong!);
      if (_playlist.isEmpty) return;
    }

    // Auto-fetch more songs when near the end (<= 2 tracks left)
    if (_playlist.length - _currentIndex <= 2 && _currentSong != null) {
      await _autoFetchMoreSongs(_currentSong!);
    }

    int nextIdx = _currentIndex + 1;
    if (nextIdx >= _playlist.length) {
      // If we hit the end of the playlist, fetch fresh similar songs so playback never stops!
      if (_currentSong != null) {
        await _autoFetchMoreSongs(_currentSong!);
      }
      if (nextIdx >= _playlist.length) {
        nextIdx = 0; // Fallback loop if offline
      }
    }
    _currentIndex = nextIdx;
    await playSong(_playlist[_currentIndex]);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;
    if (_player.position.inSeconds > 4) {
      await seek(Duration.zero);
      return;
    }
    int prevIdx = _currentIndex - 1;
    if (prevIdx < 0) prevIdx = _playlist.length - 1;
    _currentIndex = prevIdx;
    await playSong(_playlist[_currentIndex]);
  }

  bool _isFetchingMore = false;

  Future<void> _autoFetchMoreSongs(SongModel baseSong) async {
    if (_isFetchingMore) return;
    _isFetchingMore = true;

    try {
      final primaryArtist = baseSong.artist
          .replaceAll(RegExp(r'(VEVO|Official|Topic|Music|Zee Music|T-Series)', caseSensitive: false), '')
          .split(',')
          .first
          .trim();

      // Query similar tracks based on primary artist and vibe
      List<SongModel> more = [];
      if (primaryArtist.isNotEmpty && primaryArtist.length > 2) {
        more = await JioSaavnAdapter().searchSongs('$primaryArtist Superhit Songs', limit: 12);
      }
      if (more.isEmpty) {
        final cleanTitle = baseSong.title.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
        more = await JioSaavnAdapter().searchSongs(cleanTitle, limit: 10);
      }

      if (more.isNotEmpty) {
        final existingIds = _playlist.map((s) => s.id).toSet();
        for (final m in more) {
          if (!existingIds.contains(m.id)) {
            _playlist.add(m);
            _originalPlaylist.add(m);
            existingIds.add(m.id);
          }
        }
        _playlistSubject.add(List.unmodifiable(_playlist));
      }
    } catch (_) {} finally {
      _isFetchingMore = false;
    }
  }

  Future<void> setVolume(double vol) async {
    await _player.setVolume(vol.clamp(0.0, 1.0));
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _player.setPitch(pitch);
    } catch (_) {}
  }

  Future<void> setEqualizerGain(double gain) async {
    try {
      await _player.setVolume(gain.clamp(0.0, 2.0));
    } catch (_) {}
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _playlist.length) return;
    if (newIndex < 0 || newIndex > _playlist.length) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, item);
    if (_currentSong != null) {
      final newCurrent = _playlist.indexWhere((s) => s.id == _currentSong!.id);
      if (newCurrent != -1) {
        _currentIndex = newCurrent;
      }
    }
    _playlistSubject.add(List.unmodifiable(_playlist));
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _playlist.length) return;
    if (_playlist.length <= 1) return;
    _playlist.removeAt(index);
    if (_currentSong != null) {
      final newCurrent = _playlist.indexWhere((s) => s.id == _currentSong!.id);
      if (newCurrent != -1) {
        _currentIndex = newCurrent;
      } else {
        _currentIndex = _currentIndex.clamp(0, _playlist.length - 1);
      }
    }
    _playlistSubject.add(List.unmodifiable(_playlist));
  }
}

