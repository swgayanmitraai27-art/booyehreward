import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/match_model.dart';
import '../models/notification_model.dart';
import 'firebase_config.dart';
import 'firestore_rest_service.dart';
import 'notification_bridge/notification_bridge.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Stored FCM Device Token
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Active Subscribed Topics
  final Set<String> _subscribedTopics = {'all_users'};

  // In-App Notification Stream
  final StreamController<AppNotification> _notificationStreamController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get onNotificationReceived => _notificationStreamController.stream;

  // Local Notifications Plugin for Android foreground alerts
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Booyah Rewards Alerts',
    description: 'Notifications for match updates, room credentials, and prize rewards.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _isInitialized = false;

  /// Initialize Push Notification Service for Web and Native Android/iOS
  Future<void> initialize({String? userId}) async {
    if (_isInitialized && userId == null) return;
    _isInitialized = true;

    debugPrint('🔔 [NotificationService] Initializing Push Notifications & FCM System...');

    // 1. Web Platform Notification Permission & FCM
    if (kIsWeb) {
      try {
        final permStatus = await requestBrowserNotificationPermission();
        debugPrint('🔔 [NotificationService] Web Notification Permission status: $permStatus');
      } catch (e) {
        debugPrint('⚠️ [NotificationService] Web permission request notice: $e');
      }
    } else {
      // 2. Mobile Android / iOS FCM & Local Notification Channel Setup
      try {
        // Initialize Local Notifications
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initializationSettings =
            InitializationSettings(android: initializationSettingsAndroid);

        await _localNotifications.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            debugPrint('🔔 [LocalNotification] Clicked with payload: ${response.payload}');
          },
        );

        // Create Android High Importance Channel
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await androidImpl.createNotificationChannel(_androidChannel);
          await androidImpl.requestNotificationsPermission();
        }

        // Request FCM Permissions
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint('🔔 [FCM] Notification authorization status: ${settings.authorizationStatus}');

        // Set foreground presentation options
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Fetch & Store FCM Device Token
        _fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('📱 [FCM] Device Token: $_fcmToken');

        // Handle foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('🔔 [FCM Foreground] Received: ${message.notification?.title} | ${message.notification?.body}');
          
          final notification = message.notification;
          if (notification != null) {
            _localNotifications.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  _androidChannel.id,
                  _androidChannel.name,
                  channelDescription: _androidChannel.description,
                  importance: Importance.max,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                  playSound: true,
                  enableVibration: true,
                ),
              ),
              payload: jsonEncode(message.data),
            );
          }

          final appNotif = AppNotification(
            id: message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
            title: notification?.title ?? 'Notification',
            body: notification?.body ?? '',
            type: NotificationType.systemAlert,
            targetType: 'all',
            createdAt: DateTime.now(),
            data: message.data,
          );
          _notificationStreamController.add(appNotif);
        });

        // Handle notification click when app opens from background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('🔔 [FCM] App opened from push notification: ${message.data}');
        });

      } catch (e) {
        debugPrint('⚠️ [NotificationService] Mobile FCM Setup Exception: $e');
      }
    }

    // Subscribe to global announcements topic
    await subscribeToTopic('all_users');

    if (userId != null && userId.isNotEmpty) {
      await subscribeToTopic('user_$userId');
    }
  }

  /// Explicitly request notification permission (can be called from UI buttons / settings)
  Future<String> requestPermission() async {
    if (kIsWeb) {
      return await requestBrowserNotificationPermission();
    } else {
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized ? 'granted' : 'denied';
      } catch (e) {
        return 'granted';
      }
    }
  }

  /// Get current browser / mobile permission status
  Future<String> getPermissionStatus() async {
    if (kIsWeb) {
      return await getBrowserNotificationPermissionStatus();
    } else {
      try {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized ? 'granted' : 'denied';
      } catch (e) {
        return 'granted';
      }
    }
  }

  /// Trigger a live test notification
  void triggerTestBrowserNotification() {
    if (kIsWeb) {
      showBrowserNotification(
        '🔥 Booyah Rewards Alert!',
        'Desktop & Browser Push Notifications are working perfectly! 🎮',
        imageUrl: 'https://booyehreward.vercel.app/booyah_logo.png',
      );
    } else {
      _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: '🔥 Booyah Rewards Alert!',
        body: 'Push notifications on Android are working perfectly! 🎮',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  /// Subscribe device to an FCM / In-App Topic (e.g. 'all_users', 'match_123', 'admin_alerts')
  Future<void> subscribeToTopic(String topic) async {
    _subscribedTopics.add(topic);
    if (!kIsWeb) {
      try {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
        debugPrint('🔔 [NotificationService] Subscribed native Android FCM to topic: $topic');
      } catch (e) {
        debugPrint('⚠️ [NotificationService] Native FCM topic subscribe error: $e');
      }
    } else {
      debugPrint('🔔 [NotificationService] Subscribed to topic: $topic');
    }
  }

  /// Unsubscribe from a Topic
  Future<void> unsubscribeFromTopic(String topic) async {
    _subscribedTopics.remove(topic);
    if (!kIsWeb) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        debugPrint('🔔 [NotificationService] Unsubscribed native Android FCM from topic: $topic');
      } catch (e) {
        debugPrint('⚠️ [NotificationService] Native FCM topic unsubscribe error: $e');
      }
    } else {
      debugPrint('🔔 [NotificationService] Unsubscribed from topic: $topic');
    }
  }

  /// Trigger Dynamic Auto-Start Alerts when a Match is 100% FULL
  Future<void> triggerMatchFullAutoAlert({required MatchModel match}) async {
    final now = DateTime.now();
    final matchId = match.id;
    final matchTitle = match.title;

    debugPrint('⚡ [Auto-Start Engine] Match $matchId ($matchTitle) is 100% FULL! Dispatching notifications...');

    // 1. Participant Alert
    final playerNotif = AppNotification(
      id: 'notif_full_${matchId}_${now.millisecondsSinceEpoch}',
      title: '🚨 MATCH IS FULL! ($matchTitle)',
      body: 'Your Match is FULL! The Room ID and Password will be provided in exactly 15 minutes. Open the app now!',
      type: NotificationType.matchFull,
      targetType: 'match',
      targetId: matchId,
      matchId: matchId,
      createdAt: now,
      data: {
        'matchId': matchId,
        'action': 'OPEN_MATCH_LOBBY',
        'countdownMinutes': 15,
      },
    );

    // 2. Admin Alert
    final adminNotif = AppNotification(
      id: 'admin_alert_${matchId}_${now.millisecondsSinceEpoch}',
      title: '🔥 ADMIN ALERT: Match Full Guaranteed Profit!',
      body: 'Match [$matchTitle] ($matchId) is 100% full. Please create the custom room and enter the Room ID within 15 minutes.',
      type: NotificationType.systemAlert,
      targetType: 'admin',
      targetId: 'admin_alerts',
      matchId: matchId,
      createdAt: now,
      data: {
        'matchId': matchId,
        'action': 'OPEN_ROOM_PUBLISHER',
        'urgency': 'HIGH',
      },
    );

    // Broadcast locally to in-app stream & web browser notification
    _notificationStreamController.add(playerNotif);
    _notificationStreamController.add(adminNotif);

    if (kIsWeb) {
      showBrowserNotification(playerNotif.title, playerNotif.body);
    }

    // Persist notifications to Firestore and dispatch FCM push
    await Future.wait([
      _saveNotificationToFirestore(playerNotif),
      _saveNotificationToFirestore(adminNotif),
      _dispatchPushNotification(
        topic: 'match_$matchId',
        title: playerNotif.title,
        body: playerNotif.body,
        data: playerNotif.data,
      ),
      _dispatchPushNotification(
        topic: 'admin_alerts',
        title: adminNotif.title,
        body: adminNotif.body,
        data: adminNotif.data,
      ),
    ]);
  }

  /// Admin Manual Broadcast to All Users
  Future<bool> sendBroadcastAnnouncement({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    final now = DateTime.now();
    final notif = AppNotification(
      id: 'broadcast_${now.millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.adminBroadcast,
      targetType: 'all',
      createdAt: now,
      imageUrl: imageUrl,
    );

    _notificationStreamController.add(notif);
    if (kIsWeb) {
      showBrowserNotification(title, body, imageUrl: imageUrl);
    }

    await _saveNotificationToFirestore(notif);
    return await _dispatchPushNotification(
      topic: 'all_users',
      title: title,
      body: body,
      imageUrl: imageUrl,
    );
  }

  /// Admin Notification to Specific Match Participants (e.g. Room ID Published)
  Future<bool> sendMatchAlert({
    required String matchId,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    final notif = AppNotification(
      id: 'match_notif_${matchId}_${now.millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.roomCredentials,
      targetType: 'match',
      targetId: matchId,
      matchId: matchId,
      createdAt: now,
    );

    _notificationStreamController.add(notif);
    if (kIsWeb) {
      showBrowserNotification(title, body);
    }

    await _saveNotificationToFirestore(notif);
    return await _dispatchPushNotification(
      topic: 'match_$matchId',
      title: title,
      body: body,
      data: {'matchId': matchId},
    );
  }

  /// Send Targeted Notification to a Single User (e.g. Withdrawal Approved, Deposit Added)
  Future<bool> sendPersonalNotification({
    required String userId,
    required String title,
    required String body,
    NotificationType type = NotificationType.systemAlert,
  }) async {
    final now = DateTime.now();
    final notif = AppNotification(
      id: 'user_notif_${userId}_${now.millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      targetType: 'user',
      targetId: userId,
      createdAt: now,
    );

    _notificationStreamController.add(notif);
    if (kIsWeb) {
      showBrowserNotification(title, body);
    }

    await _saveNotificationToFirestore(notif);
    return await _dispatchPushNotification(
      topic: 'user_$userId',
      title: title,
      body: body,
      data: {'userId': userId},
    );
  }

  /// Save notification record into Firestore collection 'skillwinner_notifications'
  Future<void> _saveNotificationToFirestore(AppNotification notification) async {
    try {
      await FirestoreRestService.setDocument(
        'skillwinner_notifications',
        notification.id,
        notification.toJson(),
      );
    } catch (e) {
      debugPrint('⚠️ Error saving notification to Firestore: $e');
    }
  }

  /// Dispatch FCM push notification via backend API endpoint (https://www.swgayanbhumi.in/api/push-notification)
  Future<bool> _dispatchPushNotification({
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final payload = {
        'topic': topic,
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'status': 'done',
          ...?data,
        },
      };

      final response = await http.post(
        Uri.parse(FirebaseConfig.pushNotificationEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        return http.Response('{"status":"timeout"}', 408);
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ FCM Push Notification dispatched successfully to topic: $topic');
        return true;
      } else {
        debugPrint('ℹ️ FCM Push endpoint status: ${response.statusCode} (body: ${response.body})');
        return response.statusCode < 400;
      }
    } catch (e) {
      debugPrint('⚠️ Push notification dispatch caught exception: $e (In-App notifications active)');
      return false;
    }
  }

  void dispose() {
    _notificationStreamController.close();
  }
}
