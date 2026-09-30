import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/firebase_config.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          appId: FirebaseConfig.appId,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          projectId: FirebaseConfig.projectId,
          storageBucket: FirebaseConfig.storageBucket,
          authDomain: FirebaseConfig.authDomain,
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    debugPrint("🔔 [FCM Background] Remote message received: ${message.messageId} - ${message.notification?.title}");
  } catch (e) {
    debugPrint("⚠️ [FCM Background] Handler error: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          appId: FirebaseConfig.appId,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          projectId: FirebaseConfig.projectId,
          storageBucket: FirebaseConfig.storageBucket,
          authDomain: FirebaseConfig.authDomain,
        ),
      );
    } else {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    debugPrint("✅ [Firebase] Firebase Core & Messaging initialized successfully.");
  } catch (e) {
    debugPrint("⚠️ [Firebase] Initialization notice: $e");
  }

  await AdService.initialize();
  runApp(const BooyahRewardsApp());
}

class BooyahRewardsApp extends StatefulWidget {
  const BooyahRewardsApp({super.key});

  @override
  State<BooyahRewardsApp> createState() => _BooyahRewardsAppState();
}

class _BooyahRewardsAppState extends State<BooyahRewardsApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.addListener(_onStateChange);
  }

  void _onStateChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChange);
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booyah Rewards - Esports Tournaments (Free & Paid)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(appState: _appState),
    );
  }
}
