import 'package:http/http.dart' as http;

/// Auto-resolves image URLs from image hosting providers
/// like ImgBB (ibb.co), PostImages, Google Drive, Imgur, Dropbox to their direct .png/.jpg stream.
class ImageUrlResolver {
  static final Map<String, String> _resolvedCache = {};

  static String sanitizeUrl(String rawUrl) {
    String url = rawUrl.trim().replaceAll('"', '').replaceAll("'", '');
    if (url.isEmpty) return url;

    // HTML embed snippet (e.g. <img src="https://i.ibb.co/..." />)
    if (url.contains('<img') || url.contains('src=')) {
      final reg = RegExp(r'src=["\x27]?([^"\x27\s>]+)["\x27]?');
      final match = reg.firstMatch(url);
      if (match != null) {
        url = match.group(1)!;
      }
    }

    // BBCode embed snippet (e.g. [img]https://i.ibb.co/...[/img])
    if (url.contains('[img]') || url.contains('[/img]')) {
      final reg = RegExp(r'\[img\](.*?)\[/img\]');
      final match = reg.firstMatch(url);
      if (match != null) {
        url = match.group(1)!;
      }
    }

    // Google Drive direct link conversion
    if (url.contains('drive.google.com/file/d/')) {
      final reg = RegExp(r'/d/([a-zA-Z0-9_-]+)');
      final match = reg.firstMatch(url);
      if (match != null) {
        return 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
      }
    }

    // Dropbox direct link conversion
    if (url.contains('dropbox.com') && url.contains('dl=0')) {
      return url.replaceAll('dl=0', 'raw=1');
    }

    // Imgur direct image conversion
    if (url.startsWith('https://imgur.com/') && !url.endsWith('.png') && !url.endsWith('.jpg') && !url.endsWith('.jpeg')) {
      final id = url.split('/').last;
      return 'https://i.imgur.com/$id.png';
    }

    return url;
  }

  static Future<String> resolveDirectImageUrl(String rawUrl) async {
    String url = sanitizeUrl(rawUrl);
    if (url.isEmpty) return url;

    if (_resolvedCache.containsKey(url)) {
      return _resolvedCache[url]!;
    }

    // ImgBB page URL (e.g. https://ibb.co/TxcKJDB2) -> fetch HTML & extract i.ibb.co direct image
    if (url.contains('ibb.co/') && !url.contains('i.ibb.co')) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          // 1. Check og:image meta tag
          final ogRegex = RegExp(r'<meta property="og:image" content="([^"]+)"');
          final ogMatch = ogRegex.firstMatch(response.body);
          if (ogMatch != null) {
            final direct = ogMatch.group(1)!;
            _resolvedCache[url] = direct;
            return direct;
          }

          // 2. Search for direct i.ibb.co image URL
          final directRegex = RegExp(r'https://i\.ibb\.co/[a-zA-Z0-9_/-]+\.(?:png|jpg|jpeg|webp)');
          final directMatch = directRegex.firstMatch(response.body);
          if (directMatch != null) {
            final direct = directMatch.group(0)!;
            _resolvedCache[url] = direct;
            return direct;
          }
        }
      } catch (e) {
        // Continue with original
      }
    }

    // Postimages page (e.g. https://postimg.cc/xyz)
    if (url.contains('postimg.cc/') && !url.contains('i.postimg.cc')) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final ogRegex = RegExp(r'<meta property="og:image" content="([^"]+)"');
          final ogMatch = ogRegex.firstMatch(response.body);
          if (ogMatch != null) {
            final direct = ogMatch.group(1)!;
            _resolvedCache[url] = direct;
            return direct;
          }
        }
      } catch (e) {
        // Fallback to url
      }
    }

    _resolvedCache[url] = url;
    return url;
  }
}
