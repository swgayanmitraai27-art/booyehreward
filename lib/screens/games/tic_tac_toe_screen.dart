import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import '../../services/ad_service.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class TicTacToeScreen extends StatefulWidget {
  final AppState appState;

  const TicTacToeScreen({super.key, required this.appState});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  // Board: null = empty, 'X' = User, 'O' = Cyber AI
  List<String?> _board = List.filled(9, null);
  bool _isPlayerTurn = true;
  int _score = 0;
  int _round = 1;
  int _playerWins = 0;
  int _aiWins = 0;
  bool _isGameOver = false;
  bool _isSubmitting = false;

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
  }

  void _initBannerAds() {
    if (kIsWeb) return;
    _topBannerAd = AdService.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isTopBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('TicTacToe top banner failed: $err');
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
          debugPrint('TicTacToe bottom banner failed: $err');
          ad.dispose();
        },
      ),
    );
    _bottomBannerAd?.load();
  }

  void _handleTap(int index) {
    if (_board[index] != null || !_isPlayerTurn || _isGameOver) return;

    setState(() {
      _board[index] = 'X';
      _isPlayerTurn = false;
    });

    final winner = _checkWinner();
    if (winner != null) {
      _finishRound(winner);
      return;
    }

    if (_isBoardFull()) {
      _finishRound('D'); // Draw
      return;
    }

    // AI Turn with brief realistic thinking delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || _isGameOver) return;
      _makeAiMove();
    });
  }

  void _makeAiMove() {
    // 1. Try winning move
    for (int i = 0; i < 9; i++) {
      if (_board[i] == null) {
        _board[i] = 'O';
        if (_checkWinner() == 'O') {
          setState(() => _isPlayerTurn = true);
          _finishRound('O');
          return;
        }
        _board[i] = null;
      }
    }

    // 2. Block player's winning move
    for (int i = 0; i < 9; i++) {
      if (_board[i] == null) {
        _board[i] = 'X';
        if (_checkWinner() == 'X') {
          _board[i] = 'O';
          setState(() => _isPlayerTurn = true);
          final w = _checkWinner();
          if (w != null) {
            _finishRound(w);
          } else if (_isBoardFull()) {
            _finishRound('D');
          }
          return;
        }
        _board[i] = null;
      }
    }

    // 3. Take center if available
    if (_board[4] == null && _rand.nextDouble() < 0.65) {
      setState(() {
        _board[4] = 'O';
        _isPlayerTurn = true;
      });
      if (_isBoardFull()) _finishRound('D');
      return;
    }

    // 4. Random available cell
    final empties = <int>[];
    for (int i = 0; i < 9; i++) {
      if (_board[i] == null) empties.add(i);
    }

    if (empties.isNotEmpty) {
      final chosen = empties[_rand.nextInt(empties.length)];
      setState(() {
        _board[chosen] = 'O';
        _isPlayerTurn = true;
      });

      final w = _checkWinner();
      if (w != null) {
        _finishRound(w);
      } else if (_isBoardFull()) {
        _finishRound('D');
      }
    }
  }

  String? _checkWinner() {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];

    for (final line in lines) {
      final a = _board[line[0]];
      final b = _board[line[1]];
      final c = _board[line[2]];
      if (a != null && a == b && b == c) {
        return a;
      }
    }
    return null;
  }

  bool _isBoardFull() {
    return _board.every((cell) => cell != null);
  }

  void _finishRound(String result) {
    if (result == 'X') {
      _playerWins++;
      _score += 25;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 1),
          content: Text('🎉 राउंड जीता! +25 Points!'),
        ),
      );
    } else if (result == 'O') {
      _aiWins++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.errorRed,
          duration: Duration(seconds: 1),
          content: Text('🤖 साइबर बॉट ने राउंड जीता!'),
        ),
      );
    } else {
      _score += 10;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.bgCard,
          duration: Duration(seconds: 1),
          content: Text('🤝 राउंड ड्रॉ! +10 Points!'),
        ),
      );
    }

    if (_round >= 5 || _aiWins >= 3) {
      _isGameOver = true;
      _showGameOverDialog();
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || _isGameOver) return;
        setState(() {
          _round++;
          _board = List.filled(9, null);
          _isPlayerTurn = true;
        });
      });
    }
  }

  void _claimRewardAndExit({bool doubleReward = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final res = await widget.appState.claimMiniGameReward(
      gameId: 'tic_tac_toe',
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
            const Text('🏆 ', style: TextStyle(fontSize: 22)),
            Text(
              'MATCH FINISHED',
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
            Text('खिलाड़ी: $_playerWins जीत • AI: $_aiWins जीत', style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 8),
            Text('कुल स्कोर: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
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

            // Option 1: Double Reward
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

            // Option 2: Normal Claim & Exit
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
                  '⭕ TIC TAC TOE ARENA • FREE FIRE BATTLE',
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
                    onPressed: () async {
                      await AdService.showInterstitialAd();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  Text(
                    'राउंड $_round / 5',
                    style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.stars, color: AppTheme.primaryGold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$_score PTS',
                        style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Turn Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: _isPlayerTurn ? const Color(0xFF1E293B) : const Color(0xFF312E81),
              alignment: Alignment.center,
              child: Text(
                _isPlayerTurn ? '🎮 आपकी बारी (Katana X)' : '🤖 Cyber AI सोच रहा है...',
                style: TextStyle(
                  color: _isPlayerTurn ? AppTheme.cyanAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            // ── 3X3 GRID BOARD ──
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4), width: 2),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.15), blurRadius: 20),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final val = _board[index];
                      return InkWell(
                        onTap: () => _handleTap(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          alignment: Alignment.center,
                          child: val == null
                              ? const SizedBox.shrink()
                              : Text(
                                  val == 'X' ? '⚔️' : '🛡️',
                                  style: TextStyle(
                                    fontSize: 44,
                                    color: val == 'X' ? AppTheme.cyanAccent : Colors.orangeAccent,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
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
    ),
  );
  }
}
