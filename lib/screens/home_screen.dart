import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../services/ad_service.dart';
import '../utils/url_launcher_util.dart';
import '../widgets/booyah_header.dart';
import '../widgets/booyah_footer.dart';
import 'tournament_lobby_screen.dart';
import 'my_matches_screen.dart';
import 'weekly_leaderboard_screen.dart';
import 'earn_coins_screen.dart';
import 'wallet_screen.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasShownUpdateDialog = false;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_checkAppUpdateRequired);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppUpdateRequired();
    });
  }

  @override
  void dispose() {
    widget.appState.removeListener(_checkAppUpdateRequired);
    super.dispose();
  }

  void _checkAppUpdateRequired() {
    if (!mounted || _hasShownUpdateDialog) return;
    if (widget.appState.isUpdateRequired) {
      _hasShownUpdateDialog = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.system_update, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.appState.updateTitle,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appState.updateMessage,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Version: v${AppState.currentAppVersion}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Latest: v${widget.appState.minAppVersion}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () {
                  UrlLauncherUtil.openUrl(widget.appState.playStoreUrl);
                },
                icon: const Icon(Icons.shop, size: 20),
                label: const Text(
                  'UPDATE FROM PLAY STORE',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _handleTabChange(int index) {
    if (_currentIndex != index) {
      AdService.showInterstitialAd(context: context);
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.appState.user.role == 'admin' || AuthService.isAdminIdentifier(widget.appState.user.email, widget.appState.user.uid);

    final List<Widget> screens = [
      TournamentLobbyScreen(
        appState: widget.appState,
        onEarnCoinsClick: () => _handleTabChange(3),
        onTabChange: (tab) => _handleTabChange(tab),
      ),
      MyMatchesScreen(
        appState: widget.appState,
        onBrowseMatches: () => _handleTabChange(0),
      ),
      WeeklyLeaderboardScreen(
        appState: widget.appState,
        onBrowseTournaments: () => _handleTabChange(0),
      ),
      EarnCoinsScreen(appState: widget.appState),
      WalletScreen(
        appState: widget.appState,
        onGoToStore: () => _handleTabChange(3),
      ),
      if (isAdmin) AdminPanelScreen(appState: widget.appState),
      ProfileScreen(appState: widget.appState),
    ];

    return Scaffold(
      appBar: BooyahHeader(
        appState: widget.appState,
        onTabChange: (index) => _handleTabChange(index),
      ),
      body: SafeArea(
        child: screens[_currentIndex < screens.length ? _currentIndex : 0],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < screens.length ? _currentIndex : 0,
        onTap: (index) => _handleTabChange(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9.5),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: 'Matches',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: 'My Matches',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: '🏆 Ranks',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.stars),
            label: 'Earn/Store',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: widget.appState.isRealCashModeEnabled ? 'Wallet' : 'Wallet',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.shield),
              label: 'Admin',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
