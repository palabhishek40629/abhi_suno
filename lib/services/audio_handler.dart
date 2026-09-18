import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
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

  // Playback Decision Flow (Requirement 21)
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
        // 2. Check Cache tiers (Promote prefetch or use cached file)
        await _cacheManager.promotePrefetchToCurrent(song.id);
        final cachedFile = await _cacheManager.getCachedSongFile(song.id);

        if (cachedFile != null && await cachedFile.exists() && await cachedFile.length() > 200000) {
          await _player.setAudioSource(AudioSource.file(cachedFile.path));
        } else {
          // 3. Resolve authorized stream URL
          String? audioUrl = song.streamUrl;
          if (audioUrl == null || audioUrl.isEmpty) {
            audioUrl = await _audioRepo.resolveAudioStreamUrl(song.id);
            song.streamUrl = audioUrl;
          }

          if (audioUrl != null && audioUrl.isNotEmpty) {
            final streamHeaders = {
              'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
              'Referer': 'https://www.youtube.com/',
            };

            await _player.setAudioSource(
              AudioSource.uri(Uri.parse(audioUrl), headers: streamHeaders),
              preload: true,
            );
          } else {
            throw Exception('Unable to resolve audio stream for track: ');
          }
        }
      }

      await _player.play();

      // 4. Background Next-Song Prefetch (~13 seconds) (Requirement 3)
      _triggerNextSongPrefetch();
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Prefetch first ~13 seconds (~350 KB) of upcoming track in background
  void _triggerNextSongPrefetch() {
    if (_currentIndex < 0 || _currentIndex + 1 >= _playlist.length) return;
    final nextSong = _playlist[_currentIndex + 1];

    Future.microtask(() async {
      try {
        final cached = await _cacheManager.getCachedSongFile(nextSong.id);
        if (cached != null && await cached.exists()) return;

        // Resolve stream url
        String? nextUrl = nextSong.streamUrl;
        if (nextUrl == null || nextUrl.isEmpty) {
          nextUrl = await _audioRepo.resolveAudioStreamUrl(nextSong.id);
          nextSong.streamUrl = nextUrl;
        }

        if (nextUrl == null || nextUrl.isEmpty) return;

        final prefetchDir = await _cacheManager.prefetchDir;
        final cleanId = nextSong.id.replaceAll(RegExp(r'[^\w]+'), '_');
        final targetFile = File('/.m4a');

        // Fetch initial ~350 KB with HTTP range request (~13 seconds)
        final res = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
            'Referer': 'https://www.youtube.com/',
            'Range': 'bytes=0-350000',
          },
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200 || res.statusCode == 206) {
          await targetFile.writeAsBytes(res.bodyBytes, flush: true);
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
