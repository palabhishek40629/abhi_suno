import 'package:flutter/material.dart';
import '../services/language_service.dart';
import 'youtube_login_dialog.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onAboutTap;
  final VoidCallback? onSearchTap;

  const AppHeader({
    Key? key,
    this.onAboutTap,
    this.onSearchTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 3D "A" Logo Badge + "Abhi Suno" Stylized Branding
          Row(
            children: [
              // 3D "A" Monogram Emblem
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF2A6D), // Vibrant Neon Pink
                      Color(0xFF05D9E8), // Electric Cyan
                      Color(0xFF005670), // Deep 3D Shadow
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2A6D).withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(-2, -2),
                    ),
                    BoxShadow(
                      color: const Color(0xFF05D9E8).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(3, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 3D Shadow for letter A
                      Transform.translate(
                        offset: const Offset(1.5, 1.5),
                        child: const Text(
                          'A',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'sans-serif',
                            color: Colors.black45,
                          ),
                        ),
                      ),
                      // Foreground crisp 3D Letter A
                      const Text(
                        'A',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'sans-serif',
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Stylized 3D "Abhi Suno" Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFE0E0E0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: const Text(
                          'Abhi ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF05D9E8), Color(0xFFFF2A6D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Suno',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'by Abhishek Pal',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Header Actions (Language Toggle, YouTube Sync, Creator Profile)
          Row(
            children: [
              // Language Switcher Pill [हिन्दी / EN]
              AnimatedBuilder(
                animation: LanguageService(),
                builder: (context, _) {
                  final isHindi = LanguageService().isHindi;
                  return InkWell(
                    onTap: () => LanguageService().toggleLanguage(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF05D9E8).withOpacity(0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language_rounded, size: 14, color: Color(0xFF05D9E8)),
                          const SizedBox(width: 4),
                          Text(
                            isHindi ? 'हिन्दी' : 'EN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),

              // YouTube Connect & Playlist Button
              IconButton(
                icon: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFF0000), size: 26),
                tooltip: 'YouTube Playlist Import',
                onPressed: () => YouTubeLoginDialog.show(context),
              ),

              // Search Button
              if (onSearchTap != null)
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                  tooltip: 'Search',
                  onPressed: onSearchTap,
                ),

              // Creator Profile (Abhishek Pal)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF05D9E8), width: 1.5),
                  ),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFF1E1E1E),
                    child: Text(
                      'AP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF05D9E8),
                      ),
                    ),
                  ),
                ),
                tooltip: 'Abhishek Pal (About)',
                onPressed: onAboutTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
