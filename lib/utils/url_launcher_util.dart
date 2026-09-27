import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe' as js_util;

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

    if (kIsWeb) {
      try {
        final global = js.globalContext;
        global.callMethod('open'.toJS, url.toJS, '_blank'.toJS);
      } catch (e) {
        debugPrint('[UrlLauncherUtil] Error opening URL on Web: $e');
      }
    } else {
      try {
        final uri = Uri.parse(url);
        await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('[UrlLauncherUtil] Error launching URL on Android: $e');
      }
    }
  }
}
