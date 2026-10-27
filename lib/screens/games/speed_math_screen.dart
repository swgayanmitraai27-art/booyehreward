import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import '../../services/ad_service.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class SpeedMathScreen extends StatefulWidget {
  final AppState appState;

  const SpeedMathScreen({super.key, required this.appState});

  @override
  State<SpeedMathScreen> createState() => _SpeedMathScreenState();
}

class _SpeedMathScreenState extends State<SpeedMathScreen> {
  int _score = 0;
  int _streak = 0;
  bool _isGameOver = false;
  bool _hasRevivedOnce = false;
  bool _isSubmitting = false;

  late String _question;
  late int _correctAnswer;
  late List<int> _options;

  // Question Timer
  int _secondsLeft = 10;
  Timer? _questionTimer;

  // Dual Banner Ads
  BannerAd? _topBannerAd;
  bool _isTopBannerLoaded = false;
  BannerAd? _bottomBannerAd;
  bool _isBottomBannerLoaded = false;

  final math.Random _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _initBannerAds();
    _generateNewQuestion();
  }

  void _initBannerAds() {
    if (kIsWeb) return;
    _topBannerAd = AdService.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isTopBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('SpeedMath top banner failed: $err');
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
          debugPrint('SpeedMath bottom banner failed: $err');
          ad.dispose();
        },
      ),
    );
    _bottomBannerAd?.load();
  }

  void _generateNewQuestion() {
    _questionTimer?.cancel();
    _secondsLeft = 10;

    final type = _rand.nextInt(3); // 0 = add, 1 = sub, 2 = mul
    int a, b;

    if (type == 0) {
      // Addition
      a = _rand.nextInt(30) + 5;
      b = _rand.nextInt(30) + 5;
      _correctAnswer = a + b;
      _question = '$a + $b = ?';
    } else if (type == 1) {
      // Subtraction
      a = _rand.nextInt(40) + 15;
      b = _rand.nextInt(a - 5) + 3;
      _correctAnswer = a - b;
      _question = '$a - $b = ?';
    } else {
      // Multiplication
      a = _rand.nextInt(12) + 2;
      b = _rand.nextInt(10) + 2;
      _correctAnswer = a * b;
      _question = '$a × $b = ?';
    }

    final opts = <int>{_correctAnswer};
    while (opts.length < 4) {
      final offset = (_rand.nextInt(9) + 1) * (_rand.nextBool() ? 1 : -1);
      final fake = _correctAnswer + offset;
      if (fake >= 0) opts.add(fake);
    }
    _options = opts.toList()..shuffle(_rand);

    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          timer.cancel();
          _triggerGameOver('⏰ समय समाप्त! (Time Out)');
        }
      });
    });
  }

  void _selectAnswer(int ans) {
    if (_isGameOver) return;

    if (ans == _correctAnswer) {
      setState(() {
        _streak++;
        _score += 10 + (_streak > 3 ? 5 : 0);
      });
      _generateNewQuestion();
    } else {
      _triggerGameOver('❌ गलत उत्तर! सही उत्तर था: $_correctAnswer');
    }
  }

  void _triggerGameOver(String reason) {
    _questionTimer?.cancel();
    setState(() => _isGameOver = true);
    _showGameOverDialog(reason);
  }

  void _reviveWithAd() {
    AdService.showRewardedAd(
      context: context,
      onRewarded: () {
        if (!mounted) return;
        Navigator.pop(context);
        setState(() {
          _isGameOver = false;
          _hasRevivedOnce = true;
        });
        _generateNewQuestion();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successGreen,
            content: Text('⚡ रिवाइव सफल! खेल जारी रखें!'),
          ),
        );
      },
    );
  }

  void _claimRewardAndExit({bool doubleReward = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final res = await widget.appState.claimMiniGameReward(
      gameId: 'speed_math',
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

  void _showGameOverDialog(String reason) {
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
            const Text('🧠 ', style: TextStyle(fontSize: 22)),
            Text(
              'GAME OVER',
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
            Text(reason, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 10),
            Text('आपका कुल स्कोर: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('1 लाइफ रिवाइव • वीडियो देखें', style: TextStyle(fontWeight: FontWeight.bold)),
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
    _questionTimer?.cancel();
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BANNER AD ──
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
                  '➕ SPEED MATH ARENA • QUICK BRAIN QUIZ',
                  style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),

            // ── HEADER STRIP ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _secondsLeft <= 3 ? Colors.redAccent.withValues(alpha: 0.2) : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _secondsLeft <= 3 ? Colors.redAccent : AppTheme.primaryGold),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: _secondsLeft <= 3 ? Colors.redAccent : AppTheme.primaryGold),
                        const SizedBox(width: 4),
                        Text(
                          '${_secondsLeft}s',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _secondsLeft <= 3 ? Colors.redAccent : AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Countdown Progress Bar
            LinearProgressIndicator(
              value: _secondsLeft / 10.0,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(_secondsLeft <= 3 ? Colors.redAccent : AppTheme.cyanAccent),
              minHeight: 4,
            ),

            // ── MAIN QUESTION & OPTIONS ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_streak > 2)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryGold),
                        ),
                        child: Text(
                          '🔥 $_streak Streak! (+Bonus Points)',
                          style: const TextStyle(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),

                    // Question Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.1), blurRadius: 20),
                        ],
                      ),
                      child: Text(
                        _question,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rajdhani(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 4 Option Buttons (2x2 Grid)
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _options.length,
                        itemBuilder: (ctx, idx) {
                          final opt = _options[idx];
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A2333),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.white12, width: 1.2),
                              ),
                            ),
                            onPressed: () => _selectAnswer(opt),
                            child: Text(
                              '$opt',
                              style: GoogleFonts.rajdhani(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.cyanAccent,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── BOTTOM BANNER AD ──
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
    );
  }
}
