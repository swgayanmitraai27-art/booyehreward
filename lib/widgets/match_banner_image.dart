import 'package:flutter/material.dart';

class MatchBannerImage extends StatelessWidget {
  final String? bannerImage;
  final double height;
  final double width;
  final BoxFit fit;

  const MatchBannerImage({
    super.key,
    required this.bannerImage,
    this.height = 140,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    String raw = bannerImage?.trim().replaceAll('"', '').replaceAll("'", '') ?? '';

    // If empty, use default BR banner
    if (raw.isEmpty) {
      return _buildAssetImage('imgasest/brhomescreen .png');
    }

    // Auto-detect web image URLs (http://, https://, or domain-like strings)
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _buildNetworkImage(raw);
    } else if (raw.contains('.') && !raw.startsWith('imgasest/') && !raw.startsWith('assets/')) {
      return _buildNetworkImage('https://$raw');
    }

    // Local asset path
    return _buildAssetImage(raw);
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          width: width,
          color: const Color(0xFF0F172A),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFF59E0B)),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[MatchBannerImage] Network image failed to load: $url');
        return _buildAssetImage('imgasest/cshomescreen.png');
      },
    );
  }

  Widget _buildAssetImage(String assetPath) {
    String normalized = assetPath.trim();
    if (normalized == 'imgasest/brhomescreen.png' || normalized == 'imgasest/solobrfullmap.png') {
      normalized = 'imgasest/brhomescreen .png';
    }

    return Image.asset(
      normalized,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'imgasest/cshomescreen.png',
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height,
            width: width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.sports_esports, size: 48, color: Color(0xFFF59E0B)),
            ),
          ),
        );
      },
    );
  }
}
