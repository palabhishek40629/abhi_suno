import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../screens/settings_screen.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onSearchTap;

  const AppHeader({
    Key? key,
    this.onSearchTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService();
    final lang = LanguageService();

    return AnimatedBuilder(
      animation: Listenable.merge([theme, lang]),
      builder: (context, _) {
        final textColor = theme.textColor;
        final subtextColor = theme.subtextColor;
        final primaryColor = theme.primaryColor;
        final isHindi = lang.isHindi;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 3D Golden Crown Audio Emblem & Brand Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black45,
                          child: const Icon(Icons.music_note_rounded, color: Colors.amber),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang.t('app_name'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: textColor,
                        ),
                      ),
                      Text(
                        lang.t('app_subtitle'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Header Actions: Language Switcher, Search, Settings Gear
              Row(
                children: [
                  // Language Switcher Pill [हिन्दी / EN]
                  InkWell(
                    onTap: () => lang.toggleLanguage(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            isHindi ? 'हिन्दी' : 'EN',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Optional Search Icon Button
                  if (onSearchTap != null)
                    IconButton(
                      icon: Icon(Icons.search_rounded, color: textColor, size: 24),
                      tooltip: lang.t('search'),
                      onPressed: onSearchTap,
                    ),

                  // Settings Gear Icon (contains YouTube login & Abhishek Pal bio)
                  IconButton(
                    icon: Icon(Icons.settings_rounded, color: textColor, size: 24),
                    tooltip: lang.t('settings'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
