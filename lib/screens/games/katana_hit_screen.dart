import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import '../../services/ad_service.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class KatanaHitScreen extends StatefulWidget {
  final AppState appState;

  const KatanaHitScreen({super.key, required this.appState});

  @override
  State<KatanaHitScreen> createState() => _KatanaHitScreenState();
}

class _KatanaHitScreenState extends State<KatanaHitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Game Physics & State
  double _targetRotation = 0.0;
  double _rotationSpeed = 0.025; // Radians per tick
  int _rotationDirection = 1;
  Timer? _rotationSpeedTimer;

  int _score = 0;
  int _coinsEarned = 0;
  static const int maxCoinsHardCap = 3;
  static const int scorePerCoin = 50;

  bool _isGameOver = false;
  bool _hasRevivedOnce = false;
  bool _isShooting = false;
  double _flyingKnifeY = 0.0; // 0.0 = bottom, 1.0 = target hit

  // Angles of embedded knives relative to target
  final List<double> _embeddedAngles = [0.0, math.pi * 0.7]; // Start with 2 initial knives

  // Dual Banner Ads (Top & Bottom simultaneously for 2X Banner Revenue!)
  BannerAd? _topBannerAd;
  bool _isTopBannerLoaded = false;
  BannerAd? _bottomBannerAd;
  bool _isBottomBannerLoaded = false;

  // Strategic Rewarded Ad Power-Up: Free Fire Golden Shield
  bool _hasShieldActive = false;

  @override
  void initState() {
    super.initState();
    _initBannerAds();

    // 60 FPS Game Loop
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameTick);
    _animController.repeat();

    // Dynamically fluctuate rotation speed and direction
    _rotationSpeedTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted || _isGameOver) return;
      setState(() {
        final rand = math.Random();
        _rotationDirection = rand.nextBool() ? 1 : -1;
        _rotationSpeed = 0.02 + (rand.nextDouble() * 0.035);
      });
    });
  }

  void _initBannerAds() {
    if (kIsWeb) return;
    _topBannerAd = AdService.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isTopBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Top banner failed: $err');
          ad.dispose();
        },
      ),
    );
    _topBannerAd?.load();

    _bottomBannerAd = AdService.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBottomBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Bottom banner failed: $err');
          ad.dispose();
        },
      ),
    );
    _bottomBannerAd?.load();
  }

  void _activateShieldWithRewardedAd() {
    AdService.showRewardedAd(
      context: context,
      ignoreCooldown: true,
      onRewarded: () {
        if (!mounted) return;
        setState(() => _hasShieldActive = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successGreen,
            content: Text('🛡️ गोल्डन शील्ड एक्टिवेटेड! 1 गलती माफ होगी!'),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _rotationSpeedTimer?.cancel();
    _animController.dispose();
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    super.dispose();
  }

  void _gameTick() {
    if (_isGameOver) return;

    setState(() {
      _targetRotation = (_targetRotation + (_rotationSpeed * _rotationDirection)) % (2 * math.pi);

      // Handle shooting knife animation
      if (_isShooting) {
        _flyingKnifeY += 0.12;
        if (_flyingKnifeY >= 1.0) {
          _flyingKnifeY = 0.0;
          _isShooting = false;
          _handleKnifeHit();
        }
      }
    });
  }

  void _onTapShoot() {
    if (_isGameOver || _isShooting) return;
    setState(() {
      _isShooting = true;
      _flyingKnifeY = 0.0;
    });
  }

  void _handleKnifeHit() {
    // Current angle relative to target where knife hit
    // The bottom knife enters at angle: (math.pi / 2 - _targetRotation)
    double hitAngle = (math.pi / 2 - _targetRotation) % (2 * math.pi);
    if (hitAngle < 0) hitAngle += 2 * math.pi;

    // Check collision with embedded knives (threshold ~ 0.26 radians = ~15 degrees)
    const double minAngleDiff = 0.26;
    bool collided = false;

    for (final angle in _embeddedAngles) {
      double diff = (angle - hitAngle).abs();
      if (diff > math.pi) diff = (2 * math.pi) - diff;
      if (diff < minAngleDiff) {
        collided = true;
        break;
      }
    }

    if (collided) {
      if (_hasShieldActive) {
        setState(() => _hasShieldActive = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryGold,
            duration: Duration(seconds: 2),
            content: Text('🛡️ गोल्डन शील्ड ने आपको बचा लिया! स्ट्राइक जारी रखें!'),
          ),
        );
        return;
      }
      _triggerGameOver();
    } else {
      // Success! Knife embedded
      _embeddedAngles.add(hitAngle);
      _score += 10;

      // Update High Score
      if (_score > widget.appState.user.knifeHitHighScore) {
        widget.appState.user.knifeHitHighScore = _score;
        widget.appState.saveUser();
      }

      // Hard Capped Coin calculation: 50 Score = 1 Coin, MAX 3 Coins per game!
      _coinsEarned = math.min(_score ~/ scorePerCoin, maxCoinsHardCap);
    }
  }

  void _triggerGameOver() {
    setState(() => _isGameOver = true);
    // Show game over dialog
    _showGameOverModal();
  }

  void _reviveWithRewardedAd() {
    Navigator.of(context, rootNavigator: true).pop();
    AdService.showRewardedAd(
      context: context,
      ignoreCooldown: true,
      onRewarded: () {
        if (!mounted) return;
        setState(() {
          _hasRevivedOnce = true;
          _isGameOver = false;
          // Clear 2 closest knives to give room
          if (_embeddedAngles.length > 3) {
            _embeddedAngles.removeLast();
            _embeddedAngles.removeLast();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successGreen,
            content: Text('✨ 1 Extra Life! गेम जारी रखें!'),
          ),
        );
      },
    );
  }

  void _doubleCoinsWithRewardedAd() {
    AdService.showRewardedAd(
      context: context,
      ignoreCooldown: true,
      onRewarded: () {
        _collectCoinsAndExit(doubleReward: true);
      },
    );
  }

  void _collectCoinsAndExit({bool doubleReward = false}) async {
    // 1. Show full screen Interstitial Ad on Game Over
    await AdService.showInterstitialAd();

    if (!mounted) return;
    // 2. Claim reward in backend
    final res = await widget.appState.claimMiniGameReward(
      gameId: 'katana_hit',
      score: _score,
      doubleReward: doubleReward,
    );

    if (!mounted) return;
    final int credited = (res['coinsEarned'] as num?)?.toInt() ?? 0;
    final String msg = res['message'] as String? ?? 'You Earned $credited Coins!';

    // Show celebration popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryGold, width: 2),
        ),
        title: Column(
          children: [
            const Icon(Icons.stars, color: AppTheme.primaryGold, size: 48),
            const SizedBox(height: 8),
            Text(
              credited > 0 ? '🎉 YOU EARNED $credited COINS!' : 'GAME OVER',
              style: GoogleFonts.rajdhani(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('कुल वॉलेट कॉइन्स:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    '${widget.appState.user.adCoins} कॉइन्स',
                    style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.bgDark,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to Play Zone
            },
            child: const Text('Play Zone में वापस जाएं', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  void _showGameOverModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.bgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.primaryGold, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_off, color: Color(0xFFEF4444), size: 28),
                const SizedBox(width: 8),
                Text(
                  'GAME OVER!',
                  style: GoogleFonts.rajdhani(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('स्कोर', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('$_score', style: GoogleFonts.rajdhani(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Container(width: 1, height: 35, color: Colors.white24),
                  Column(
                    children: [
                      const Text('बोनस कॉइन्स', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('+$_coinsEarned', style: GoogleFonts.rajdhani(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                    ],
                  ),
                  Container(width: 1, height: 35, color: Colors.white24),
                  Column(
                    children: [
                      const Text('हार्ड कैप', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Max 3', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Button 1: Revive with Ad (only available once per match)
            if (!_hasRevivedOnce)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cyanAccent,
                    side: const BorderSide(color: AppTheme.cyanAccent, width: 1.5),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_circle_fill, color: AppTheme.cyanAccent),
                  label: const Text('🔄 रिवाइव करें (1 लाइफ) - वीडियो देखें', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _reviveWithRewardedAd,
                ),
              ),

            // Button 2: 2X Double Coins with Ad
            if (_coinsEarned > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.electric_bolt, color: Colors.black),
                  label: Text('⚡ 2X कॉइन्स पाएं (+${_coinsEarned * 2} Coins)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _doubleCoinsWithRewardedAd();
                  },
                ),
              ),

            // Button 3: Collect & Exit
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: AppTheme.bgDark,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _collectCoinsAndExit();
              },
              child: const Text('🏆 कॉइन्स कलेक्ट करें और बाहर आएं', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '🔥 KATANA STRIKE',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.primaryGold,
          ),
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
                const SizedBox(width: 4),
                Text(
                  '$_coinsEarned / $maxCoinsHardCap',
                  style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Pinned Top Banner Ad ──
          if (_topBannerAd != null && _isTopBannerLoaded)
            Container(
              alignment: Alignment.center,
              width: _topBannerAd!.size.width.toDouble(),
              height: _topBannerAd!.size.height.toDouble(),
              color: AppTheme.bgDark,
              child: AdWidget(ad: _topBannerAd!),
            )
          else
            Container(
              height: 50,
              color: AppTheme.bgDark,
              alignment: Alignment.center,
              child: const Text('⚡ SPONSORED ARENA BANNER (TOP)', style: TextStyle(color: Colors.white24, fontSize: 11)),
            ),

          // Top Score & Target Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('स्कोर', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    Text('$_score', style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    '🎯 50 अंक = 1 कॉइन',
                    style: TextStyle(color: AppTheme.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('हाई स्कोर', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    Text(
                      '${widget.appState.user.knifeHitHighScore}',
                      style: GoogleFonts.rajdhani(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🛡️ Rewarded Video Power-Up Strip (Boost Rewarded Ad Views)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _hasShieldActive ? Icons.shield : Icons.shield_outlined,
                      color: _hasShieldActive ? AppTheme.primaryGold : Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _hasShieldActive ? 'गोल्डन शील्ड एक्टिव (1 लाइफ प्रोटेक्टेड)' : 'शील्ड: इनएक्टिव',
                      style: TextStyle(
                        color: _hasShieldActive ? AppTheme.primaryGold : Colors.white60,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!_hasShieldActive && !_isGameOver)
                  InkWell(
                    onTap: _activateShieldWithRewardedAd,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.primaryGold, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.play_circle_fill, color: AppTheme.primaryGold, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '🛡️ शील्ड लें (वीडियो देखें)',
                            style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Interactive Canvas Area (Tap anywhere to shoot)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onTapShoot,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Spinning Wheel Target
                  Positioned(
                    top: 40,
                    child: CustomPaint(
                      size: const Size(180, 180),
                      painter: KatanaTargetPainter(
                        rotation: _targetRotation,
                        embeddedAngles: _embeddedAngles,
                      ),
                    ),
                  ),

                  // Bottom Ready Katana
                  Positioned(
                    bottom: 40,
                    child: Transform.translate(
                      offset: Offset(0, -(_flyingKnifeY * 260)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white, Color(0xFFF59E0B), Color(0xFFB45309)],
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGold.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.primaryGold, width: 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tap to Strike Hint
                  if (_score == 0 && !_isShooting)
                    Positioned(
                      bottom: 150,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app, color: AppTheme.primaryGold, size: 16),
                            SizedBox(width: 6),
                            Text('कटाना स्ट्राइक के लिए स्क्रीन पर टैप करें', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Pinned Bottom Banner Ad ──
          if (_bottomBannerAd != null && _isBottomBannerLoaded)
            Container(
              alignment: Alignment.center,
              width: _bottomBannerAd!.size.width.toDouble(),
              height: _bottomBannerAd!.size.height.toDouble(),
              color: AppTheme.bgDark,
              child: AdWidget(ad: _bottomBannerAd!),
            )
          else
            Container(
              height: 50,
              color: AppTheme.bgDark,
              alignment: Alignment.center,
              child: const Text('⚡ SPONSORED ARENA BANNER (BOTTOM)', style: TextStyle(color: Colors.white24, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

// ── Custom Painter for Target & Embedded Knives ──
class KatanaTargetPainter extends CustomPainter {
  final double rotation;
  final List<double> embeddedAngles;

  KatanaTargetPainter({
    required this.rotation,
    required this.embeddedAngles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw Airdrop Core / Target Circle
    final corePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFE11D48), Color(0xFF881337), Color(0xFF1E1B4B)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, corePaint);

    // Golden Outer Ring
    final ringPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, ringPaint);

    // Inner Glowing Ring
    final innerRing = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.65, innerRing);

    // Center Golden Bullseye Emblem
    final bullseye = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(center, 12, bullseye);

    // Draw Embedded Knives protruding from the wheel
    for (final angle in embeddedAngles) {
      final totalAngle = angle + rotation;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(totalAngle);

      // Embedded Katana protruding outward from radius
      final bladePaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF59E0B), Colors.white],
        ).createShader(Rect.fromLTWH(-4, radius, 8, 48));

      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-4, radius, 8, 45), const Radius.circular(3)),
        bladePaint,
      );

      // Guard
      final guardPaint = Paint()..color = const Color(0xFF1E293B);
      canvas.drawRect(Rect.fromLTWH(-8, radius + 40, 16, 5), guardPaint);

      // Handle
      final handlePaint = Paint()..color = const Color(0xFF0F172A);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-3, radius + 45, 6, 18), const Radius.circular(2)),
        handlePaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant KatanaTargetPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.embeddedAngles.length != embeddedAngles.length;
  }
}
