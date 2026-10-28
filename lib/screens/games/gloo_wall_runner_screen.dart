import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import '../../services/ad_service.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class GlooWallRunnerScreen extends StatefulWidget {
  final AppState appState;

  const GlooWallRunnerScreen({super.key, required this.appState});

  @override
  State<GlooWallRunnerScreen> createState() => _GlooWallRunnerScreenState();
}

enum EntityType { landmine, medkit, glooWall }

class GameEntity {
  int lane; // 0 = Left, 1 = Center, 2 = Right
  double y; // 0.0 = top spawn, 1.0 = bottom
  EntityType type;
  bool collected;

  GameEntity({
    required this.lane,
    required this.y,
    required this.type,
    this.collected = false,
  });
}

class _GlooWallRunnerScreenState extends State<GlooWallRunnerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Player State
  int _playerLane = 1; // 0, 1, 2
  int _score = 0;
  int _coinsEarned = 0;
  static const int maxCoinsHardCap = 3;
  static const int scorePerCoin = 50;

  bool _isGameOver = false;
  bool _hasRevivedOnce = false;
  double _gameSpeed = 0.012;

  final List<GameEntity> _entities = [];
  Timer? _spawnTimer;

  // Dual Banner Ads (Top & Bottom)
  BannerAd? _topBannerAd;
  bool _isTopBannerLoaded = false;
  BannerAd? _bottomBannerAd;
  bool _isBottomBannerLoaded = false;

  // Strategic Rewarded Ad Power-Up: Free Fire Level 4 Armor
  bool _hasArmorActive = false;

  @override
  void initState() {
    super.initState();
    _initBannerAds();

    // 60 FPS Game Loop
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
    _animController.repeat();

    // Spawner Timer
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted || _isGameOver) return;
      _spawnEntity();
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

  void _activateArmorWithRewardedAd() {
    AdService.showRewardedAd(
      context: context,
      ignoreCooldown: true,
      onRewarded: () {
        if (!mounted) return;
        setState(() => _hasArmorActive = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successGreen,
            content: Text('🛡️ लेवल 4 वेस्ट एक्टिवेटेड! 1 लैंडमाइन ब्लास्ट सुरक्षित!'),
          ),
        );
      },
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

  void _spawnEntity() {
    final rand = math.Random();
    int lane = rand.nextInt(3);
    // 70% Landmine obstacle, 30% Medkit bonus
    EntityType type = rand.nextDouble() < 0.3 ? EntityType.medkit : EntityType.landmine;

    setState(() {
      _entities.add(GameEntity(lane: lane, y: 0.0, type: type));
    });
  }

  void _gameLoop() {
    if (_isGameOver) return;

    setState(() {
      // Move all entities down
      for (int i = _entities.length - 1; i >= 0; i--) {
        final e = _entities[i];
        e.y += _gameSpeed;

        // Collision Check (Player at y ≈ 0.85)
        if (!e.collected && e.y >= 0.78 && e.y <= 0.90 && e.lane == _playerLane) {
          if (e.type == EntityType.medkit) {
            e.collected = true;
            _score += 15;
            _updateCoins();
          } else if (e.type == EntityType.landmine) {
            if (_hasArmorActive) {
              setState(() => _hasArmorActive = false);
              e.collected = true;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.primaryGold,
                  duration: Duration(seconds: 2),
                  content: Text('🛡️ लेवल 4 वेस्ट ने आपको बचा लिया! दौड़ते रहें!'),
                ),
              );
            } else {
              _triggerGameOver();
              return;
            }
          }
        }

        // Passed safely
        if (e.y > 1.05) {
          if (!e.collected && e.type == EntityType.landmine) {
            _score += 5;
            _updateCoins();
          }
          _entities.removeAt(i);
        }
      }

      // Slightly increase game speed over time
      if (_gameSpeed < 0.024) {
        _gameSpeed += 0.000005;
      }
    });
  }

  void _updateCoins() {
    // Hard Capped Coin calculation: 50 Score = 1 Coin, MAX 3 Coins per game!
    _coinsEarned = math.min(_score ~/ scorePerCoin, maxCoinsHardCap);
  }

  void _triggerGameOver() {
    setState(() => _isGameOver = true);
    _showGameOverModal();
  }

  void _moveLeft() {
    if (_isGameOver) return;
    if (_playerLane > 0) {
      setState(() => _playerLane--);
    }
  }

  void _moveRight() {
    if (_isGameOver) return;
    if (_playerLane < 2) {
      setState(() => _playerLane++);
    }
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
          _entities.clear(); // Clear all mines on screen
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
      gameId: 'gloo_wall_runner',
      score: _score,
      doubleReward: doubleReward,
    );

    if (!mounted) return;
    final int credited = (res['coinsEarned'] as num?)?.toInt() ?? 0;
    final String msg = res['message'] as String? ?? 'You Earned $credited Coins!';

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
            Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
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
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await AdService.showInterstitialAd();
        if (context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              await AdService.showInterstitialAd();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          title: Text(
          '⚡ GLOO WALL RUSH',
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

          // Top Stats Strip
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
                  child: const Text('🎯 50 अंक = 1 कॉइन', style: TextStyle(color: AppTheme.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('हार्ड कैप', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    Text('Max 3 Coins', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                  ],
                ),
              ],
            ),
          ),

          // 🛡️ Rewarded Video Power-Up Strip (Level 4 Armor)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _hasArmorActive ? Icons.security : Icons.security_outlined,
                      color: _hasArmorActive ? AppTheme.cyanAccent : Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _hasArmorActive ? 'लेवल 4 वेस्ट एक्टिव (1 ब्लास्ट सेफ)' : 'वेस्ट: इनएक्टिव',
                      style: TextStyle(
                        color: _hasArmorActive ? AppTheme.cyanAccent : Colors.white60,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!_hasArmorActive && !_isGameOver)
                  InkWell(
                    onTap: _activateArmorWithRewardedAd,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.cyanAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.cyanAccent, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.play_circle_fill, color: AppTheme.cyanAccent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '🛡️ वेस्ट लें (वीडियो देखें)',
                            style: TextStyle(color: AppTheme.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3-Lane 3D Cyber Battleground
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < 0) {
                    _moveLeft();
                  } else if (details.primaryVelocity! > 0) {
                    _moveRight();
                  }
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final laneWidth = constraints.maxWidth / 3;
                  final height = constraints.maxHeight;

                  return Stack(
                    children: [
                      // Lane Divider Lines
                      Positioned(
                        left: laneWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 1.5, color: Colors.white10),
                      ),
                      Positioned(
                        left: laneWidth * 2,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 1.5, color: Colors.white10),
                      ),

                      // Spawned Entities (Mines, Medkits)
                      for (final e in _entities)
                        if (!e.collected)
                          Positioned(
                            left: (e.lane * laneWidth) + (laneWidth / 2) - 22,
                            top: e.y * height,
                            child: e.type == EntityType.medkit
                                ? Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.6), blurRadius: 10),
                                      ],
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                                  )
                                : Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFBBF24), width: 2),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.6), blurRadius: 10),
                                      ],
                                    ),
                                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
                                  ),
                          ),

                      // Player Hero Character
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOutQuad,
                        left: (_playerLane * laneWidth) + (laneWidth / 2) - 26,
                        top: height * 0.82,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.8), blurRadius: 14, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.shield, color: Colors.white, size: 30),
                        ),
                      ),

                      // On-Screen Touch Controls (Left / Right Arrows)
                      Positioned(
                        bottom: 16,
                        left: 20,
                        child: InkWell(
                          onTap: _moveLeft,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.cyanAccent.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: AppTheme.cyanAccent, size: 26),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 20,
                        child: InkWell(
                          onTap: _moveRight,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.cyanAccent.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: const Icon(Icons.arrow_forward_ios, color: AppTheme.cyanAccent, size: 26),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
    ),
  );
  }
}
