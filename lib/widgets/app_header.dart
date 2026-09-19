import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../screens/profile_screen.dart';

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
  String _userName = 'Abhishek Pal';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('user_custom_profile_image');
      final name = prefs.getString('user_custom_profile_name');
      if (mounted) {
        setState(() {
          if (path != null && File(path).existsSync()) {
            _customProfilePath = path;
          }
          if (name != null && name.trim().isNotEmpty) {
            _userName = name.trim();
          }
        });
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
        const primaryCyan = Color(0xFF00E5FF);

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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryCyan.withOpacity(0.4),
                          blurRadius: 12,
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
                        'by $_userName',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: primaryCyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Header Actions: Search Button + Radiant Profile Button ONLY (Outer settings removed per user request)
              Row(
                children: [
                  if (widget.onSearchTap != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            primaryCyan.withOpacity(0.2),
                            const Color(0xFF0077FE).withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(color: primaryCyan.withOpacity(0.3)),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.search_rounded, color: primaryCyan, size: 22),
                        tooltip: _lang.t('search'),
                        onPressed: widget.onSearchTap,
                      ),
                    ),
                  // Radiant Profile Button with Avatar or Glowing Icon
                  InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                      _loadProfileData();
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryCyan.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _customProfilePath != null
                            ? Image.file(
                                File(_customProfilePath!),
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 34,
                                height: 34,
                                color: const Color(0xFF141414),
                                child: Icon(Icons.person_rounded, color: primaryCyan, size: 22),
                              ),
                      ),
                    ),
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
