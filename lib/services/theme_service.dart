import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  dark,
  light,
  transparent,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal() {
    _loadTheme();
  }

  AppThemeMode _currentMode = AppThemeMode.dark;
  AppThemeMode get currentMode => _currentMode;

  bool get isDark => _currentMode == AppThemeMode.dark;
  bool get isLight => _currentMode == AppThemeMode.light;
  bool get isTransparent => _currentMode == AppThemeMode.transparent;

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString('app_theme_mode') ?? 'dark';
      if (modeStr == 'light') {
        _currentMode = AppThemeMode.light;
      } else if (modeStr == 'transparent') {
        _currentMode = AppThemeMode.transparent;
      } else {
        _currentMode = AppThemeMode.dark;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _currentMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = mode == AppThemeMode.light
          ? 'light'
          : (mode == AppThemeMode.transparent ? 'transparent' : 'dark');
      await prefs.setString('app_theme_mode', modeStr);
    } catch (_) {}
  }

  Color get primaryColor => const Color(0xFF05D9E8);
  Color get secondaryColor => const Color(0xFFFF2A6D);

  Color get scaffoldBg {
    switch (_currentMode) {
      case AppThemeMode.light:
        return const Color(0xFFF6F8FA);
      case AppThemeMode.transparent:
        return const Color(0xFF10121A);
      case AppThemeMode.dark:
      default:
        return const Color(0xFF0A0A0A);
    }
  }

  Color get cardBg {
    switch (_currentMode) {
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.transparent:
        return Colors.white.withOpacity(0.08);
      case AppThemeMode.dark:
      default:
        return const Color(0xFF1A1A1A);
    }
  }

  Color get textColor {
    switch (_currentMode) {
      case AppThemeMode.light:
        return const Color(0xFF1A1A1A);
      case AppThemeMode.transparent:
      case AppThemeMode.dark:
      default:
        return Colors.white;
    }
  }

  Color get subtextColor {
    switch (_currentMode) {
      case AppThemeMode.light:
        return const Color(0xFF6B7280);
      case AppThemeMode.transparent:
        return Colors.white70;
      case AppThemeMode.dark:
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  BoxDecoration get backgroundDecoration {
    if (_currentMode == AppThemeMode.transparent) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF181126),
            Color(0xFF0B1424),
            Color(0xFF050510),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (_currentMode == AppThemeMode.light) {
      return const BoxDecoration(
        color: Color(0xFFF6F8FA),
      );
    } else {
      return const BoxDecoration(
        color: Color(0xFF0A0A0A),
      );
    }
  }

  ThemeData get themeData {
    if (_currentMode == AppThemeMode.light) {
      return ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        primaryColor: const Color(0xFF007AFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF007AFF),
          secondary: Color(0xFFFF2A6D),
          surface: Colors.white,
          background: Color(0xFFF6F8FA),
        ),
        fontFamily: 'sans-serif',
        useMaterial3: true,
      );
    }

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardBg,
        background: scaffoldBg,
      ),
      fontFamily: 'sans-serif',
      useMaterial3: true,
    );
  }
}
