import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import 'cache_manager.dart';
import 'audio_providers/unified_audio_repository.dart';

class AbhiAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final UnifiedAudioRepository _audioRepo = UnifiedAudioRepository();
  final CacheManager _cacheManager = CacheManager();

  SongModel? _currentSong;
  final List<SongModel> _playlist = [];
  int _currentIndex = -1;

  SongModel? get currentSong => _currentSong;
  List<SongModel> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  AudioPlayer get player => _player;

  final StreamController<SongModel?> _currentSongSubject = StreamController<SongModel?>.broadcast();
  Stream<SongModel?> get currentSongStream => _currentSongSubject.stream;

  final StreamController<List<SongModel>> _playlistSubject = StreamController<List<SongModel>>.broadcast();
  Stream<List<SongModel>> get playlistStream => _playlistSubject.stream;

  AbhiAudioHandler() {
    _init();
  }

  void _init() {
    _cacheManager.init();

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

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  // Playback Decision Flow
  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    try {
      final previousSong = _currentSong;
      if (previousSong != null && previousSong.id != song.id) {
        _cacheManager.demoteCurrentToRecent(previousSong.id);
      }

      if (queue != null && queue.isNotEmpty) {
        _playlist.clear();
        _playlist.addAll(queue);
        _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) {
          _playlist.insert(0, song);
          _currentIndex = 0;
        }
        _playlistSubject.add(List.unmodifiable(_playlist));
      }

      _currentSong = song;
      _currentSongSubject.add(_currentSong);

      final item = MediaItem(
        id: song.id,
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: song.duration > Duration.zero ? song.duration : null,
        artUri: song.thumbnailUrl.isNotEmpty ? Uri.tryParse(song.thumbnailUrl) : null,
      );
      mediaItem.add(item);

      // 1. Check PERMANENT local downloaded file
      if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
        await _player.setAudioSource(AudioSource.file(song.localFilePath!));
      } else {
        // 2. Check full cached file in local cache tiers
        final cachedFile = await _cacheManager.getCachedSongFile(song.id);
        if (cachedFile != null && await cachedFile.exists() && await cachedFile.length() > 500000) {
          await _player.setAudioSource(AudioSource.file(cachedFile.path));
        } else {
          // 3. Play direct high-speed Akamai CDN audio stream URL
          String? audioUrl = song.streamUrl;
          if (audioUrl == null || audioUrl.isEmpty) {
            audioUrl = await _audioRepo.resolveAudioStreamUrl(song.id, quality: '320kbps');
            song.streamUrl = audioUrl;
          }

          if (audioUrl != null && audioUrl.isNotEmpty) {
            final streamHeaders = {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            };

            await _player.setAudioSource(
              AudioSource.uri(Uri.parse(audioUrl), headers: streamHeaders),
              preload: true,
            );
          } else {
            throw Exception('Unable to resolve audio stream for track: ${song.title}');
          }
        }
      }

      await _player.play();

      // 4. Background Next-Song Stream Pre-resolution
      _triggerNextSongPrefetch();
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Pre-resolve upcoming song stream URL in background
  void _triggerNextSongPrefetch() {
    if (_currentIndex < 0 || _currentIndex + 1 >= _playlist.length) return;
    final nextSong = _playlist[_currentIndex + 1];

    Future.microtask(() async {
      try {
        if (nextSong.streamUrl != null && nextSong.streamUrl!.isNotEmpty) return;
        final resolved = await _audioRepo.resolveAudioStreamUrl(nextSong.id, quality: '320kbps');
        if (resolved != null && resolved.isNotEmpty) {
          nextSong.streamUrl = resolved;
        }
      } catch (_) {}
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;
    if (_currentIndex + 1 < _playlist.length) {
      _currentIndex++;
      await playSong(_playlist[_currentIndex]);
    } else if (_playlist.isNotEmpty) {
      _currentIndex = 0;
      await playSong(_playlist[_currentIndex]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;
    if (_currentIndex - 1 >= 0) {
      _currentIndex--;
      await playSong(_playlist[_currentIndex]);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.5, 2.0));
  }

  Future<void> setPitch(double pitch) async {
    await _player.setPitch(pitch.clamp(0.5, 2.0));
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _currentSongSubject.close();
    await _playlistSubject.close();
  }
}
