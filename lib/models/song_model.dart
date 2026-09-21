class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String thumbnailUrl;
  String? streamUrl;
  String? permaUrl;
  String? localFilePath;
  String? localThumbnailPath;
  String? localLyricsPath;
  String? lyrics;
  bool isDownloaded;
  bool isFavorite;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album = 'Abhi Suno Music',
    required this.duration,
    required this.thumbnailUrl,
    this.streamUrl,
    this.permaUrl,
    this.localFilePath,
    this.localThumbnailPath,
    this.localLyricsPath,
    this.lyrics,
    this.isDownloaded = false,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration.inMilliseconds,
      'thumbnailUrl': thumbnailUrl,
      'streamUrl': streamUrl,
      'permaUrl': permaUrl,
      'localFilePath': localFilePath,
      'localThumbnailPath': localThumbnailPath,
      'localLyricsPath': localLyricsPath,
      'lyrics': lyrics,
      'isDownloaded': isDownloaded,
      'isFavorite': isFavorite,
    };
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String? ?? 'Abhi Suno Music',
      duration: Duration(milliseconds: int.tryParse(json['durationMs']?.toString() ?? '0') ?? 0),
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      streamUrl: json['streamUrl'] as String?,
      permaUrl: json['permaUrl'] as String?,
      localFilePath: json['localFilePath'] as String?,
      localThumbnailPath: json['localThumbnailPath'] as String?,
      localLyricsPath: json['localLyricsPath'] as String?,
      lyrics: json['lyrics'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? thumbnailUrl,
    String? streamUrl,
    String? permaUrl,
    String? localFilePath,
    String? localThumbnailPath,
    String? localLyricsPath,
    String? lyrics,
    bool? isDownloaded,
    bool? isFavorite,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      permaUrl: permaUrl ?? this.permaUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      localLyricsPath: localLyricsPath ?? this.localLyricsPath,
      lyrics: lyrics ?? this.lyrics,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
