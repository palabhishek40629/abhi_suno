import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/user_service.dart';
import '../widgets/screen_bubble_celebration.dart';
import '../widgets/tactile_3d_wrapper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _user = UserService();
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();

  static const MethodChannel _nativeChannel = MethodChannel('com.abhishekpal.abhisuno/native');

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  String? _selectedImagePath;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _presetAvatars = [
    {
      'id': 'preset:dj',
      'label': 'DJ Beats',
      'icon': Icons.headphones_rounded,
      'gradient': [Color(0xFF00E5FF), Color(0xFF0072FF)],
    },
    {
      'id': 'preset:rock',
      'label': 'Rockstar',
      'icon': Icons.electric_bolt_rounded,
      'gradient': [Color(0xFFFF2A6D), Color(0xFFFF7597)],
    },
    {
      'id': 'preset:piano',
      'label': 'Maestro',
      'icon': Icons.piano_rounded,
      'gradient': [Color(0xFF7C4DFF), Color(0xFF536DFE)],
    },
    {
      'id': 'preset:star',
      'label': 'Superstar',
      'icon': Icons.star_rounded,
      'gradient': [Color(0xFFFFD700), Color(0xFFFF9100)],
    },
    {
      'id': 'preset:fire',
      'label': 'Pulse',
      'icon': Icons.local_fire_department_rounded,
      'gradient': [Color(0xFFFF3D00), Color(0xFFFF9100)],
    },
    {
      'id': 'preset:wave',
      'label': 'Equalizer',
      'icon': Icons.graphic_eq_rounded,
      'gradient': [Color(0xFF00E676), Color(0xFF00B0FF)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _user.userName);
    _bioController = TextEditingController(text: _user.userBio);
    _emailController = TextEditingController(text: _user.userEmail);
    _selectedImagePath = _user.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDeviceImage() async {
    try {
      final String? path = await _nativeChannel.invokeMethod<String>('pickProfileImage');
      if (path != null && path.isNotEmpty) {
        setState(() => _selectedImagePath = path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _lang.isHindi
                  ? 'गैलरी से फोटो नहीं चुना जा सका, कृपया नीचे दिए गए अवतारों में से चुनें'
                  : 'Could not open gallery, choose from presets below',
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(_lang.isHindi ? 'कृपया अपना नाम दर्ज करें' : 'Please enter your name'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    await _user.updateProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      email: _emailController.text.trim(),
      imagePath: _selectedImagePath,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScreenBubbleCelebration.show(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00E676),
          content: Text(
            _lang.isHindi ? '🎉 प्रोफ़ाइल सफलतापूर्वक अपडेट हो गई!' : '🎉 Profile updated successfully!',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildAvatarPreview() {
    Widget avatarChild;

    if (_selectedImagePath != null && _selectedImagePath!.startsWith('preset:')) {
      final preset = _presetAvatars.firstWhere(
        (p) => p['id'] == _selectedImagePath,
        orElse: () => _presetAvatars.first,
      );
      final List<Color> colors = preset['gradient'] as List<Color>;
      final IconData icon = preset['icon'] as IconData;

      avatarChild = Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 52),
      );
    } else if (_selectedImagePath != null && File(_selectedImagePath!).existsSync()) {
      avatarChild = Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00E5FF), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.file(
            File(_selectedImagePath!),
            width: 104,
            height: 104,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      avatarChild = Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 56),
      );
    }

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatarChild,
          GestureDetector(
            onTap: _pickDeviceImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)]),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2A6D).withOpacity(0.6),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoogleSignInDialog(bool isHindi) {
    final googleNameCtrl = TextEditingController(text: _user.userName.isNotEmpty ? _user.userName : 'Abhishek Pal');
    final googleEmailCtrl = TextEditingController(text: _user.userEmail.isNotEmpty ? _user.userEmail : 'abhishekpal40629@gmail.com');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.network(
                      'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, color: Colors.blue, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHindi ? 'Google से साइन इन करें' : 'Sign in with Google',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          isHindi ? '100% मुफ़्त एवं सुरक्षित गूगल खाता' : '100% Free & Secure Google Account',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                isHindi ? 'Google प्रोफ़ाइल नाम' : 'Google Profile Name',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: googleNameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF00E5FF), size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isHindi ? 'Gmail पता (Email Address)' : 'Gmail Address',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: googleEmailCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFFFF2A6D), size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Tactile3DWrapper(
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _user.loginWithGoogle(
                      name: googleNameCtrl.text.trim().isNotEmpty ? googleNameCtrl.text.trim() : 'Abhishek Pal',
                      email: googleEmailCtrl.text.trim().isNotEmpty ? googleEmailCtrl.text.trim() : 'abhishekpal40629@gmail.com',
                    );
                    _nameController.text = _user.userName;
                    _bioController.text = _user.userBio;
                    _emailController.text = _user.userEmail;
                    if (mounted) {
                      ScreenBubbleCelebration.show(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF00E676),
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.black),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isHindi
                                      ? 'Google से सफलतापूर्वक साइन इन किया गया!'
                                      : 'Successfully signed in with Google!',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  scaleElevation: 1.08,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.white.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login_rounded, color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isHindi ? 'Google से लॉगिन पूर्ण करें' : 'Complete Google Login',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang, _user]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        final cardColor = _theme.cardBg;
        final isHindi = _lang.isHindi;

        return Scaffold(
          backgroundColor: _theme.scaffoldBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isHindi ? 'प्रोफ़ाइल अपडेट करें' : 'Update Profile',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar preview with camera button
                _buildAvatarPreview(),
                const SizedBox(height: 12),

                // Device Photo Pick Button
                Center(
                  child: Tactile3DWrapper(
                    onTap: _pickDeviceImage,
                    scaleElevation: 1.05,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_rounded, color: Color(0xFF00E5FF), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            isHindi ? 'गैलरी से फोटो चुनें' : 'Choose Photo from Gallery',
                            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Preset Avatars Section
                Text(
                  isHindi ? 'या म्यूज़िकल अवतार चुनें:' : 'Or Choose a Musical Avatar:',
                  style: TextStyle(color: subtextColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetAvatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final item = _presetAvatars[i];
                      final isSelected = _selectedImagePath == item['id'];
                      final List<Color> colors = item['gradient'] as List<Color>;

                      return Tactile3DWrapper(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedImagePath = item['id'] as String);
                        },
                        isCircle: true,
                        scaleElevation: 1.15,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: colors),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: colors.first.withOpacity(0.6),
                                  blurRadius: 14,
                                ),
                            ],
                          ),
                          child: Icon(item['icon'] as IconData, color: Colors.white, size: 26),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Form Section Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      Text(
                        isHindi ? 'आपका नाम (User Name)' : 'Full Name',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF00E5FF), size: 20),
                          hintText: isHindi ? 'अपना नाम दर्ज करें' : 'Enter your name',
                          hintStyle: TextStyle(color: subtextColor.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Bio / Tagline Field (editable version of Computer Science & Engineering Student)
                      Text(
                        isHindi ? 'बायो / टैगलाइन (Bio / Tagline)' : 'Bio / Tagline',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHindi
                            ? 'नाम के नीचे दिखने वाला विवरण (जैसे: Computer Science & Engineering Student)'
                            : 'Subtitle shown under your name in profile',
                        style: TextStyle(color: subtextColor, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bioController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.school_rounded, color: Color(0xFFFF2A6D), size: 20),
                          hintText: 'Computer Science & Engineering Student',
                          hintStyle: TextStyle(color: subtextColor.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFFF2A6D), width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Email Field
                      Text(
                        isHindi ? 'ईमेल / खाता (Email Account)' : 'Email / Account',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF7C4DFF), size: 20),
                          hintText: 'yourname@example.com',
                          hintStyle: TextStyle(color: subtextColor.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3D GOOGLE SIGN-IN BUTTON
                Tactile3DWrapper(
                  onTap: () => _showGoogleSignInDialog(isHindi),
                  scaleElevation: 1.06,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.network(
                            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, color: Colors.blue, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _user.isGoogleUser
                              ? (isHindi ? 'Google खाता लिंक है (${_user.userEmail})' : 'Google Connected (${_user.userEmail})')
                              : (isHindi ? 'Google से साइन इन करें (मुफ़्त)' : 'Sign in with Google (Free)'),
                          style: TextStyle(
                            color: _user.isGoogleUser ? const Color(0xFF00E676) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (_user.isGoogleUser) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 16),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Account Status Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _user.isLoggedIn ? const Color(0xFF00E676).withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                        ),
                        child: Icon(
                          _user.isLoggedIn ? Icons.verified_user_rounded : Icons.person_outline_rounded,
                          color: _user.isLoggedIn ? const Color(0xFF00E676) : Colors.amber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user.isLoggedIn
                                  ? (isHindi ? 'सक्रिय खाता (Active Account)' : 'Active Account')
                                  : (isHindi ? 'गेस्ट मोड (Guest Mode)' : 'Guest Mode'),
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              _user.isLoggedIn
                                  ? (isHindi ? 'स्थानीय स्टोरेज में सुरक्षित रूप से सहेजा गया' : 'Securely saved locally')
                                  : (isHindi ? 'लॉगिन करें या प्रोफ़ाइल बनाएं' : 'Log in to sync profile'),
                              style: TextStyle(color: subtextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_user.isLoggedIn) {
                            _user.logout();
                            _nameController.text = _user.userName;
                            _bioController.text = _user.userBio;
                            _emailController.text = _user.userEmail;
                            setState(() => _selectedImagePath = null);
                          } else {
                            _user.login(
                              name: 'Abhishek Pal',
                              email: 'abhishekpal40629@gmail.com',
                              bio: 'Computer Science & Engineering Student',
                            );
                            _nameController.text = _user.userName;
                            _bioController.text = _user.userBio;
                            _emailController.text = _user.userEmail;
                          }
                        },
                        child: Text(
                          _user.isLoggedIn
                              ? (isHindi ? 'लॉग आउट' : 'Log Out')
                              : (isHindi ? 'लॉग इन' : 'Log In'),
                          style: TextStyle(
                            color: _user.isLoggedIn ? Colors.redAccent : const Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 3D DYNAMIC SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: Tactile3DWrapper(
                    onTap: _isSaving ? () {} : _saveProfile,
                    scaleElevation: 1.15,
                    glowColor: const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            isHindi ? 'प्रोफ़ाइल सहेजें एवं अपडेट करें' : 'Save & Update Profile',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
