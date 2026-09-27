import 'package:flutter/material.dart';
import '../utils/image_url_resolver.dart';

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
    String raw = ImageUrlResolver.sanitizeUrl(bannerImage ?? '');

    // If empty, use default BR banner
    if (raw.isEmpty) {
      return _buildAssetImage('imgasest/brhomescreen .png');
    }

    // Auto-detect web image URLs (http://, https://, ibb.co, etc.)
    if (raw.startsWith('http://') || raw.startsWith('https://') || (raw.contains('.') && !raw.startsWith('imgasest/'))) {
      String initialUrl = raw.startsWith('http') ? raw : 'https://$raw';

      // If it's a page link like ibb.co/xyz or postimg.cc/xyz, resolve to direct stream
      if (initialUrl.contains('ibb.co/') && !initialUrl.contains('i.ibb.co')) {
        return FutureBuilder<String>(
          future: ImageUrlResolver.resolveDirectImageUrl(initialUrl),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
              return _buildNetworkImage(snapshot.data!);
            }
            return _buildNetworkImage(initialUrl);
          },
        );
      }

      return _buildNetworkImage(initialUrl);
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
