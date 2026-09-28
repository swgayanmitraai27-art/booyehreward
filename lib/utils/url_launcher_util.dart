import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class UrlLauncherUtil {
  static Future<void> openUrl(String rawUrl) async {
    if (rawUrl.isEmpty) return;
    String url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('@')) {
        url = 'https://t.me/${url.substring(1)}';
      } else if (!url.contains('/') && !url.contains('.')) {
        url = 'https://t.me/$url';
      } else {
        url = 'https://$url';
      }
    }

    try {
      final uri = Uri.parse(url);
      await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[UrlLauncherUtil] Error launching URL: $e');
    }
  }
}

