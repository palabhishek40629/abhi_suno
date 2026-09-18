import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import 'music_service.dart';

class AbhiAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final MusicService _musicService = MusicService();

  SongModel? _currentSong;
  final List<SongModel> _playlist = [];
  int _currentIndex = -1;

  SongModel? get currentSong => _currentSong;
  List<SongModel> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  AudioPlayer get player => _player;

  // Stream for current playing song model
  final StreamController<SongModel?> _currentSongSubject = StreamController<SongModel?>.broadcast();
  Stream<SongModel?> get currentSongStream => _currentSongSubject.stream;

  // Stream for playlist changes
  final StreamController<List<SongModel>> _playlistSubject = StreamController<List<SongModel>>.broadcast();
  Stream<List<SongModel>> get playlistStream => _playlistSubject.stream;

  AbhiAudioHandler() {
    _init();
  }

  void _init() {
    // Broadcast playback state changes to Android System / Notification
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

    // Auto play next song when current finishes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    try {
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

      // Setup Android Lockscreen & Notification MediaItem
      final item = MediaItem(
        id: song.id,
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: song.duration > Duration.zero ? song.duration : null,
        artUri: song.thumbnailUrl.isNotEmpty ? Uri.tryParse(song.thumbnailUrl) : null,
      );
      mediaItem.add(item);

      // Determine audio source: 1. Local Sandboxed File OR 2. Instant Online Stream
      if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
        await _player.setAudioSource(AudioSource.file(song.localFilePath!));
      } else {
        // Resolve online stream url if missing or expired (raced + cached)
        String? audioUrl = song.streamUrl;
        if (audioUrl == null || audioUrl.isEmpty) {
          audioUrl = await _musicService.getAudioStreamUrl(song.id);
          song.streamUrl = audioUrl;
        }

        final streamHeaders = {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
          'Referer': 'https://www.youtube.com/',
        };

        if (audioUrl != null && audioUrl.isNotEmpty) {
          try {
            await _player.setAudioSource(
              AudioSource.uri(Uri.parse(audioUrl), headers: streamHeaders),
              preload: true,
            );
          } catch (initialErr) {
            // Automatic resilient fallback if primary link encountered 403 or network issue
            final fallbackUrl = await _musicService.getFallbackAudioStreamUrl(song.id);
            if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
              song.streamUrl = fallbackUrl;
              await _player.setAudioSource(
                AudioSource.uri(Uri.parse(fallbackUrl), headers: streamHeaders),
                preload: true,
              );
            } else {
              rethrow;
            }
          }
        } else {
          throw Exception('Unable to resolve audio stream for track: ' + song.title);
        }
      }

      await _player.play();

      // Preload next track URL in background for 0-latency skip
      if (_currentIndex >= 0 && _currentIndex + 1 < _playlist.length) {
        _musicService.preloadStreamUrl(_playlist[_currentIndex + 1].id);
      }
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: e.toString(),
      ));
    }
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

  // Audio Equalizer & Speed/Pitch controls
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
