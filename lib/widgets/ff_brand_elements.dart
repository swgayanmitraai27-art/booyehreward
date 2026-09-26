import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';

/// Inline Free Fire or Free Fire MAX logo image widget
class FreeFireLogoInline extends StatelessWidget {
  final GameType gameType;
  final double height;
  final Color? color;
  final BoxFit fit;

  const FreeFireLogoInline({
    super.key,
    this.gameType = GameType.freeFire,
    this.height = 20,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = gameType == GameType.freeFireMax
        ? 'imgasest/FREE_FIRE_MAX_LOGO.PNG.png'
        : 'imgasest/FREE_FIRE_LOGO.PNG.png';

    return Image.asset(
      assetPath,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return Text(
          gameType == GameType.freeFireMax ? 'FREE FIRE MAX' : 'FREE FIRE',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: AppTheme.primaryAmber,
            letterSpacing: 0.5,
          ),
        );
      },
    );
  }
}

/// Creative Yellow FF Short Logo as a custom bullet point
class FfBulletPoint extends StatelessWidget {
  final double size;

  const FfBulletPoint({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 8, top: 2),
      child: Image.asset(
        'imgasest/FF_SHORT_LOGO.PNG.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.flash_on, size: 14, color: AppTheme.primaryAmber);
        },
      ),
    );
  }
}

/// Subtle Watermark for Backgrounds (e.g. Wallet, Profile, Dialogs)
class FfWatermark extends StatelessWidget {
  final double size;
  final double opacity;
  final double angle;

  const FfWatermark({
    super.key,
    this.size = 180,
    this.opacity = 0.05,
    this.angle = -0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          'imgasest/FF_SHORT_LOGO.PNG.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Custom FF Short Logo animated loading indicator
class FfLoadingSpinner extends StatefulWidget {
  final double size;

  const FfLoadingSpinner({super.key, this.size = 40});

  @override
  State<FfLoadingSpinner> createState() => _FfLoadingSpinnerState();
}

class _FfLoadingSpinnerState extends State<FfLoadingSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.85 + (_controller.value * 0.3);
        return Transform.scale(
          scale: scale,
          child: Image.asset(
            'imgasest/FF_SHORT_LOGO.PNG.png',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}
