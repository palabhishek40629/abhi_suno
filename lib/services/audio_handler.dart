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
        }[_player.processingState]!,
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

      // Determine audio source: 1. Local Sandboxed File OR 2. Online Stream
      if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
        await _player.setAudioSource(AudioSource.file(song.localFilePath!));
      } else {
        // Resolve online stream url if missing or expired
        String? audioUrl = song.streamUrl;
        if (audioUrl == null || audioUrl.isEmpty) {
          audioUrl = await _musicService.getAudioStreamUrl(song.id);
          song.streamUrl = audioUrl;
        }

        if (audioUrl != null && audioUrl.isNotEmpty) {
          await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
        } else {
          throw Exception("Unable to resolve audio stream for track: ${song.title}");
        }
      }

      await _player.play();
    } catch (e) {
      // Graceful error recovery: don't crash, update state
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
      // Loop back to first song
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

  // Equalizer & Volume Boost controls
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
