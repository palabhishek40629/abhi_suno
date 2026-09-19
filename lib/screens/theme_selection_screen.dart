import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../widgets/tactile_3d_wrapper.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService();
    final lang = LanguageService();

    return AnimatedBuilder(
      animation: Listenable.merge([theme, lang]),
      builder: (context, _) {
        final textColor = theme.textColor;
        final subtextColor = theme.subtextColor;
        final cardColor = theme.cardBg;
        final isHindi = lang.isHindi;

        final themes = [
          _ThemeItem(
            mode: AppThemeMode.cyberpunk,
            title: isHindi ? 'साइबरपंक (Cyberpunk Neon)' : 'Cyberpunk Neon',
            desc: isHindi ? 'नियॉन स्यान और पिंक का 3D भविष्य' : 'Signature neon cyan & hot pink',
            accent: const Color(0xFF00E5FF),
            previewColors: [const Color(0xFF0A0E17), const Color(0xFF00E5FF), const Color(0xFFFF2A6D)],
          ),
          _ThemeItem(
            mode: AppThemeMode.dark,
            title: isHindi ? 'अमोलेड डार्क (AMOLED Dark)' : 'AMOLED Dark',
            desc: isHindi ? 'गहरा काला, अधिकतम बैटरी बचत' : 'Pure pitch black for OLED panels',
            accent: const Color(0xFF9E9E9E),
            previewColors: [Colors.black, const Color(0xFF1E1E1E), const Color(0xFF757575)],
          ),
          _ThemeItem(
            mode: AppThemeMode.light,
            title: isHindi ? 'प्रीमियम लाइट (Clean Light)' : 'Clean Light',
            desc: isHindi ? 'स्वच्छ और चमकदार दिन का अनुभव' : 'Crisp, high-contrast bright mode',
            accent: const Color(0xFFFFB300),
            previewColors: [Colors.white, const Color(0xFFF5F5F5), const Color(0xFFFFB300)],
          ),
          _ThemeItem(
            mode: AppThemeMode.amoledPitch,
            title: isHindi ? 'मिडनाइट पिच (Midnight Pitch)' : 'Midnight Pitch',
            desc: isHindi ? 'काले रंग के साथ एमराल्ड ग्रीन चमक' : 'Deep obsidian with emerald neon glow',
            accent: const Color(0xFF00E676),
            previewColors: [Colors.black, const Color(0xFF121212), const Color(0xFF00E676)],
          ),
        ];

        return Scaffold(
          backgroundColor: theme.scaffoldBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isHindi ? 'ऐप थीम चुनें' : 'App Theme',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: theme.backgroundDecoration,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: themes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = themes[index];
                final isSelected = theme.currentMode == item.mode;

                return Tactile3DWrapper(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    theme.setThemeMode(item.mode);
                  },
                  scaleElevation: 1.05,
                  glowColor: item.accent,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? item.accent.withOpacity(0.12) : cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? item.accent : Colors.white12,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: item.accent.withOpacity(0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Theme Palette Circles
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1.5),
                            gradient: LinearGradient(
                              colors: item.previewColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.desc,
                                style: TextStyle(color: subtextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.accent,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.black, size: 16),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ThemeItem {
  final AppThemeMode mode;
  final String title;
  final String desc;
  final Color accent;
  final List<Color> previewColors;

  _ThemeItem({
    required this.mode,
    required this.title,
    required this.desc,
    required this.accent,
    required this.previewColors,
  });
}
