import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'local_notification_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Initialize Firebase Cloud Messaging & Request Notification Permission
  static Future<void> initialize({required String uid}) async {
    if (kIsWeb || _initialized) return;

    try {
      // 1. Request user permission for notifications (Android 13+ & iOS)
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission Status: ${settings.authorizationStatus}');

      // 2. Subscribe to broadcast topics
      await _messaging.subscribeToTopic('all_users');
      await _messaging.subscribeToTopic('ff_tournaments');
      debugPrint('FCM Subscribed to topics: all_users, ff_tournaments');

      // 3. Get FCM Device Token & register with backend
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Device Token: $token');
        await _registerTokenWithBackend(uid, token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _registerTokenWithBackend(uid, newToken);
      });

      // 4. Handle Foreground Messages (when app is open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Message received in foreground: ${message.notification?.title}');
        final title = message.notification?.title ?? message.data['title'] ?? 'Free Fire Alert';
        final body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';
        
        LocalNotificationService.showNotification(
          title: title,
          body: body,
          payload: jsonEncode(message.data),
        );
      });

      // 5. Handle Background Message clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification clicked to open app: ${message.data}');
      });

      _initialized = true;
    } catch (e) {
      debugPrint('FCM Init gracefully handled: $e');
    }
  }

  /// Register device token with VPS backend
  static Future<void> _registerTokenWithBackend(String uid, String token) async {
    try {
      final url = Uri.parse('https://vps.swgayanbhumi.in/api/user/fcm-token');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'token': token,
        }),
      );
      debugPrint('FCM Token successfully synced with VPS backend for user $uid');
    } catch (e) {
      debugPrint('Error syncing FCM token with VPS: $e');
    }
  }
}
