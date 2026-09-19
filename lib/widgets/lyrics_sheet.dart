import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/theme_service.dart';

class LyricsSheet extends StatefulWidget {
  final SongModel song;

  const LyricsSheet({Key? key, required this.song}) : super(key: key);

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  final MusicService _musicService = MusicService();
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();

  String _lyrics = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    final rawLyrics = await _musicService.fetchLyrics(widget.song.title, widget.song.artist);
    // Clean LRC timestamps [00:12.34] for crystal-clear readability
    final cleanLyrics = rawLyrics
        .replaceAll(RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]'), '')
        .trim();

    if (mounted) {
      setState(() {
        _lyrics = cleanLyrics;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        const primaryCyan = Color(0xFF00E5FF);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xEB0A1329), // Deep midnight blue frosted glass
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: primaryCyan.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: primaryCyan.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: primaryCyan.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryCyan.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lyrics_rounded, color: primaryCyan, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: subtextColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(primaryCyan),
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _lyrics.isEmpty
                                  ? (_lang.isHindi ? 'गीत के बोल उपलब्ध नहीं हैं।' : 'Lyrics not available.')
                                  : _lyrics,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                height: 2.2,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
