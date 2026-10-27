import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import '../services/ad_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'play_zone_screen.dart';

class WalletScreen extends StatefulWidget {
  final AppState appState;

  const WalletScreen({super.key, required this.appState});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = AdService.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showRedeemDialog(BuildContext context, RedeemPackage pkg) {
    final user = widget.appState.user;
    final int winningCoins = user.winningCoins;

    if (winningCoins < pkg.points) {
      final int needed = pkg.points - winningCoins;
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
              Text('विनिंग कॉइन्स चाहिए', style: AppTheme.gamingTitle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${pkg.title} रिडीम करने के लिए आपको ${pkg.points} विनिंग कॉइन्स चाहिए (अभी $needed कॉइन्स कम हैं)।',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('आपके विनिंग कॉइन्स:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('$winningCoins कॉइन्स', style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('बोनस/एड कॉइन्स:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('${user.adCoins} कॉइन्स (मैच एंट्री के लिए)', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '💡 नोट: वीडियो एड्स व चेक-इन से मिले कॉइन्स से आप फ्री टूर्नामेंट मैच खेल सकते हैं। टूर्नामेंट जीतकर Booyah करने पर आपको 100% रिडीम होने वाले विनिंग कॉइन्स मिलते हैं!',
                style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.cyanAccent, height: 1.35),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.bgDark),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('मैच खेलें और Booyah जीतें ➜', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // Has enough coins -> Show Redeem submission form
    final phoneController = TextEditingController(text: user.phoneNumber);
    final emailController = TextEditingController(text: user.email);
    final upiController = TextEditingController();

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
            const Icon(Icons.card_giftcard_rounded, color: AppTheme.primaryGold, size: 24),
            const SizedBox(width: 8),
            Text('रिडीम कोड प्राप्त करें', style: AppTheme.gamingTitle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pkg.title, style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('लागत: ${pkg.points} Coins', style: GoogleFonts.inter(color: AppTheme.primaryGold, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₹${pkg.amount}', style: GoogleFonts.rajdhani(color: AppTheme.successGreen, fontWeight: FontWeight.w900, fontSize: 22)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('ईमेल आईडी (जिस पर कोड भेजा जाएगा):', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
              const SizedBox(height: 10),
              const Text('व्हाट्सएप मोबाइल नंबर:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '10-अंकों का फ़ोन नंबर',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('UPI ID (यदि कैश चाहिए तो वैकल्पिक):', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(
                controller: upiController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. mobile@paytm',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करें', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.bgDark),
            onPressed: () async {
              final email = emailController.text.trim();
              final phone = phoneController.text.trim();
              final upi = upiController.text.trim();

              if (email.isEmpty && phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('कृपया कम से कम ईमेल या फ़ोन नंबर दर्ज करें!')),
                );
                return;
              }

              final res = await widget.appState.submitRedeemRequest(
                amount: pkg.amount,
                packageId: pkg.id,
                email: email,
                phone: phone,
                upiId: upi,
              );

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'अनुरोध सफलतापूर्वक सबमिट हुआ!'),
                    backgroundColor: res['success'] == true ? AppTheme.bgCard : AppTheme.errorRed,
                  ),
                );
              }
            },
            child: const Text('सबमिट करें (Submit)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
        final int winCoins = user.winningCoins;
        final int entryCoins = user.adCoins;
        final double winInRupees = winCoins / 100.0;
        final double progressToMinWithdrawal = (winCoins / 5000.0).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: AppTheme.bgDark,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryGold, size: 26),
                const SizedBox(width: 8),
                Text(
                  'BOOYAH WALLET (वॉलेट)',
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppTheme.primaryGold,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // ── 🏆 COIN 1: WINNING COINS (100% WITHDRAWABLE) ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF854D0E), Color(0xFFCA8A04), Color(0xFFEAB308)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.35),
                      blurRadius: 18,
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
                            const Icon(Icons.emoji_events, color: Colors.black, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              '🏆 WINNING COINS (विनिंग कॉइन्स)',
                              style: GoogleFonts.rajdhani(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '100% WITHDRAWABLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$winCoins',
                          style: GoogleFonts.rajdhani(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'WIN COINS',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withValues(alpha: 0.75),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '₹${winInRupees.toStringAsFixed(2)} Real Cash',
                            style: GoogleFonts.rajdhani(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress to Minimum ₹50 Withdrawal
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹50 मिनिमम विड्रॉल लक्ष्य:',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black.withValues(alpha: 0.85),
                              ),
                            ),
                            Text(
                              '${(progressToMinWithdrawal * 100).toInt()}% ($winCoins / 5,000 Coins)',
                              style: GoogleFonts.rajdhani(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressToMinWithdrawal,
                            minHeight: 7,
                            backgroundColor: Colors.black.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── 🪙 COIN 2: MATCH ENTRY / BONUS COINS ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cyanAccent.withValues(alpha: 0.25),
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
                            const Icon(Icons.sports_esports, color: Colors.black, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              '🪙 MATCH ENTRY COINS (मैच कॉइन्स)',
                              style: GoogleFonts.rajdhani(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'MATCH FEES USE ONLY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.cyanAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$entryCoins',
                          style: GoogleFonts.rajdhani(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ENTRY COINS',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withValues(alpha: 0.75),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '🎮 टूर्नामेंट खेलें',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.cyanAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• मिनी-गेम खेलने, वीडियो एड्स देखने और टास्क से अर्जित कॉइन्स।\n• इनसे आप सीधे Free Fire India टूर्नामेंट्स की एंट्री ले सकते हैं!',
                      style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.35),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── ⚡ 3 QUICK EARNING ACTIONS ──
              Text(
                '⚡ EARN MORE COINS (कॉइन्स कमाएं)',
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // 1. Arcade Play Zone
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayZoneScreen(appState: widget.appState)));
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🎮', style: TextStyle(fontSize: 22)),
                            const SizedBox(height: 6),
                            Text('आर्केड ज़ोन', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                            const Text('5 गेम्स खेलें', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Direct Watch & Earn (+10)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        final messenger = ScaffoldMessenger.of(context);
                        AdService.showRewardedAd(
                          context: context,
                          onRewarded: () async {
                            final res = await widget.appState.watchAdEarnCoins();
                            if (res['success'] == true) {
                              messenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: AppTheme.successGreen,
                                  content: Text('🎉 +${res['coinsEarned']} Coins वॉलेट में जुड़ गए!'),
                                ),
                              );
                            }
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🎬', style: TextStyle(fontSize: 22)),
                            const SizedBox(height: 6),
                            Text('वीडियो देखें', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                            const Text('+10 कॉइन्स पाएं', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Refer & Earn
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.bgCard,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text('👥 रेफर करें और कमाएं', style: AppTheme.gamingTitle(fontSize: 18)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('अपना रेफरल कोड दोस्तों के साथ शेयर करें। जब वे साइन अप करेंगे तो दोनों को बोनस कॉइन्स मिलेंगे!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgDark,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.primaryGold),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(user.referralCode, style: GoogleFonts.rajdhani(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                                      IconButton(
                                        icon: const Icon(Icons.copy, color: Colors.white70),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: user.referralCode));
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('रेफरल कोड कॉपी हो गया!')));
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black),
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('ठीक है'),
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cyanAccent.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('👥', style: TextStyle(fontSize: 22)),
                            const SizedBox(height: 6),
                            Text('रेफर कोड', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
                            const Text('+20 कॉइन्स/फ्रेंड', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── 🎁 REDEEM PACKAGES (STORE) ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GOOGLE PLAY & CASH REDEEM STORE',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    'Min: ₹50',
                    style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ...widget.appState.redeemPackages.map((pkg) {
                final bool canRedeem = winCoins >= pkg.points;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: canRedeem ? AppTheme.successGreen : AppTheme.bgCardLight,
                      width: canRedeem ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: canRedeem ? AppTheme.successGreen : AppTheme.primaryGold.withValues(alpha: 0.4)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '₹${pkg.amount}',
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: canRedeem ? AppTheme.successGreen : AppTheme.primaryGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  pkg.title,
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'लागत: ${pkg.points} कॉइन्स (${pkg.badge})',
                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _showRedeemDialog(context, pkg),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canRedeem ? AppTheme.successGreen : AppTheme.bgDark,
                          foregroundColor: canRedeem ? AppTheme.bgDark : AppTheme.textMuted,
                          side: BorderSide(color: canRedeem ? AppTheme.successGreen : Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          canRedeem ? 'REDEEM' : 'LOCK 🔒',
                          style: GoogleFonts.rajdhani(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // ── Banner Ad at Bottom ───────────────────────────────────────
              if (_isBannerLoaded && _bannerAd != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  alignment: Alignment.center,
                  child: AdWidget(ad: _bannerAd!),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
