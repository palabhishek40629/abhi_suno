import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class AppHeader extends StatefulWidget {
  final VoidCallback? onSearchTap;

  const AppHeader({
    Key? key,
    this.onSearchTap,
  }) : super(key: key);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();
  String? _customProfilePath;

  @override
  void initState() {
    super.initState();
    _loadProfileAvatar();
  }

  Future<void> _loadProfileAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('user_custom_profile_image');
      if (mounted && path != null && File(path).existsSync()) {
        setState(() => _customProfilePath = path);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        final primaryColor = _theme.primaryColor;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 3D Headphone Logo Emblem & Brand Title
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo_square.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black45,
                            child: const Icon(Icons.headphones_rounded, color: Colors.amber),
                          ),
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
                        _lang.t('app_name'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: textColor,
                        ),
                      ),
                      Text(
                        _lang.t('app_subtitle'),
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

              // Header Actions: Search Button + Profile Button + Settings Gear
              Row(
                children: [
                  if (widget.onSearchTap != null)
                    IconButton(
                      icon: Icon(Icons.search_rounded, color: textColor, size: 24),
                      tooltip: _lang.t('search'),
                      onPressed: widget.onSearchTap,
                    ),
                  IconButton(
                    icon: _customProfilePath != null
                        ? ClipOval(
                            child: Image.file(
                              File(_customProfilePath!),
                              width: 26,
                              height: 26,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.account_circle_outlined, color: textColor, size: 26),
                    tooltip: _lang.isHindi ? 'प्रोफ़ाइल' : 'Profile',
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                      _loadProfileAvatar();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_rounded, color: textColor, size: 24),
                    tooltip: _lang.t('settings'),
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
