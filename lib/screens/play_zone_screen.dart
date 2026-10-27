import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ad_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'games/katana_hit_screen.dart';
import 'games/gloo_wall_runner_screen.dart';

class PlayZoneScreen extends StatefulWidget {
  final AppState appState;

  const PlayZoneScreen({super.key, required this.appState});

  @override
  State<PlayZoneScreen> createState() => _PlayZoneScreenState();
}

class _PlayZoneScreenState extends State<PlayZoneScreen> {
  int _cooldownRemaining = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _refreshStatus() async {
    final status = await widget.appState.fetchMiniGameStatus();
    if (!mounted) return;
    setState(() {
      _cooldownRemaining = (status['remainingSeconds'] as num?)?.toInt() ?? 0;
    });

    _startLocalCountdown();
  }

  void _startLocalCountdown() {
    _countdownTimer?.cancel();
    if (_cooldownRemaining > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_cooldownRemaining > 0) {
            _cooldownRemaining--;
          } else {
            timer.cancel();
          }
        });
      });
    }
  }

  void _openKatanaGame() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KatanaHitScreen(appState: widget.appState)),
    );
    _refreshStatus();
  }

  void _openGlooWallGame() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GlooWallRunnerScreen(appState: widget.appState)),
    );
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.appState.user;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.sports_esports, color: AppTheme.primaryGold, size: 24),
            const SizedBox(width: 8),
            Text(
              '🎮 आर्केड प्ले ज़ोन',
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
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
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshStatus(),
        color: AppTheme.primaryGold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.15), blurRadius: 16),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.videogame_asset, color: AppTheme.primaryGold, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'गेम खेलें और कॉइन्स कमाएं',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                '1 गेम = 1 बोनस कॉइन • 2X रिवॉर्ड • अनलिमिटेड प्ले',
                                style: TextStyle(fontSize: 11, color: AppTheme.cyanAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 60-Second Cooldown Live Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _cooldownRemaining > 0
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : AppTheme.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _cooldownRemaining > 0 ? const Color(0xFFF59E0B) : AppTheme.successGreen,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _cooldownRemaining > 0 ? Icons.timer_outlined : Icons.check_circle_outline,
                            color: _cooldownRemaining > 0 ? const Color(0xFFF59E0B) : AppTheme.successGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _cooldownRemaining > 0
                                  ? 'फुल स्क्रीन एड कूलडाउन: $_cooldownRemaining सेकंड बाकी'
                                  : '🟢 रेडी टू प्ले: अभी खेलें और कॉइन जीतें!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _cooldownRemaining > 0 ? const Color(0xFFF59E0B) : AppTheme.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── 🎬 DIRECT WATCH & EARN (BINA GAME KHELE DIRECT ADS SE COIN) ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.successGreen, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppTheme.successGreen.withValues(alpha: 0.15), blurRadius: 12),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.successGreen),
                      ),
                      child: const Icon(Icons.play_circle_fill, color: AppTheme.successGreen, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'सीधे वीडियो देखें और कॉइन पाएं',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('+10 COINS', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Text(
                            'बिना गेम खेले 30s वीडियो देखकर तुरंत +10 बोनस कॉइन्स पाएं!',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        AdService.showRewardedAd(
                          context: context,
                          onRewarded: () async {
                            final res = await widget.appState.watchAdEarnCoins();
                            if (res['success'] == true) {
                              messenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: AppTheme.successGreen,
                                  content: Text('🎉 +${res['coinsEarned']} Coins आपके वॉलेट में जुड़ गए!'),
                                ),
                              );
                            }
                          },
                        );
                      },
                      child: const Text('देखें ➜', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Game 1: Katana Hit
              _buildGameCard(
                title: '🔥 KATANA STRIKE (कटाना हिट)',
                subtitle: 'टारगेट पर फ्री फायर कटाना स्ट्राइक करें और कॉइन्स जीतें!',
                highScore: user.knifeHitHighScore,
                badgeText: 'POPULAR',
                badgeColor: const Color(0xFFE11D48),
                accentColor: AppTheme.primaryGold,
                iconData: Icons.gps_fixed,
                onTap: _openKatanaGame,
              ),

              const SizedBox(height: 16),

              // Game 2: Gloo Wall Runner
              _buildGameCard(
                title: '⚡ GLOO WALL RUSH (डैज रनर)',
                subtitle: 'लैंडमाइन्स से बचें, मेडकिट कलेक्ट करें और हाई स्कोर बनाएं!',
                highScore: user.gameScore,
                badgeText: 'NEW',
                badgeColor: AppTheme.cyanAccent,
                accentColor: AppTheme.cyanAccent,
                iconData: Icons.directions_run,
                onTap: _openGlooWallGame,
              ),

              const SizedBox(height: 22),

              // Rules & Profit-Safe Earning Guide
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'आर्केड ज़ोन नियम व कॉइन गाइड',
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildRuleRow('1.', '1 गेम सेशन पूरा करने पर आपको 1 बोनस कॉइन मिलता है।'),
                    _buildRuleRow('2.', 'गेम ओवर पर वीडियो देखकर आप 2X (डबल = 2 कॉइन्स) ले सकते हैं।'),
                    _buildRuleRow('3.', 'कम से कम 30 स्कोर बनाना ज़रूरी है।'),
                    _buildRuleRow('4.', 'एंटी-स्पैम सुरक्षा के लिए 60 सेकंड का कूलडाउन रहता है।'),
                    _buildRuleRow('5.', 'दिन में जितनी बार चाहें उतनी बार खेलें, कोई दैनिक लिमिट नहीं है!'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '💡 टिप: इन बोनस कॉइन्स से आप 100% फ्री में ₹500 तक के फ्री फायर कस्टम रूम टूर्नामेंट्स में भाग ले सकते हैं!',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.cyanAccent, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required int highScore,
    required String badgeText,
    required Color badgeColor,
    required Color accentColor,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor, width: 1),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'हाई स्कोर: $highScore',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                      ),
                      child: Icon(iconData, color: accentColor, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.rajdhani(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: AppTheme.bgDark,
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'अभी खेलें और 1 कॉइन जीतें',
                        style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num, style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
