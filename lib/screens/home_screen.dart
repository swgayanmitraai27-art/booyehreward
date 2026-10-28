import 'dart:convert';
import 'package:http/http.dart' as http;
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
      await widget.appState.fetchAppConfig();
      if (!mounted) return;

      // 1. Check for Admin Startup Popup Event Banner FIRST
      final banner = widget.appState.appSettings?['popupBanner'];
      if (banner != null && banner['enabled'] == true && (banner['imageUrl'] as String? ?? '').isNotEmpty) {
        _showPopupEventBannerDialog(banner);
        return;
      }

      // 2. If no popup banner, check if user needs to see the tutorial video guide
      final prefs = await SharedPreferences.getInstance();
      final hasSeenGuide = prefs.getBool('has_seen_esports_tutorial_v1') ?? false;
      if (!hasSeenGuide) {
        await _showHowToPlayVideoGuideDialog();
        await prefs.setBool('has_seen_esports_tutorial_v1', true);
      }
    } catch (e) {
      debugPrint('Startup popup error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBroadcastNotifications() async {
    try {
      final res = await http.get(Uri.parse('https://vps.swgayanbhumi.in/api/notifications'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['notifications'] is List) {
          return List<Map<String, dynamic>>.from(data['notifications']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
    return [];
  }

  void _showInAppNotificationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.cyanAccent, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: AppTheme.cyanAccent, size: 26),
            const SizedBox(width: 8),
            Text('सूचनाएं (Notifications)', style: AppTheme.gamingTitle(fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchBroadcastNotifications(),
            builder: (context, snapshot) {
              final notifs = snapshot.data ?? [];
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notifs.isNotEmpty) ...[
                      Text(
                        '📢 लाइव ब्रॉडकास्ट संदेश:',
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...notifs.map((n) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n['title'] ?? 'सूचना',
                              style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              n['message'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                    ],

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.appState.tournamentNotice,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.cyanAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.security, color: AppTheme.cyanAccent, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '🛡️ फेयर प्ले पॉलिसी: मैच शुरू होने से 15 मिनट पहले रूम आईडी व पासवर्ड चेक करें। हैक या चीटिंग पूरी तरह प्रतिबंधित है।',
                              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ठीक है (OK)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
            titleSpacing: 10,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/imgasest/free_fire_india_logo.png',
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/imgasest/booyah_hero_logo.png',
                      height: 28,
                      width: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BOOYAH REWARDS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rajdhani(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                      Text(
                        '🔥 Free Fire India Esports',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          letterSpacing: 0.3,
                          color: AppTheme.cyanAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // 💰 Wallet Coins Chip (1-Click Open Wallet)
              Center(
                child: InkWell(
                  onTap: () {
                    setState(() => _currentIndex = 3); // Switch to Wallet
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: AppTheme.primaryGold, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          '${user.adCoins}',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.add_circle, color: AppTheme.successGreen, size: 13),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 2),

              // 🔔 In-App Announcements / Notifications
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                icon: const Icon(Icons.notifications_active_outlined, color: AppTheme.cyanAccent, size: 22),
                tooltip: 'सूचनाएं (Notifications)',
                onPressed: _showInAppNotificationsDialog,
              ),

              // ⋯ More Menu (YouTube Guide, Play Zone, Leaderboard, Support)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70, size: 22),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                color: AppTheme.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                onSelected: (value) {
                  if (value == 'youtube') {
                    _showHowToPlayVideoGuideDialog();
                  } else if (value == 'playzone') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlayZoneScreen(appState: widget.appState)),
                    );
                  } else if (value == 'leaderboard') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LeaderboardScreen(appState: widget.appState)),
                    );
                  } else if (value == 'support') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SupportScreen(appState: widget.appState)),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'youtube',
                    child: Row(
                      children: [
                        const Icon(Icons.smart_display, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Text('वीडियो गाइड (How to Play)', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'playzone',
                    child: Row(
                      children: [
                        const Icon(Icons.sports_esports, color: Color(0xFFA855F7), size: 20),
                        const SizedBox(width: 10),
                        Text('प्ले ज़ोन (Play Zone)', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'leaderboard',
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 20),
                        const SizedBox(width: 10),
                        Text('लीडरबोर्ड (Leaderboard)', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'support',
                    child: Row(
                      children: [
                        const Icon(Icons.headset_mic, color: AppTheme.cyanAccent, size: 20),
                        const SizedBox(width: 10),
                        Text('सपोर्ट (Support)', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
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
