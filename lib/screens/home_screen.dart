import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import 'daily_tasks_screen.dart';
import 'leaderboard_screen.dart';
import 'play_zone_screen.dart';
import 'profile_screen.dart';
import 'support_screen.dart';
import 'tournament_lobby_screen.dart';
import 'wallet_screen.dart';
import 'world_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  bool _hasCheckedPopups = false;

  @override
  void initState() {
    super.initState();
    _screens = [
      TournamentLobbyScreen(appState: widget.appState),
      WorldChatScreen(appState: widget.appState),
      DailyTasksScreen(appState: widget.appState),
      WalletScreen(appState: widget.appState),
      ProfileScreen(appState: widget.appState),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedPopups) {
        _hasCheckedPopups = true;
        _checkAndShowStartupPopups();
      }
    });
  }

  Future<void> _checkAndShowStartupPopups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenGuide = prefs.getBool('has_seen_esports_tutorial_v1') ?? false;

      if (!hasSeenGuide) {
        if (!mounted) return;
        await _showHowToPlayVideoGuideDialog();
        await prefs.setBool('has_seen_esports_tutorial_v1', true);
        return;
      }

      // If user has already seen guide, check for Admin Popup Event Banner
      final banner = widget.appState.appSettings?['popupBanner'];
      if (banner != null && banner['enabled'] == true && (banner['imageUrl'] as String? ?? '').isNotEmpty) {
        if (!mounted) return;
        _showPopupEventBannerDialog(banner);
      }
    } catch (e) {
      debugPrint('Startup popup error: $e');
    }
  }

  Future<void> _showHowToPlayVideoGuideDialog() async {
    final videoSettings = widget.appState.appSettings?['howToPlayVideo'] ?? {};
    final videoUrl = videoSettings['youtubeUrl'] ?? 'https://youtube.com/@booyahrewards';
    final videoTitle = videoSettings['title'] ?? 'फ्री फायर टूर्नामेंट कैसे खेलें और रिडीम कोड कैसे जीतें?';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.primaryGold, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.sports_esports, color: AppTheme.primaryGold, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'टूर्नामेंट गाइड व नियम',
                style: GoogleFonts.rajdhani(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                videoTitle,
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 🎬 Watch Video Tutorial Button
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(videoUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFE11D48).withValues(alpha: 0.4), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '▶️ वीडियो ट्यूटोरियल देखें',
                              style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const Text(
                              'YouTube पर 2 मिनट का पूरा गाइड देखें',
                              style: TextStyle(fontSize: 10.5, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text('4 आसान चरणों में खेलें और जीतें:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
              const SizedBox(height: 8),

              _buildGuideStep('1', 'फ्री कॉइन्स कमाएं', 'डेली चेक-इन और वीडियो एड्स देखकर टूर्नामेंट एंट्री के लिए कॉइन्स जमा करें।'),
              _buildGuideStep('2', 'मैच में स्लॉट बुक करें', 'अपना Free Fire इन-गेम नाम (IGN) और UID डालकर स्लॉट रिज़र्व करें।'),
              _buildGuideStep('3', 'रूम आईडी व पासवर्ड', 'मैच शुरू होने से 15 मिनट पहले ऐप में रूम आईडी व पासवर्ड मिलेगा।'),
              _buildGuideStep('4', 'Booyah करें व कैश निकालें', 'मैच जीतकर विनिंग कॉइन्स पाएं और सीधे Google Play कोड या UPI में लें!'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 44),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '🚀 समझ गया, खेलना शुरू करें!',
              style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppTheme.bgCard, shape: BoxShape.circle),
            child: Text(num, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPopupEventBannerDialog(Map<String, dynamic> banner) {
    final imgUrl = banner['imageUrl'] as String? ?? '';
    final actionUrl = banner['actionUrl'] as String? ?? '';
    final title = banner['title'] as String? ?? 'स्पेशल इवेंट अलर्ट!';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close X Button on top right
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: actionUrl.isNotEmpty
                    ? () async {
                        Navigator.pop(ctx);
                        final uri = Uri.parse(actionUrl);
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      }
                    : null,
                child: Stack(
                  children: [
                    Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(24),
                        color: AppTheme.bgCard,
                        child: Text(title, style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    if (actionUrl.isNotEmpty)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('🔥 अभी देखें ➜', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final user = widget.appState.user;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: AppTheme.bgDark,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/imgasest/booyah_hero_logo.png',
                    height: 32,
                    width: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.emoji_events,
                      size: 26,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BOOYAH REWARDS',
                      style: GoogleFonts.rajdhani(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                    Text(
                      'India Ka Apna Esports Platform',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 0.5,
                        color: AppTheme.cyanAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // 💰 Wallet Coins Chip (1-Click Open Wallet)
              InkWell(
                onTap: () {
                  setState(() => _currentIndex = 3); // Switch to Wallet
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: AppTheme.primaryGold, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        '${user.adCoins}',
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.add_circle, color: AppTheme.successGreen, size: 14),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // 🎮 Arcade Play Zone Icon (Direct 1-Click Game Launcher)
              IconButton(
                icon: const Icon(Icons.sports_esports, color: Color(0xFFA855F7), size: 24),
                tooltip: 'Play Zone',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayZoneScreen(appState: widget.appState)),
                  );
                },
              ),

              // 🏆 Esports Champions Leaderboard Icon
              IconButton(
                icon: const Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 24),
                tooltip: 'Champions Leaderboard',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LeaderboardScreen(appState: widget.appState)),
                  );
                },
              ),

              // 🎧 100% In-App Support Icon (Direct Help Desk)
              IconButton(
                icon: const Icon(Icons.headset_mic, color: AppTheme.cyanAccent, size: 24),
                tooltip: 'Customer Support',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SupportScreen(appState: widget.appState)),
                  );
                },
              ),

              const SizedBox(width: 6),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppTheme.bgDark,
              border: Border(top: BorderSide(color: Colors.white12, width: 0.8)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (_currentIndex != index) {
                  AdService.showInterstitialAd();
                }
                setState(() => _currentIndex = index);
              },
              backgroundColor: AppTheme.bgDark,
              selectedItemColor: AppTheme.primaryGold,
              unselectedItemColor: AppTheme.textMuted,
              selectedLabelStyle: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 10, fontWeight: FontWeight.w600),
              type: BottomNavigationBarType.fixed,
              elevation: 12,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_esports_outlined),
                  activeIcon: Icon(Icons.sports_esports),
                  label: 'टूर्नामेंट',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.forum_outlined),
                  activeIcon: Icon(Icons.forum),
                  label: 'वर्ल्ड चैट',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_fire_department_outlined),
                  activeIcon: Icon(Icons.local_fire_department),
                  label: 'डेली टास्क',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet),
                  label: 'वॉलेट',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'प्रोफाइल',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
