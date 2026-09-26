import 'package:flutter/material.dart';

class MatchBannerImage extends StatelessWidget {
  final String? bannerImage;
  final double height;
  final double width;
  final BoxFit fit;

  const MatchBannerImage({
    super.key,
    required this.bannerImage,
    this.height = 120,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final banner = bannerImage?.trim();

    if (banner != null && (banner.startsWith('http://') || banner.startsWith('https://'))) {
      return Image.network(
        banner,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            width: width,
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _fallbackAsset(),
      );
    }

    return _fallbackAsset();
  }

  Widget _fallbackAsset() {
    String assetPath = (bannerImage != null && bannerImage!.isNotEmpty && !bannerImage!.startsWith('http'))
        ? bannerImage!.trim()
        : 'imgasest/brhomescreen .png';

    // Normalize potential space discrepancies in filenames
    if (assetPath == 'imgasest/brhomescreen.png') {
      assetPath = 'imgasest/brhomescreen .png';
    }

    return Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Try fallback to known banner
        return Image.asset(
          'imgasest/brhomescreen .png',
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height,
            width: width,
            color: const Color(0xFF0F172A),
            child: const Center(
              child: Icon(Icons.sports_esports, size: 40, color: Colors.amber),
            ),
          ),
        );
      },
    );
  }
}
