import 'dart:async';
import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ff_brand_elements.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  final AppState appState;

  const SplashScreen({super.key, required this.appState});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Immediately restore session from synchronous WebStorage cache
    AuthService.getActiveUser().then((savedUser) {
      if (savedUser != null && mounted) {
        widget.appState.setUser(savedUser);
      }
    });

    Timer(const Duration(milliseconds: 1800), () async {
      if (mounted) {
        if (!widget.appState.isAuthenticated) {
          final savedUser = await AuthService.getActiveUser();
          if (savedUser != null) {
            widget.appState.setUser(savedUser);
          }
        }

        if (!mounted) return;

        final targetScreen = widget.appState.isAuthenticated
            ? HomeScreen(appState: widget.appState)
            : AuthScreen(appState: widget.appState);

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => targetScreen,
            transitionsBuilder: (context, anim, secAnim, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background subtle FF Watermark
          Positioned(
            right: -40,
            bottom: -40,
            child: const FfWatermark(size: 260, opacity: 0.04),
          ),
          Positioned(
            left: -40,
            top: -40,
            child: const FfWatermark(size: 200, opacity: 0.03, angle: 0.2),
          ),

          // Central Branding
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Logo Card with Light Theme Glow & Shadow
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAmber.withAlpha(80),
                              blurRadius: 36,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'imgasest/app logo .png',
                            width: 130,
                            height: 130,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 130,
                                height: 130,
                                color: AppTheme.primaryAmber,
                                child: const Center(
                                  child: Icon(Icons.sports_esports, size: 64, color: Colors.black),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Platform Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('BOOYAH ', style: AppTheme.gamingTitle(fontSize: 28, color: Colors.black)),
                          Text(
                            'REWARDS',
                            style: AppTheme.gamingTitle(fontSize: 28, color: AppTheme.primaryAmber),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Inline Free Fire Branding
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'PREMIUM ESPORTS ARENA FOR ',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF64748B),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const FreeFireLogoInline(height: 14),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Custom FF Short Logo Pulse
                      const FfLoadingSpinner(size: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Tagline & Fair Play Badge
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user, color: AppTheme.winningGreen, size: 14),
                      SizedBox(width: 6),
                      Text(
                        '100% Fair Play Verified • Instant UPI Payouts',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '© 2026 Booyah Rewards Platform',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
