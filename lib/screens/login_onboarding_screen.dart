import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../widgets/tactile_3d_wrapper.dart';

class LoginOnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const LoginOnboardingScreen({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<LoginOnboardingScreen> createState() => _LoginOnboardingScreenState();
}

class _LoginOnboardingScreenState extends State<LoginOnboardingScreen> {
  final PageController _pageController = PageController();
  final AuthService _auth = AuthService();
  final SyncService _sync = SyncService();
  final LanguageService _lang = LanguageService();

  int _currentPage = 0;
  bool _isLoginTab = true; // true = Log In, false = Sign Up
  bool _isPhoneMethod = true; // true = Phone+OTP, false = Gmail+Password

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otp1Controller = TextEditingController();
  final TextEditingController _otp2Controller = TextEditingController();
  final TextEditingController _otp3Controller = TextEditingController();
  final TextEditingController _otp4Controller = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isOtpSent = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _resendCountdown = 30;
  Timer? _countdownTimer;

  static const Color cyanNeon = Color(0xFF2FC0DB);
  static const Color pinkNeon = Color(0xFFD34C8C);
  static const Color darkBg = Color(0xFF070913);
  static const Color cardBg = Color(0xFF131726);

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _otp1Controller.dispose();
    _otp2Controller.dispose();
    _otp3Controller.dispose();
    _otp4Controller.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    widget.onComplete();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await _auth.signInWithGoogle(
        customEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        customName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      );
      if (success) {
        await _sync.syncUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00E676),
              content: Text(
                _lang.isHindi ? 'Google से लॉगिन सफल!' : 'Signed in with Google successfully!',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          );
        }
        await _completeOnboarding();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _sendPhoneOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(_lang.isHindi ? 'कृपया 10 अंकों का मान्य मोबाइल नंबर दर्ज करें' : 'Please enter a valid 10-digit mobile number'),
        ),
      );
      return;
    }
    setState(() {
      _isOtpSent = true;
    });
    _startCountdown();
  }

  void _autofillDemoOtp() {
    setState(() {
      _otp1Controller.text = '8';
      _otp2Controller.text = '5';
      _otp3Controller.text = '2';
      _otp4Controller.text = '0';
    });
  }

  Future<void> _verifyOtpAndLogin() async {
    final otp = '${_otp1Controller.text}${_otp2Controller.text}${_otp3Controller.text}${_otp4Controller.text}';
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(_lang.isHindi ? 'कृपया 4-अंकों का OTP दर्ज करें' : 'Please enter the 4-digit OTP'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'User ${phone.substring(max(0, phone.length - 4))}';
    await _auth.signInWithGoogle(
      customEmail: '$phone@phone.abhisuno.app',
      customName: name,
    );
    await _sync.syncUserData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00E676),
          content: Text(
            _lang.isHindi ? 'लॉगिन सफल!' : 'Login Successful!',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      );
    }
    await _completeOnboarding();
  }

  int max(int a, int b) => a > b ? a : b;

  Future<void> _handleEmailPasswordAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!email.contains('@') || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(_lang.isHindi ? 'कृपया मान्य ईमेल और न्यूनतम 6 अक्षरों का पासवर्ड दर्ज करें' : 'Please enter a valid email and 6+ char password'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : email.split('@').first;
    await _auth.signInWithGoogle(
      customEmail: email,
      customName: name,
    );
    await _sync.syncUserData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00E676),
          content: Text(
            _lang.isHindi ? 'लॉगिन सफल!' : 'Login Successful!',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      );
    }
    await _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = _lang.isHindi;

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (idx) => setState(() => _currentPage = idx),
          children: [
            // PAGE 1: Welcome Screen (Poster + Features + Next)
            _buildWelcomePage(isHindi),
            // PAGE 2: Authentication Screen (Google + Phone/Email + Skip)
            _buildAuthPage(isHindi),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(bool isHindi) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cyanNeon.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cyanNeon.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.music_note_rounded, color: cyanNeon, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Abhi Suno',
                      style: TextStyle(color: cyanNeon, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _completeOnboarding,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                label: Text(
                  isHindi ? 'स्किप करें (Skip)' : 'Skip',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Poster Image with Glow
          Container(
            height: MediaQuery.of(context).size.height * 0.44,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cyanNeon.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/welcome_banner.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1F1F1F),
                      child: const Center(
                        child: Icon(Icons.album_rounded, size: 80, color: cyanNeon),
                      ),
                    ),
                  ),
                  // Badge at Top
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: cyanNeon, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'OFFICIAL ABHI SUNO APP',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cyanNeon.withOpacity(0.2), pinkNeon.withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cyanNeon.withOpacity(0.5)),
            ),
            child: Text(
              isHindi ? '🎵 असीमित भारतीय एवं वैश्विक संगीत' : '🎵 THE WORLD OF UNLIMITED MUSIC',
              style: const TextStyle(color: cyanNeon, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),

          const SizedBox(height: 12),

          // Welcome Heading
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [cyanNeon, pinkNeon],
            ).createShader(bounds),
            child: Text(
              isHindi ? 'स्वागत है' : 'Welcome',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
            ),
          ),

          const SizedBox(height: 6),
          Text(
            isHindi ? 'अभि सुनो - आपका अपना विज्ञापन-मुक्त म्यूज़िक ऐप' : 'Welcome to our music application',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 16),

          // Feature Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeaturePill(Icons.headset_rounded, isHindi ? 'असीमित गाने' : 'Unlimited Songs'),
              _buildFeaturePill(Icons.bolt_rounded, isHindi ? 'तेज़ डाउनलोड' : 'Fast Downloads'),
              _buildFeaturePill(Icons.block_rounded, isHindi ? 'बिना विज्ञापन' : 'Ad-Free Music'),
            ],
          ),

          const SizedBox(height: 26),

          // Next Button
          Tactile3DWrapper(
            onTap: () {
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
              );
            },
            scaleElevation: 1.08,
            glowColor: cyanNeon,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [cyanNeon, pinkNeon],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cyanNeon.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isHindi ? 'आगे बढ़ें (Next)' : 'Next',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cyanNeon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAuthPage(bool isHindi) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Back and Skip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
              TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  isHindi ? 'स्किप (Skip)' : 'Skip',
                  style: const TextStyle(color: cyanNeon, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Segmented Tab Switcher (Log In / Sign Up)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isLoginTab = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isLoginTab ? cyanNeon : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isHindi ? 'लॉगिन (Log In)' : 'Log In',
                        style: TextStyle(
                          color: _isLoginTab ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isLoginTab = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isLoginTab ? pinkNeon : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isHindi ? 'साइन अप (Sign Up)' : 'Sign Up',
                        style: TextStyle(
                          color: !_isLoginTab ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            _isLoginTab
                ? (isHindi ? 'अपने खाते में लॉगिन करें' : 'Log In to Your Account')
                : (isHindi ? 'नया खाता बनाएं' : 'Create an Account'),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isHindi ? 'लाइक्ड गाने और प्लेलिस्ट क्लाउड पर सुरक्षित रखें' : 'Sign in to enjoy seamless ad-free music streaming',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),

          const SizedBox(height: 20),

          // Method 1: Google Sign-in Button
          Tactile3DWrapper(
            onTap: _isLoading ? null : _handleGoogleSignIn,
            scaleElevation: 1.05,
            glowColor: const Color(0xFF4285F4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2640),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4285F4).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isHindi ? 'Google से जारी रखें' : 'Sign in with Google',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.white12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  isHindi ? 'या इसके साथ जारी रखें' : 'OR CONTINUE WITH',
                  style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.8),
                ),
              ),
              const Expanded(child: Divider(color: Colors.white12)),
            ],
          ),

          const SizedBox(height: 16),

          // Method Toggle (Mobile Number vs Gmail)
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_android_rounded, size: 14),
                      const SizedBox(width: 6),
                      Text(isHindi ? 'मोबाइल एवं OTP' : 'Mobile & OTP'),
                    ],
                  ),
                  selected: _isPhoneMethod,
                  onSelected: (val) => setState(() => _isPhoneMethod = true),
                  selectedColor: cyanNeon.withOpacity(0.2),
                  backgroundColor: cardBg,
                  labelStyle: TextStyle(
                    color: _isPhoneMethod ? cyanNeon : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: _isPhoneMethod ? cyanNeon : Colors.white12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mail_rounded, size: 14),
                      const SizedBox(width: 6),
                      Text(isHindi ? 'Gmail एवं पासवर्ड' : 'Gmail & Password'),
                    ],
                  ),
                  selected: !_isPhoneMethod,
                  onSelected: (val) => setState(() => _isPhoneMethod = false),
                  selectedColor: pinkNeon.withOpacity(0.2),
                  backgroundColor: cardBg,
                  labelStyle: TextStyle(
                    color: !_isPhoneMethod ? pinkNeon : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: !_isPhoneMethod ? pinkNeon : Colors.white12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // PHONE METHOD
          if (_isPhoneMethod) ...[
            Text(
              isHindi ? 'मोबाइल नंबर दर्ज करें' : 'Enter Mobile Number',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Text('🇮🇳 +91', style: TextStyle(color: cyanNeon, fontWeight: FontWeight.bold)),
                ),
                hintText: '98765 43210',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: cyanNeon)),
              ),
            ),

            // OTP Section if Sent
            if (_isOtpSent) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  isHindi ? '4-अंकों का OTP दर्ज करें' : 'Enter 4-Digit OTP',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              // Auto-fill Demo OTP Chip
              Center(
                child: ActionChip(
                  onPressed: _autofillDemoOtp,
                  backgroundColor: cyanNeon.withOpacity(0.15),
                  side: BorderSide(color: cyanNeon.withOpacity(0.5)),
                  avatar: const Icon(Icons.bolt_rounded, color: cyanNeon, size: 16),
                  label: Text(
                    isHindi ? '⚡ ऑटोफ़िल OTP: 8520' : '⚡ Auto-fill OTP: 8520',
                    style: const TextStyle(color: cyanNeon, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4 Digits OTP Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOtpBox(_otp1Controller),
                  _buildOtpBox(_otp2Controller),
                  _buildOtpBox(_otp3Controller),
                  _buildOtpBox(_otp4Controller),
                ],
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  _resendCountdown > 1
                      ? '${isHindi ? "OTP पुनः भेजें:" : "Resend OTP in:"} 00:${_resendCountdown.toString().padLeft(2, "0")}'
                      : (isHindi ? 'OTP दोबारा भेजने के लिए तैयार' : 'Ready to resend OTP'),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Submit Button
            Tactile3DWrapper(
              onTap: _isLoading
                  ? null
                  : (_isOtpSent ? _verifyOtpAndLogin : _sendPhoneOtp),
              scaleElevation: 1.05,
              glowColor: cyanNeon,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [cyanNeon, Color(0xFF00A2C7)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _isOtpSent
                            ? (isHindi ? 'सत्यापित करें और लॉगिन करें' : 'Verify & Continue')
                            : (isHindi ? 'OTP प्राप्त करें ➔' : 'Get OTP ➔'),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ] else ...[
            // GMAIL + PASSWORD METHOD
            if (!_isLoginTab) ...[
              Text(
                isHindi ? 'आपका नाम' : 'Your Name',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_rounded, color: pinkNeon, size: 18),
                  hintText: 'Abhishek Pal',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              isHindi ? 'Gmail / ईमेल पता' : 'Gmail / Email Address',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_rounded, color: pinkNeon, size: 18),
                hintText: 'name@gmail.com',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              isHindi ? 'पासवर्ड' : 'Password',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_rounded, color: pinkNeon, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                hintText: '••••••••',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
              ),
            ),

            const SizedBox(height: 20),

            // Submit Email Button
            Tactile3DWrapper(
              onTap: _isLoading ? null : _handleEmailPasswordAuth,
              scaleElevation: 1.05,
              glowColor: pinkNeon,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [pinkNeon, Color(0xFFC2185B)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _isLoginTab
                            ? (isHindi ? 'लॉगिन करें' : 'Log In')
                            : (isHindi ? 'खाता बनाएं' : 'Create Account'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildOtpBox(TextEditingController controller) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cyanNeon.withOpacity(0.5)),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (val) {
          if (val.isNotEmpty) FocusScope.of(context).nextFocus();
        },
      ),
    );
  }
}
