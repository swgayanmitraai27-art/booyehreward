import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/ad_service.dart';
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

  void _handleTabChange(int index) {
    if (_currentIndex != index) {
      AdService.showInterstitialAd(context: context);
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.appState.user.role == 'admin';

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
        child: SingleChildScrollView(
          child: Column(
            children: [
              screens[_currentIndex < screens.length ? _currentIndex : 0],
              const BooyahFooter(),
            ],
          ),
        ),
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
