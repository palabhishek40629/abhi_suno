import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
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
        final url = await _audioRepo.resolveAudioStreamUrl(nextSong.id, quality: '320kbps');
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
      // 1. Non-blocking pause/stop so UI thread never freezes
      _player.pause();

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
        artUri: song.thumbnailUrl.isNotEmpty ? Uri.tryParse(song.thumbnailUrl) : null,
      );
      mediaItem.add(item);

      // 3. Resolve audio source
      AudioSource? source;
      if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
        source = AudioSource.file(song.localFilePath!);
      } else {
        final cachedFile = await _cacheManager.getCachedSongFile(song.id);
        if (cachedFile != null && await cachedFile.exists() && await cachedFile.length() > 500000) {
          source = AudioSource.file(cachedFile.path);
        } else {
          String? audioUrl = song.streamUrl;
          if (audioUrl == null || audioUrl.isEmpty) {
            audioUrl = await _audioRepo.resolveAudioStreamUrl(song.id, quality: '320kbps');
            if (audioUrl == null || audioUrl.isEmpty) {
              try {
                final cleanQ = '${song.title} ${song.artist}'.replaceAll(RegExp(r'\(.*?\)'), '').trim();
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
            final streamHeaders = {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
              'Accept': '*/*',
              'Connection': 'keep-alive',
            };
            source = AudioSource.uri(Uri.parse(audioUrl), headers: streamHeaders);
          }
        }
      }

      // Discard stale audio operations if user tapped another track
      if (gen != _playGeneration) return;

      if (source != null) {
        // 4. CRITICAL: Always start every track from 0:00! Never resume previous song's position!
        await _player.setAudioSource(source, initialPosition: Duration.zero);
        await _player.seek(Duration.zero);
        if (gen != _playGeneration) return;
        await _player.play();
      }
    } catch (_) {}
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
      if (_currentSong != null) _autoFetchMoreSongs(_currentSong!);
      return;
    }
    if (_playlist.length - _currentIndex <= 2 && _currentSong != null) {
      _autoFetchMoreSongs(_currentSong!);
    }
    int nextIdx = _currentIndex + 1;
    if (nextIdx >= _playlist.length) nextIdx = 0;
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

  Future<void> _autoFetchMoreSongs(SongModel baseSong) async {
    try {
      final cleanQ = '${baseSong.title} ${baseSong.artist}'.replaceAll(RegExp(r'\(.*?\)'), '').trim();
      final more = await JioSaavnAdapter().searchSongs(cleanQ, limit: 10);
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
    } catch (_) {}
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
}

