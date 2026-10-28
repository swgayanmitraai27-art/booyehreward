import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import '../../services/ad_service.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class FruitItem {
  final String id;
  final String emoji;
  final int points;
  final bool isBomb;
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double vRot;
  bool isSliced;
  Color splashColor;

  FruitItem({
    required this.id,
    required this.emoji,
    required this.points,
    required this.isBomb,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.vRot,
    required this.splashColor,
    this.isSliced = false,
  });
}

class SplashParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double opacity;

  SplashParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.opacity = 1.0,
  });
}

class FruitSlashScreen extends StatefulWidget {
  final AppState appState;

  const FruitSlashScreen({super.key, required this.appState});

  @override
  State<FruitSlashScreen> createState() => _FruitSlashScreenState();
}

class _FruitSlashScreenState extends State<FruitSlashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _spawnTimer;

  int _score = 0;
  int _lives = 3;
  bool _isGameOver = false;
  bool _hasRevivedOnce = false;
  bool _isSubmitting = false;

  final List<FruitItem> _fruits = [];
  final List<SplashParticle> _particles = [];
  final List<Offset> _swipePoints = [];

  // Dual Banner Ads (Top & Bottom)
  BannerAd? _topBannerAd;
  bool _isTopBannerLoaded = false;
  BannerAd? _bottomBannerAd;
  bool _isBottomBannerLoaded = false;

  final math.Random _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _initBannerAds();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
    _animController.repeat();

    _startSpawner();
  }

  void _initBannerAds() {
    if (kIsWeb) return;
    _topBannerAd = AdService.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isTopBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('FruitSlash top banner failed: $err');
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
          debugPrint('FruitSlash bottom banner failed: $err');
          ad.dispose();
        },
      ),
    );
    _bottomBannerAd?.load();
  }

  void _startSpawner() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (!mounted || _isGameOver) return;
      _spawnFruitBatch();
    });
  }

  void _spawnFruitBatch() {
    final count = _rand.nextInt(2) + 1;
    for (int i = 0; i < count; i++) {
      final isBomb = _rand.nextDouble() < 0.22;
      String emoji = '🍉';
      int points = 10;
      Color splash = Colors.redAccent;

      if (isBomb) {
        emoji = '💣';
        points = 0;
        splash = Colors.orangeAccent;
      } else {
        final r = _rand.nextInt(4);
        if (r == 0) {
          emoji = '🍎';
          points = 10;
          splash = Colors.red;
        } else if (r == 1) {
          emoji = '🍌';
          points = 10;
          splash = Colors.yellow;
        } else if (r == 2) {
          emoji = '🍍';
          points = 15;
          splash = Colors.amber;
        } else {
          emoji = '⭐';
          points = 25;
          splash = AppTheme.primaryGold;
        }
      }

      final startX = 0.2 + (_rand.nextDouble() * 0.6);
      final vx = (_rand.nextDouble() - 0.5) * 0.015;
      final vy = -0.024 - (_rand.nextDouble() * 0.008);

      _fruits.add(
        FruitItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          emoji: emoji,
          points: points,
          isBomb: isBomb,
          x: startX,
          y: 1.05,
          vx: vx,
          vy: vy,
          rotation: 0.0,
          vRot: (_rand.nextDouble() - 0.5) * 0.15,
          splashColor: splash,
        ),
      );
    }
  }

  void _gameLoop() {
    if (_isGameOver) return;

    setState(() {
      // Update fruits physics
      for (int i = _fruits.length - 1; i >= 0; i--) {
        final f = _fruits[i];
        f.x += f.vx;
        f.y += f.vy;
        f.vy += 0.00065; // gravity
        f.rotation += f.vRot;

        // Dropped below screen without being sliced
        if (f.y > 1.15) {
          if (!f.isBomb && !f.isSliced) {
            _lives--;
            if (_lives <= 0) {
              _triggerGameOver();
              return;
            }
          }
          _fruits.removeAt(i);
        }
      }

      // Update splash particles
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.opacity -= 0.04;
        if (p.opacity <= 0.05) {
          _particles.removeAt(i);
        }
      }

      // Fade swipe trail
      if (_swipePoints.isNotEmpty) {
        _swipePoints.removeAt(0);
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_isGameOver) return;
    final pos = details.localPosition;
    final normX = pos.dx / size.width;
    final normY = pos.dy / size.height;

    setState(() {
      _swipePoints.add(pos);
      if (_swipePoints.length > 10) _swipePoints.removeAt(0);
    });

    // Check hit test against active fruits
    for (int i = 0; i < _fruits.length; i++) {
      final f = _fruits[i];
      if (f.isSliced) continue;

      final dist = math.sqrt(math.pow(f.x - normX, 2) + math.pow(f.y - normY, 2));
      if (dist < 0.08) {
        // Hit!
        setState(() {
          f.isSliced = true;
          if (f.isBomb) {
            _lives--;
            _createExplosion(f.x, f.y);
            if (_lives <= 0) {
              _triggerGameOver();
              return;
            }
          } else {
            _score += f.points;
            _createSplashes(f.x, f.y, f.splashColor);
          }
        });
      }
    }
  }

  void _createSplashes(double x, double y, Color color) {
    for (int i = 0; i < 12; i++) {
      _particles.add(
        SplashParticle(
          x: x,
          y: y,
          vx: (_rand.nextDouble() - 0.5) * 0.02,
          vy: (_rand.nextDouble() - 0.5) * 0.02,
          color: color,
        ),
      );
    }
  }

  void _createExplosion(double x, double y) {
    for (int i = 0; i < 24; i++) {
      _particles.add(
        SplashParticle(
          x: x,
          y: y,
          vx: (_rand.nextDouble() - 0.5) * 0.04,
          vy: (_rand.nextDouble() - 0.5) * 0.04,
          color: i % 2 == 0 ? Colors.redAccent : Colors.orangeAccent,
        ),
      );
    }
  }

  void _triggerGameOver() {
    _isGameOver = true;
    _spawnTimer?.cancel();
    _showGameOverDialog();
  }

  void _reviveWithAd() {
    AdService.showRewardedAd(
      context: context,
      onRewarded: () {
        if (!mounted) return;
        Navigator.pop(context); // Close dialog
        setState(() {
          _lives = 3;
          _isGameOver = false;
          _hasRevivedOnce = true;
          _fruits.clear();
        });
        _startSpawner();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successGreen,
            content: Text('⚡ रिवाइव सफल! +3 अतिरिक्त लाइफ मिल गईं!'),
          ),
        );
      },
    );
  }

  void _claimRewardAndExit({bool doubleReward = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final res = await widget.appState.claimMiniGameReward(
      gameId: 'fruit_slash',
      score: _score,
      doubleReward: doubleReward,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.pop(context); // Close dialog
    AdService.showInterstitialAd(
      onDismissed: () {
        if (mounted) Navigator.pop(context); // Exit game
      },
    );

    final coins = res['coinsEarned'] ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: coins > 0 ? AppTheme.successGreen : AppTheme.bgCard,
        content: Text(coins > 0 ? '🎉 +$coins Coins वॉलेट में जुड़ गए!' : res['message'] ?? 'गेम समाप्त!'),
      ),
    );
  }

  void _showGameOverDialog() {
    final potentialCoins = math.min(3, (_score ~/ 50));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131B2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryGold, width: 2),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💥 ', style: TextStyle(fontSize: 22)),
            Text(
              'GAME OVER (आउट)',
              style: GoogleFonts.rajdhani(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryGold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('आपका कुल स्कोर: $_score', style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: AppTheme.primaryGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'अर्जित कॉइन्स: $potentialCoins / 3 मैक्स',
                    style: GoogleFonts.rajdhani(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Option 1: 1-Life Revive
            if (!_hasRevivedOnce) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyanAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.favorite, size: 18),
                label: const Text('रिवाइव (+3 Life) • वीडियो देखें', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _reviveWithAd,
              ),
              const SizedBox(height: 10),
            ],

            // Option 2: Double Reward
            if (potentialCoins > 0) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.stars, size: 18),
                label: Text('2X कॉइन्स पाएं (${potentialCoins * 2} Coins) • Ad', style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  AdService.showRewardedAd(
                    context: context,
                    onRewarded: () => _claimRewardAndExit(doubleReward: true),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            // Option 3: Normal Claim & Exit
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _claimRewardAndExit(doubleReward: false),
              child: const Text('कॉइन्स क्लेम करें और बाहर निकलें ➜'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _animController.dispose();
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await AdService.showInterstitialAd();
        if (context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BANNER AD (CONTINUOUS 2X REVENUE) ──
            if (_isTopBannerLoaded && _topBannerAd != null)
              SizedBox(
                height: 50,
                width: double.infinity,
                child: AdWidget(ad: _topBannerAd!),
              )
            else
              Container(
                height: 48,
                color: const Color(0xFF0F172A),
                alignment: Alignment.center,
                child: const Text(
                  '🔥 FRUIT SLASH • SWIPE TO SLICE',
                  style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),

            // ── HEADER STRIP (SCORE & LIVES) ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () async {
                      await AdService.showInterstitialAd();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  Row(
                    children: [
                      const Icon(Icons.stars, color: AppTheme.primaryGold, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '$_score',
                        style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Icon(
                          index < _lives ? Icons.favorite : Icons.favorite_border,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // ── MAIN INTERACTIVE GAME AREA ──
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanUpdate: (d) => _onPanUpdate(d, Size(constraints.maxWidth, constraints.maxHeight)),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          // Background pattern
                          Center(
                            child: Icon(
                              Icons.sports_martial_arts,
                              size: 160,
                              color: Colors.white.withValues(alpha: 0.03),
                            ),
                          ),

                          // Flying Fruits
                          ..._fruits.map((f) {
                            if (f.isSliced) return const SizedBox.shrink();
                            return Positioned(
                              left: f.x * constraints.maxWidth - 24,
                              top: f.y * constraints.maxHeight - 24,
                              child: Transform.rotate(
                                angle: f.rotation,
                                child: Text(f.emoji, style: const TextStyle(fontSize: 44)),
                              ),
                            );
                          }),

                          // Splashes
                          ..._particles.map((p) {
                            return Positioned(
                              left: p.x * constraints.maxWidth - 6,
                              top: p.y * constraints.maxHeight - 6,
                              child: Opacity(
                                opacity: p.opacity.clamp(0.0, 1.0),
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: p.color),
                                ),
                              ),
                            );
                          }),

                          // Swipe Trail
                          CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: BladeTrailPainter(points: _swipePoints),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── BOTTOM BANNER AD (SIMULTANEOUS DUAL BANNER) ──
            if (_isBottomBannerLoaded && _bottomBannerAd != null)
              SizedBox(
                height: 50,
                width: double.infinity,
                child: AdWidget(ad: _bottomBannerAd!),
              )
            else
              Container(
                height: 48,
                color: const Color(0xFF0F172A),
                alignment: Alignment.center,
                child: const Text(
                  '1 GAME = MAX 3 COINS • UNLIMITED PLAYS',
                  style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.5),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  }
}

class BladeTrailPainter extends CustomPainter {
  final List<Offset> points;

  BladeTrailPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = AppTheme.cyanAccent
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      paint.color = AppTheme.cyanAccent.withValues(alpha: (i + 1) / points.length);
      paint.strokeWidth = ((i + 1) / points.length) * 6.0;
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant BladeTrailPainter oldDelegate) => true;
}
