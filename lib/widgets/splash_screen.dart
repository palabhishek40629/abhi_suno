import 'dart:async';
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

    // Fast transition (~0.9s total) to Home screen
    Timer(const Duration(milliseconds: 950), () {
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
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            'assets/images/startup_wide.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover, // 100% Full-Screen Edge-to-Edge Fill! Zero Letterboxing!
            errorBuilder: (_, __, ___) => Image.asset(
              AppConstants.startupAsset,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                AppConstants.logoAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
