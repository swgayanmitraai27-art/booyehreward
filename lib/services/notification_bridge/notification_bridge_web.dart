import 'dart:js_interop' as js_interop;
import 'dart:js_interop_unsafe' as js_util;
import 'package:flutter/foundation.dart';

Future<String> getBrowserNotificationPermissionStatus() async {
  try {
    final global = js_interop.globalContext;
    if (global.has('getNotificationPermissionStatus')) {
      final jsVal = global.callMethod('getNotificationPermissionStatus'.toJS);
      return (jsVal as js_interop.JSString?)?.toDart ?? 'default';
    }
  } catch (e) {
    debugPrint('[NotificationBridgeWeb] Error getting permission status: $e');
  }
  return 'default';
}

Future<String> requestBrowserNotificationPermission() async {
  try {
    final global = js_interop.globalContext;
    if (global.has('requestNotificationPermission')) {
      final jsPromise = global.callMethod('requestNotificationPermission'.toJS);
      final result = await (jsPromise as js_interop.JSPromise).toDart;
      return (result as js_interop.JSString?)?.toDart ?? 'granted';
    }
  } catch (e) {
    debugPrint('[NotificationBridgeWeb] Error requesting permission: $e');
  }
  return 'error';
}

void showBrowserNotification(String title, String body, {String? imageUrl, String? url}) {
  try {
    final global = js_interop.globalContext;
    if (global.has('showWebNotification')) {
      global.callMethod(
        'showWebNotification'.toJS,
        title.toJS,
        body.toJS,
        (imageUrl ?? 'https://booyehreward.vercel.app/booyah_logo.png').toJS,
        (url ?? '').toJS,
      );
    }
  } catch (e) {
    debugPrint('[NotificationBridgeWeb] Error showing web notification: $e');
  }
}
