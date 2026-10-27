import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import '../services/ad_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'wallet_screen.dart';
import '../widgets/referral_status_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// How the list works:
//   Leaderboard has N player entries.
//   We insert a banner slot after every 2 players → index logic:
//     Every 3rd slot (index % 3 == 2) is an ad slot.
//     Player index = index - (index ~/ 3)
//   Total item count = N + (N ~/ 2)  [one ad per 2 players]
//
//   Each inline ad slot gets its own BannerAd instance (max 5 shown at once
//   in the list at any time due to ListView recycling, so this is fine).
// ─────────────────────────────────────────────────────────────────────────────

class LeaderboardScreen extends StatefulWidget {
  final AppState appState;

  const LeaderboardScreen({
    super.key,
    required this.appState,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // Top banner (above list header)
  BannerAd? _topBannerAd;
  bool _isTopBannerLoaded = false;

  // Pool of inline banner ads for the list (one per ad slot, max ~10)
  final Map<int, BannerAd> _inlineAds = {};
  final Map<int, bool> _inlineAdLoaded = {};

  // Adaptive banner height (calculated once)
  double _adaptiveBannerHeight = 60;

  @override
  void initState() {
    super.initState();
    _loadTopBanner();
    _precacheInlineAds();
  }

  // ── Top banner ────────────────────────────────────────────
  void _loadTopBanner() {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    _adaptiveBannerHeight = 52;
    _topBannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isTopBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Top leaderboard banner failed: $error');
          ad.dispose();
          _topBannerAd = null;
        },
      ),
    );
    _topBannerAd!.load();
  }

  // ── Inline ads: precache 10 slots (one per every-2-player gap) ─────────────
  Future<void> _precacheInlineAds() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    // Precache up to 10 inline banner ads
    for (int slot = 0; slot < 10; slot++) {
      _loadInlineAdForSlot(slot);
    }
  }

  void _loadInlineAdForSlot(int slot) {
    if (_inlineAds.containsKey(slot)) return;

    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner, // 320×50 — fits inside list row nicely
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _inlineAdLoaded[slot] = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _inlineAds.remove(slot);
        },
      ),
    );

    _inlineAds[slot] = ad;
    _inlineAdLoaded[slot] = false;
    ad.load();
  }

  @override
  void dispose() {
    _topBannerAd?.dispose();
    for (final ad in _inlineAds.values) {
      ad.dispose();
    }
    super.dispose();
  }

  String _getResetCountdown() {
    final now = DateTime.now();
    if (widget.appState.isDailyTournament) {
      final midnight = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final diff = midnight.difference(now);
      return 'आज रात ${diff.inHours}h ${diff.inMinutes % 60}m ${diff.inSeconds % 60}s';
    } else {
      int daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
      if (daysUntilSunday == 0 && now.hour == 23 && now.minute >= 59) {
        daysUntilSunday = 7;
      }
      final nextSunday =
          DateTime(now.year, now.month, now.day + daysUntilSunday, 23, 59, 59);
      final diff = nextSunday.difference(now);
      return 'Resets in ${diff.inDays}d ${diff.inHours % 24}h ${diff.inMinutes % 60}m';
    }
  }

  // ── Build inline ad banner widget ─────────────────────────────────────────
  Widget _buildInlineAdBanner(int adSlot) {
    // Placeholder card shown even while ad is loading (prevents layout jump)
    final bool loaded = _inlineAdLoaded[adSlot] == true;
    final BannerAd? ad = _inlineAds[adSlot];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.bgCardLight),
      ),
      alignment: Alignment.center,
      child: loaded && ad != null
          ? AdWidget(ad: ad)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.ads_click, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Ad loading...',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.appState.user.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Leaderboard Name', style: AppTheme.gamingTitle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the name you want to show on tournament leaderboard:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.bgDark,
                hintText: 'Your Gamer Tag',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGold)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.bgDark),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await widget.appState.updateDisplayName(name);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save Name', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReferralDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('रेफरल कोड दर्ज करें', style: AppTheme.gamingTitle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('अपना कोड शेयर करें: ${widget.appState.user.referralCode}\n(जब दोस्त 5 मैच खेलेगा तब आपको +50 कॉइन्स मिलेंगे!)', style: const TextStyle(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('दोस्त का 6-अंकों का कोड दर्ज करें (+10 बोनस कॉइन्स):', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.bgDark,
                hintText: 'दोस्त का रेफरल कोड',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGold)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.bgDark),
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                final success = await widget.appState.applyReferralCode(code);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'रेफरल कोड लग गया! +10 बोनस कॉइन्स प्राप्त हुए!' : 'अमान्य कोड या पहले से उपयोग किया गया है।'),
                      backgroundColor: success ? AppTheme.bgCard : AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('कोड लगाएं', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPrizeBreakdownDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 24),
            const SizedBox(width: 8),
            Text('${widget.appState.prizePool} Prize Distribution', style: AppTheme.gamingTitle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹1,000 डेली चैंपियनशिप प्राइज़ पूल वितरण (Top 100 Ranks):',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...[
                {'title': '🥇 Rank 1', 'prize': '₹150 Cash + Code', 'desc': '1 Player'},
                {'title': '🥈 Rank 2', 'prize': '₹80 Cash + Code', 'desc': '1 Player'},
                {'title': '🥉 Rank 3', 'prize': '₹50 Cash + Code', 'desc': '1 Player'},
                {'title': '🎖️ Rank 4 - 10', 'prize': '₹25 Code each', 'desc': '7 Players (₹175)'},
                {'title': '🎖️ Rank 11 - 50', 'prize': '₹11 Code each', 'desc': '40 Players (₹440)'},
                {'title': '👤 Rank 51 - 100', 'prize': '₹2.10 (210 Coins)', 'desc': '50 Real Players (Wallet Credit)'},
              ].map((item) {
                final isHighlight = item['title']!.contains('51') || item['title']!.contains('Rank 1');
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isHighlight ? AppTheme.primaryGold.withValues(alpha: 0.15) : AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isHighlight ? AppTheme.primaryGold : AppTheme.bgCardLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: GoogleFonts.rajdhani(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isHighlight ? AppTheme.primaryGold : Colors.white,
                            ),
                          ),
                          Text(
                            item['desc']!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item['prize']!,
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.bgDark),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeChip(String rankText, String prizeText, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight ? AppTheme.primaryGold.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight ? AppTheme.primaryGold : Colors.white24,
          width: isHighlight ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rankText,
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppTheme.primaryGold : Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            prizeText,
            style: GoogleFonts.rajdhani(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isHighlight ? Colors.white : AppTheme.primaryGold,
            ),
          ),
        ],
      ),
    );
  }

  void _showPayoutClaimDialog(BuildContext context) {
    final user = widget.appState.user;
    final userRank = widget.appState.userWeeklyRank;
    final prize = _getPrizeForRank(userRank);

    final phoneController = TextEditingController(text: user.phoneNumber);
    final emailController = TextEditingController(text: user.email);
    final upiController = TextEditingController();
    String payoutMethod = 'upi'; // 'upi' | 'redeem_code'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
            ),
            title: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppTheme.primaryGold, size: 24),
                const SizedBox(width: 8),
                Text('Claim Tournament Payout', style: AppTheme.gamingTitle(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Text('Rank: #$userRank', style: GoogleFonts.rajdhani(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        Text('Prize: $prize', style: GoogleFonts.rajdhani(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'पेआउट माध्यम चुनें (आपकी पसंद):',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => payoutMethod = 'upi'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: payoutMethod == 'upi' ? AppTheme.primaryGold.withValues(alpha: 0.2) : AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: payoutMethod == 'upi' ? AppTheme.primaryGold : Colors.white24,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet, size: 16, color: payoutMethod == 'upi' ? AppTheme.primaryGold : Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  'UPI Cash',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: payoutMethod == 'upi' ? AppTheme.primaryGold : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => payoutMethod = 'redeem_code'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: payoutMethod == 'redeem_code' ? const Color(0xFF10B981).withValues(alpha: 0.2) : AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: payoutMethod == 'redeem_code' ? const Color(0xFF10B981) : Colors.white24,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.card_giftcard, size: 16, color: payoutMethod == 'redeem_code' ? const Color(0xFF10B981) : Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  'Redeem Code',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: payoutMethod == 'redeem_code' ? const Color(0xFF10B981) : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Phone Number (WhatsApp संपर्क):', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '10-digit mobile number',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.bgDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (payoutMethod == 'upi') ...[
                    const Text('UPI ID (Direct Bank / Paytm / PhonePe):', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: upiController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. 9876543210@paytm / name@okaxis',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.bgDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ] else ...[
                    const Text('Email Address (Google Play Code पाने के लिए):', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'yourname@gmail.com',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.bgDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security, size: 16, color: AppTheme.successGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'प्राइज़ रोज़ रात 12:00 बजे सीधे इन-ऐप वॉलेट में जुड़ जाता है या UPI पर भेजा जाता है!',
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.successGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.bgDark),
                onPressed: () async {
                  final phone = phoneController.text.trim();
                  final email = emailController.text.trim();
                  final upi = upiController.text.trim();

                  if (phone.isEmpty && email.isEmpty && upi.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('कृपया आवश्यक पेआउट विवरण दर्ज करें।')),
                    );
                    return;
                  }

                  final res = await widget.appState.submitPayoutClaim(
                    phoneNumber: phone,
                    email: email,
                    upiId: upi,
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Payout details submitted!'),
                        backgroundColor: res['success'] == true ? AppTheme.bgCard : AppTheme.errorRed,
                      ),
                    );
                  }
                },
                child: const Text('Submit Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getPrizeForRank(int rank) {
    return widget.appState.getPrizeForRank(rank);
  }

  Widget _buildNoticeBoard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.campaign_rounded, color: AppTheme.primaryGold, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📢 सूचना पट्ट (NOTICE BOARD)',
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppTheme.primaryGold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.appState.tournamentNotice.isNotEmpty
                      ? widget.appState.tournamentNotice
                      : '🎮 टूर्नामेंट मुकाबला लाइव है! खेलें और टॉप 10 में अपनी रैंक बनाएं।',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppTheme.textWhite,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofBadge(String title, String user, String tag, {String review = ''}) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          if (review.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"$review"',
              style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final user = widget.appState.user;
        final int userRank = widget.appState.userWeeklyRank;
        final leaderboard = widget.appState.dynamicWeeklyLeaderboard;
        final topLeaderboard = leaderboard.take(100).toList();

        // ── Calculate mixed list item count for TOP 100 (Ad after every 10 players) ──
        final int playerCount = topLeaderboard.length;
        final int adCount = playerCount ~/ 10;
        final int totalItems = playerCount + adCount;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: AppTheme.bgDark,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.leaderboard_rounded,
                    color: AppTheme.primaryGold, size: 26),
                const SizedBox(width: 8),
                Text(
                  widget.appState.isDailyTournament ? 'DAILY LEADERBOARD' : 'WEEKLY LEADERBOARD',
                  style: GoogleFonts.rajdhani(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppTheme.primaryGold,
                  ),
                ),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WalletScreen(appState: widget.appState),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '₹${(widget.appState.user.adCoins / 100).toStringAsFixed(1)}',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // ── 📢 ADMIN NOTICE BOARD ──────────────────────────────────
              _buildNoticeBoard(context),

              // ── MEGA GIVEAWAY HIGHLIGHT BANNER (₹50,000) ───────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB900), Color(0xFFFF8800), Color(0xFFE11D48)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.35),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: AppTheme.primaryGold, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'SEASON ${widget.appState.season} LIVE',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryGold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'TOP 100 WINNERS',
                            style: GoogleFonts.rajdhani(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.appState.isDailyTournament ? '⚡ दैनिक चैंपियंस लीडरबोर्ड' : '🏆 वीकली चैंपियंस लीडरबोर्ड',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 1.1,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.appState.isDailyTournament
                                    ? '🔥 सीज़न ${widget.appState.season} लाइव: हर रात 12:00 AM IST पर रीसेट!'
                                    : '🔥 सीज़न ${widget.appState.season} लाइव: हर रविवार 23:59 IST पर रीसेट!',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('👑', style: TextStyle(fontSize: 28)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ── Top 10 Rank Prizes Strip ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPrizeChip('🥇 Rank 1', _getPrizeForRank(1), isHighlight: true),
                          _buildPrizeChip('🥈 Rank 2', _getPrizeForRank(2), isHighlight: true),
                          _buildPrizeChip('🥉 Rank 3', _getPrizeForRank(3), isHighlight: true),
                          _buildPrizeChip('#4 - 10', _getPrizeForRank(4)),
                          _buildPrizeChip('#11 - 50', _getPrizeForRank(11)),
                          _buildPrizeChip('#51 - 100', _getPrizeForRank(51), isHighlight: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _showPrizeBreakdownDialog(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'पूरा प्राइज़ वितरण देखें (Rank 1-100) ➜',
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── User Status Card ─────────────────────────────────────────
              Builder(
                builder: (context) {
                  final int displayRank = userRank;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(
                      border: Border.all(
                          color: AppTheme.primaryGold.withValues(alpha: 0.6),
                          width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppTheme.bgDark,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#$displayRank',
                            style: GoogleFonts.rajdhani(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    '${user.displayName} (YOU)',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textWhite,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showEditNameDialog(context),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 2),
                                      child: Icon(Icons.edit, size: 14, color: AppTheme.primaryGold),
                                    ),
                                  ),
                                  if (userRank <= 10)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successGreen,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'PRIZE ZONE',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.bgDark,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    'Ref: ${user.referralCode}',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showReferralDialog(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        '+25 PTS REFER',
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getResetCountdown(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${user.weeklyScore}',
                              style: GoogleFonts.rajdhani(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryGold,
                              ),
                            ),
                            Text(
                              widget.appState.isDailyTournament ? 'TODAY PTS' : 'WEEKLY PTS',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── Top 10 Payout Claim Banner (If in Winning Zone) ─────────
              if (userRank <= 50 && user.weeklyScore > 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF854D0E), Color(0xFFCA8A04), Color(0xFFEAB308)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGold.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppTheme.bgDark, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏆 विजेता ज़ोन: रैंक #$userRank (${_getPrizeForRank(userRank)})',
                              style: GoogleFonts.rajdhani(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.bgDark,
                              ),
                            ),
                            Text(
                              'रात 12:00 बजे सीधे प्राइज़ पाने के लिए UPI / फ़ोन नंबर दर्ज करें',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.bgDark.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () => _showPayoutClaimDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.bgDark,
                          foregroundColor: AppTheme.primaryGold,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 3,
                        ),
                        child: Text(
                          'क्लेम करें',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final int rank10Score = (leaderboard.length >= 10) ? leaderboard[9].weeklyScore : 500;
                    final int ptsNeeded = math.max(15, (rank10Score - user.weeklyScore) + 1);
                    final int displayRank = userRank;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF1E3A8A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'आपकी रैंक: #$displayRank (टॉप 10 से सिर्फ $ptsNeeded पॉइंट्स दूर!)',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF60A5FA),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '1-2 गेम खेलें और सीधे प्राइज़ ज़ोन (टॉप 10) में पहुंचकर इनाम जीतें!',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // ── Dedicated Referral Card (+25 PTS) ────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard, color: AppTheme.primaryGold, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => ReferralStatusDialog.show(context, widget.appState),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'REFER & EARN (+50 COINS)',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: AppTheme.primaryGold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGold.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.referralCode,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.referredBy.isNotEmpty
                                  ? 'Referred by: ${user.referredBy} (+10 Coins Bonus) ✅'
                                  : 'Share code: +50 Coins when friend plays 5 matches!',
                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (user.referredBy.isEmpty)
                      ElevatedButton(
                        onPressed: () => _showReferralDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: AppTheme.bgDark,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'ENTER CODE',
                          style: GoogleFonts.rajdhani(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryGold, size: 18),
                        tooltip: 'Copy Referral Code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: user.referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Referral code ${user.referralCode} copied to clipboard!'),
                              backgroundColor: AppTheme.bgCard,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              // ── Top Adaptive Banner ──────────────────────────────────────
              if (_isTopBannerLoaded && _topBannerAd != null)
                Container(
                  width: double.infinity,
                  height: _adaptiveBannerHeight,
                  color: AppTheme.bgDark,
                  alignment: Alignment.center,
                  child: AdWidget(ad: _topBannerAd!),
                )
              else
                const SizedBox(height: 4),

              // ── Table Header ─────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        'RANK',
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'PLAYER',
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    Text(
                      'SCORE / PRIZE',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Mixed List: Players + Inline Ads ─────────────────────────
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: totalItems,
                  itemBuilder: (context, index) {
                    // Inline ad slot every 10 players
                    if ((index + 1) % 11 == 0) {
                      final int adSlot = ((index + 1) ~/ 11) - 1;
                      return _buildInlineAdBanner(adSlot);
                    }

                    final int playerIndex = index - (index ~/ 11);
                    if (playerIndex >= topLeaderboard.length) {
                      return const SizedBox.shrink();
                    }

                    final item = topLeaderboard[playerIndex];
                    final bool isTop3 = item.rank <= 3;
                    final bool isTop10 = item.rank <= 10;
                    final bool isTop100 = item.rank <= 100;
                    final bool isSelf = item.name.contains('(YOU)');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelf
                            ? AppTheme.primaryGold.withValues(alpha: 0.15)
                            : isTop3
                                ? AppTheme.primaryGold.withValues(alpha: 0.08)
                                : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelf
                              ? AppTheme.primaryGold
                              : isTop3
                                  ? AppTheme.primaryGold.withValues(alpha: 0.4)
                                  : AppTheme.bgCardLight,
                          width: isSelf ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rank Badge
                          SizedBox(
                            width: 36,
                            child: item.rank == 1
                                ? const Text('🥇',
                                    style: TextStyle(fontSize: 22))
                                : item.rank == 2
                                    ? const Text('🥈',
                                        style: TextStyle(fontSize: 22))
                                    : item.rank == 3
                                        ? const Text('🥉',
                                            style: TextStyle(fontSize: 22))
                                        : Text(
                                            '#${item.rank}',
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isSelf
                                                  ? AppTheme.primaryGold
                                                  : AppTheme.textMuted,
                                            ),
                                          ),
                          ),
                          const SizedBox(width: 8),

                          // Name
                          Expanded(
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isSelf || isTop3
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelf
                                    ? AppTheme.primaryGold
                                    : AppTheme.textWhite,
                              ),
                            ),
                          ),

                          // Score + Prize
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.weeklyScore} pts',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isTop3
                                      ? AppTheme.primaryGold
                                      : AppTheme.textWhite,
                                ),
                              ),
                              if (isTop100)
                                Builder(
                                  builder: (context) {
                                    if (item.weeklyScore <= 0) return const SizedBox.shrink();
                                    final prizeText = item.prize.isNotEmpty
                                        ? item.prize
                                        : _getPrizeForRank(item.rank);
                                    if (prizeText.isEmpty) return const SizedBox.shrink();
                                    return Container(
                                      margin: const EdgeInsets.only(top: 3),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: isTop3
                                              ? AppTheme.primaryGold.withValues(alpha: 0.2)
                                              : isTop10
                                                  ? AppTheme.successGreen.withValues(alpha: 0.15)
                                                  : AppTheme.primaryGold.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isTop3
                                                ? AppTheme.primaryGold
                                                : isTop10
                                                    ? AppTheme.successGreen.withValues(alpha: 0.6)
                                                    : AppTheme.primaryGold.withValues(alpha: 0.3),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isTop3 ? Icons.emoji_events : Icons.verified,
                                              size: 11,
                                              color: isTop3 ? AppTheme.primaryGold : (isTop10 ? AppTheme.successGreen : AppTheme.primaryGold),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              prizeText,
                                              style: GoogleFonts.rajdhani(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isTop3 ? AppTheme.primaryGold : (isTop10 ? AppTheme.successGreen : AppTheme.textWhite),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // ── VERIFIED WINNER PROOFS & REVIEWS (Community Trust) ─────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'COMMUNITY WINNER PROOFS & REVIEWS',
                          style: GoogleFonts.rajdhani(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    widget.appState.winnerProofs.isNotEmpty
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: widget.appState.winnerProofs.map((p) {
                                return _buildProofBadge(p.title, p.winnerName, p.tag, review: p.review);
                              }).toList(),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.bgCardLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.security_update_good_rounded, color: AppTheme.successGreen, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Official verified UPI receipts and Google Play redeem codes are auto-credited daily at 12:00 AM midnight after tournament audits.',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),

              // ── 🏆 DAILY CHAMPIONSHIP RULES ──────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.6), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryGold, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'दैनिक चैंपियनशिप नियम एवं प्राइज़ वितरण',
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🏆 हर रोज़ ₹1,000 प्राइज़ पूल: दैनिक लीडरबोर्ड में टॉप 100 रैंक वाले खिलाड़ियों को इनाम मिलता है!\n'
                      '⏰ दैनिक रीसेट: हर रात 12:00 AM (00:00:00 IST) पर लीडरबोर्ड का दैनिक स्कोर रीसेट होता है ताकि हर खिलाड़ी को रोज़ाना नया मौका मिले!\n'
                      '💰 वॉलेट सुरक्षा: स्पिन व्हील, स्क्रैच कार्ड और दैनिक टूर्नामेंट का कमाया हुआ बैलेंस आपके वॉलेट में हमेशा सुरक्षित रहता है और कभी रीसेट नहीं होता।\n'
                      '⚡ आवश्यक नियम: इनाम पाने के लिए कम से कम 1 गेम खेलकर स्कोर बनाना ज़रूरी है (0 स्कोर पर कोई प्राइज़ नहीं मिलता)। मन लगाकर खेलें और रोज़ जीतें! 🚀',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom Prize Footer ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppTheme.bgCard,
                  border: Border(top: BorderSide(color: AppTheme.bgCardLight)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.primaryGold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Daily ₹1,000 Championship! Top 100 players win rewards daily. Scores reset every night at 23:59 IST. Wallet balance is permanent.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
