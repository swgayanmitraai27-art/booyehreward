import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'play_zone_screen.dart';

class DailyTasksScreen extends StatefulWidget {
  final AppState appState;

  const DailyTasksScreen({super.key, required this.appState});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  bool _isClaiming = false;

  void _claimStreak() async {
    setState(() => _isClaiming = true);
    final res = await widget.appState.claimDailyStreak();
    if (!mounted) return;
    setState(() => _isClaiming = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: res['success'] == true ? AppTheme.successGreen : AppTheme.saffronOrange,
            width: 2,
          ),
        ),
        title: Text(
          res['success'] == true ? '🎉 STREAK CLAIMED!' : 'NOTICE',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            color: res['success'] == true ? AppTheme.successGreen : AppTheme.saffronOrange,
          ),
        ),
        content: Text(res['message'] ?? ''),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _watchAdForCoins() {
    final messenger = ScaffoldMessenger.of(context);
    AdService.showRewardedAd(
      context: context,
      onRewarded: () async {
        final res = await widget.appState.watchAdEarnCoins();
        if (res['success'] == true) {
          messenger.showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.successGreen,
              content: Text('🎉 +${res['coinsEarned']} Coins credited to your wallet!'),
            ),
          );
        }
      },
    );
  }

  Future<void> _shareTournamentOnWhatsApp() async {
    final messenger = ScaffoldMessenger.of(context);
    final text = '🔥 Free Fire India Esports Tournament App! 100% Free Entry custom rooms mein khelo aur Google Play Redeem Codes jeeto! Download now & use my referral code: ${widget.appState.user.referralCode} for +10 Bonus Coins! 🚀';
    final url = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: text));
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
    }
    // Instant callback reward (+5 coins)
    widget.appState.addWalletCoins(5);
    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.successGreen,
        content: Text('🎉 +5 Coins awarded for sharing with friends!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final user = widget.appState.user;
        final streak = user.streakDays;
        final todayStr = DateTime.now().toIso8601String().split('T')[0];
        final isClaimedToday = user.lastCheckInDate.startsWith(todayStr);

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // ── 1. 7-DAY STREAK CARD ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primaryGold, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: AppTheme.saffronOrange, size: 26),
                            const SizedBox(width: 6),
                            Text(
                              '7-DAY LOGIN STREAK',
                              style: GoogleFonts.rajdhani(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'DAY $streak / 7',
                            style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Open the app every day to claim bonus coins. Day 7 gives a 50 Coins Jackpot!',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // Day 1 to 7 Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final dayNum = i + 1;
                        final isPastOrCurrent = dayNum <= streak;
                        final isJackpot = dayNum == 7;
                        final coinRewards = [5, 10, 15, 20, 25, 30, 50];

                        return Container(
                          width: 40,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isPastOrCurrent
                                ? (isJackpot ? AppTheme.primaryGold : AppTheme.successGreen.withValues(alpha: 0.2))
                                : AppTheme.bgCardLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isPastOrCurrent
                                  ? (isJackpot ? AppTheme.primaryGold : AppTheme.successGreen)
                                  : Colors.white12,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'D$dayNum',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isJackpot && isPastOrCurrent ? Colors.black : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                isJackpot ? Icons.military_tech : Icons.monetization_on,
                                size: 16,
                                color: isJackpot && isPastOrCurrent ? Colors.black : AppTheme.primaryGold,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+${coinRewards[i]}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isJackpot && isPastOrCurrent ? Colors.black : AppTheme.primaryGold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Claim Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isClaimedToday ? Colors.white12 : AppTheme.primaryGold,
                          foregroundColor: isClaimedToday ? Colors.white54 : Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isClaimedToday || _isClaiming ? null : _claimStreak,
                        child: Text(
                          isClaimedToday ? '✓ CLAIMED TODAY (COME BACK TOMORROW)' : 'CLAIM TODAY\'S STREAK REWARD',
                          style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── 🎮 ARCADE PLAY ZONE (GAME KHELKAR COINS KAMAYEIN) ──
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayZoneScreen(appState: widget.appState)),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF311042), Color(0xFF1E1B4B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFA855F7)),
                        ),
                        child: const Icon(Icons.sports_esports, color: Color(0xFFA855F7), size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '🎮 आर्केड प्ले ज़ोन',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGold,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('HOT', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'मिनी-गेम्स खेलें और कॉइन्स कमाएं (मैक्स 3 कॉइन/गेम, नो डेली लिमिट)',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFFA855F7), size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── 2. WATCH & EARN COINS (INSTANT REWARD) ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14532D), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.successGreen, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.successGreen),
                      ),
                      child: const Icon(Icons.play_circle_filled, color: AppTheme.successGreen, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WATCH VIDEO AD',
                            style: GoogleFonts.rajdhani(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Watch 1 short video & get +10 Coins immediately to enter tournaments!',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _watchAdForCoins,
                      child: Text(
                        '+10 COINS',
                        style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 3. DAILY ENGAGEMENT QUESTS ──
              Text(
                'DAILY ENGAGEMENT QUESTS',
                style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
              ),
              const SizedBox(height: 10),

              _buildQuestCard(
                title: 'Share Poster on WhatsApp',
                reward: '+5 Coins',
                desc: 'Invite your Free Fire squad on WhatsApp group',
                icon: Icons.share,
                actionLabel: 'SHARE',
                onAction: _shareTournamentOnWhatsApp,
              ),
              _buildQuestCard(
                title: 'Play 1 Tournament Match',
                reward: '+15 Coins',
                desc: 'Register and enter any custom room today',
                icon: Icons.sports_esports,
                actionLabel: 'PLAY',
                onAction: () => DefaultTabController.of(context).animateTo(0),
              ),
              _buildQuestCard(
                title: 'Chat in World Lounge',
                reward: '+5 Coins',
                desc: 'Post a squad code or say hi in World Chat',
                icon: Icons.chat_bubble,
                actionLabel: 'CHAT',
                onAction: () => DefaultTabController.of(context).animateTo(1),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestCard({
    required String title,
    required String reward,
    required String desc,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: AppTheme.primaryGold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(reward, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bgCardLight,
              foregroundColor: AppTheme.primaryGold,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onAction,
            child: Text(actionLabel, style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
