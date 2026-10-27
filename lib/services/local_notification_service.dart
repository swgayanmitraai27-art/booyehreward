import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        // Fallback if Asia/Kolkata not found
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(settings: initializationSettings);
      _initialized = true;

      // Request permission on Android 13+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Schedule background notifications for when the app is closed
      await scheduleBackgroundNotifications();
    } catch (e) {
      debugPrint('Local notifications init handled gracefully: $e');
    }
  }

  /// Schedule background notifications that trigger even when the app is completely closed
  static Future<void> scheduleBackgroundNotifications() async {
    if (kIsWeb || !_initialized) return;

    try {
      const AndroidNotificationDetails channelDetails = AndroidNotificationDetails(
        'arena_tournament_alerts',
        'टूर्नामेंट व दैनिक इनाम अलर्ट',
        channelDescription: 'दैनिक ₹1,000 टूर्नामेंट, फ्री स्पिन व स्क्रैच कार्ड सूचनाएं',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      final now = tz.TZDateTime.now(tz.local);

      // 1. After 2 Hours of inactivity (Background reminder)
      await _notificationsPlugin.zonedSchedule(
        id: 301,
        title: '🔥 Free Fire Custom Room Slot Waiting!',
        body: 'Rozana free tournaments khelo aur Booyah karke Google Play Redeem Codes jeeto! Join now!',
        scheduledDate: now.add(const Duration(hours: 2)),
        notificationDetails: const NotificationDetails(android: channelDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      // 2. After 5 Hours of inactivity
      await _notificationsPlugin.zonedSchedule(
        id: 302,
        title: '⚡ Daily Login Bonus Ready!',
        body: 'Apna 7-Day Check-in Streak claim karo aur +10 to +50 Free Coins pao!',
        scheduledDate: now.add(const Duration(hours: 5)),
        notificationDetails: const NotificationDetails(android: channelDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      // 3. Daily Morning Reminder at 9:00 AM IST
      await _notificationsPlugin.zonedSchedule(
        id: 201,
        title: '☀️ Free Fire India Morning Cups Live!',
        body: 'Bermuda Solo & Clash Squad matches open hain! Apna slot reserve karein.',
        scheduledDate: _nextInstanceOfTime(9, 0),
        notificationDetails: const NotificationDetails(android: channelDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // 4. Daily Evening Reminder at 7:30 PM IST (Evening Rush)
      await _notificationsPlugin.zonedSchedule(
        id: 202,
        title: '🏆 Mega Tournament Tonight!',
        body: 'Aaj raat ka Mega Cup room shuru hone wala hai! Room ID & Password check karein!',
        scheduledDate: _nextInstanceOfTime(19, 30),
        notificationDetails: const NotificationDetails(android: channelDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Background notifications scheduled successfully.');
    } catch (e) {
      debugPrint('Schedule notifications error: $e');
    }
  }

  /// Show an immediate notification (for FCM messages and live match room alerts)
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'ff_live_alerts',
        'Free Fire Live Match Alerts',
        channelDescription: 'Custom Room credentials and match start notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Show notification error: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
