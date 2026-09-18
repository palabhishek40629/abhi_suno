import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../services/playlist_service.dart';
import '../services/language_service.dart';

class YouTubeLoginDialog extends StatefulWidget {
  const YouTubeLoginDialog({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const YouTubeLoginDialog(),
    );
  }

  @override
  State<YouTubeLoginDialog> createState() => _YouTubeLoginDialogState();
}

class _YouTubeLoginDialogState extends State<YouTubeLoginDialog> {
  final TextEditingController _urlController = TextEditingController();
  final MusicService _musicService = MusicService();
  final PlaylistService _playlistService = PlaylistService();
  final LanguageService _lang = LanguageService();

  bool _isLoading = false;
  String? _statusMessage;

  void _importPlaylist() async {
    final query = _urlController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _statusMessage = _lang.isHindi
            ? 'कृपया एक वैध YouTube प्लेलिस्ट लिंक दर्ज करें'
            : 'Please enter a valid YouTube playlist link';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = _lang.isHindi
          ? 'यूट्यूब से गाने लोड हो रहे हैं...'
          : 'Fetching songs from YouTube...';
    });

    try {
      final songs = await _musicService.importYouTubePlaylist(query);

      if (!mounted) return;

      if (songs.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = _lang.isHindi
              ? 'प्लेलिस्ट से कोई गाना नहीं मिला। सुनिश्चित करें कि प्लेलिस्ट पब्लिक है।'
              : 'No songs found. Ensure the playlist is public.';
        });
        return;
      }

      // Generate playlist name
      final playlistName = songs.first.album.isNotEmpty && songs.first.album != 'Single'
          ? songs.first.album
          : 'YT Playlist ${DateTime.now().minute}';

      await _playlistService.createPlaylist(playlistName);
      final createdList = _playlistService.playlists.first;

      for (final s in songs) {
        await _playlistService.addSongToPlaylist(createdList.id, s);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00E676),
            content: Text(
              _lang.isHindi
                  ? 'सफलता! "$playlistName" (${songs.length} गाने) लाइब्रेरी में जुड़ गई।'
                  : 'Success! "$playlistName" (${songs.length} tracks) added to Library.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = _lang.isHindi ? 'इम्पोर्ट विफल रहा: $e' : 'Import failed: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = _lang.isHindi;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF161616),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFFFF0000), width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // YouTube Brand Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_circle_filled_rounded,
                    color: Color(0xFFFF0000),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'यूट्यूब & YT म्यूजिक कनेक्ट' : 'YouTube & YT Music Connect',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isHindi
                            ? 'ओपन सोर्स प्राइवेसी मोड (बिना लॉगिन ट्रैकिंग)'
                            : 'Open Source Privacy Mode (No tracking)',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Account Status Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF00E676), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isHindi
                          ? 'कनेक्टेड: सुरक्षित ओपन-सोर्स यूट्यूब सेशन एक्टिव है।'
                          : 'Connected: Secure open-source YouTube session is active.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Playlist URL Input
            Text(
              isHindi ? 'यूट्यूब प्लेलिस्ट इम्पोर्ट करें' : 'Import YouTube Playlist',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isHindi
                    ? 'https://youtube.com/playlist?list=...'
                    : 'Paste playlist link or ID...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF222222),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38),
                  onPressed: () => _urlController.clear(),
                ),
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('विफल') || _statusMessage!.contains('failed')
                      ? Colors.redAccent
                      : const Color(0xFF05D9E8),
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Import Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                onPressed: _isLoading ? null : _importPlaylist,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.playlist_add_rounded, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isHindi ? 'प्लेलिस्ट इम्पोर्ट करें' : 'Import Playlist',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
