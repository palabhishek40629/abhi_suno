import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const AnimatedSplashScreen({Key? key, required this.onFinish}) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Fast transition (~1.0s) into the main app
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted) {
        widget.onFinish();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090D),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Ambient Blurred Background Glow (No black borders; seamlessly matches poster colors)
            Image.asset(
              'assets/images/startup_portrait.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/startup_wide.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0B0D14)),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
              child: Container(
                color: Colors.black.withOpacity(0.55),
              ),
            ),
            // Layer 2: 100% Crisp, Complete, Uncut & Unzoomed Poster in Center
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Image.asset(
                    'assets/images/startup_portrait.png',
                    fit: BoxFit.contain, // Complete poster without ANY zoom or cuts!
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/startup_wide.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppConstants.startupAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          AppConstants.logoAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
