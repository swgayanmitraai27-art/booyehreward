import 'package:flutter/material.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
