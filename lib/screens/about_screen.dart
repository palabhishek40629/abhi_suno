import 'package:flutter/material.dart';
import '../services/language_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService(),
      builder: (context, _) {
        final isHindi = LanguageService().isHindi;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isHindi ? 'अभी सुनो के बारे में' : 'About Abhi Suno',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 3D "A" Logo & App Title Card
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2A6D), Color(0xFF05D9E8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF05D9E8).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(2, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Abhi Suno',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 3.9.0 Master Edition (Open Source)',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Developer Card (Abhishek Pal)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F1F2E), Color(0xFF14141E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF05D9E8).withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF05D9E8), Color(0xFFFF2A6D)],
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF1E1E1E),
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'निर्माता व डेवलपर' : 'Created & Developed by',
                        style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Abhishek Pal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05D9E8).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF05D9E8).withOpacity(0.5)),
                        ),
                        child: Text(
                          isHindi ? 'कंप्यूटर साइंस एंड इंजीनियरिंग के छात्र' : 'Computer Science & Engineering Student',
                          style: const TextStyle(
                            color: Color(0xFF05D9E8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHindi
                            ? 'कंप्यूटर साइंस एंड इंजीनियरिंग (CSE) के छात्र अभिषेक पाल द्वारा विकसित। 100% प्योर ऑडियो और बिना किसी विज्ञापन (Ad-Free) के संगीत का आनंद लें।'
                            : 'Developed by Abhishek Pal, Computer Science & Engineering (CSE) student. 100% pure audio, ad-free open-source music player.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Khaas Features (Key Highlights)',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _buildFeatureTile(
            Icons.music_note_rounded,
            'Sare Hindi Songs Available',
            'Bollywood, Retro 90s, Romantic, Punjabi aur Lo-Fi ka vishal sangeet bhandar.',
            const Color(0xFF05D9E8),
          ),
          _buildFeatureTile(
            Icons.block_rounded,
            '100% Ad-Free (Koi Vigyapan Nahi)',
            'Bina kisi ad ke direct unlimited streaming aur download.',
            const Color(0xFFFF2A6D),
          ),
          _buildFeatureTile(
            Icons.download_done_rounded,
            'In-App Offline Downloads',
            'Download kiye gaye gaane surakshit roop se app ke andar rehte hain aur bina internet bajte hain.',
            const Color(0xFF00E676),
          ),
          _buildFeatureTile(
            Icons.screen_lock_portrait_rounded,
            'Background & Lockscreen Controls',
            'Screen lock hone par bhi notification se gaana aaram se change karein.',
            const Color(0xFFFFD600),
          ),
          _buildFeatureTile(
            Icons.lyrics_rounded,
            'Lyrics & Equalizer',
            'Gaane ke bol (Lyrics) aur apne hisaab se Bass Boost aur sound adjust karein.',
            const Color(0xFF9C27B0),
          ),
          _buildFeatureTile(
            Icons.code_rounded,
            'Open Source & Privacy First',
            'Yeh app 100% open source hai. Koi data tracking ya user profiling nahi ki jaati.',
            Colors.white70,
          ),

          const SizedBox(height: 24),

          // Footer
          Center(
            child: Text(
              'Made with ❤️ by Abhishek Pal\nOpen Source MIT License',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
      },
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
