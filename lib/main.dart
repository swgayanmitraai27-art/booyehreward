import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/app_state.dart';
import 'services/local_notification_service.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sound Service
  await SoundService.init();

  // Initialize Local Notifications
  await LocalNotificationService.initialize();

  // Initialize Firebase (mobile only, handle errors gracefully)
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init handled gracefully: $e');
    }
  }

  // Initialize AdMob
  await AdService.initialize();

  // Create AppState
  final appState = AppState();

  runApp(ArenaRewardsApp(appState: appState));
}

class ArenaRewardsApp extends StatelessWidget {
  final AppState appState;

  const ArenaRewardsApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Free Fire India - Booyah Rewards',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: SplashScreen(appState: appState),
    );
  }
}
