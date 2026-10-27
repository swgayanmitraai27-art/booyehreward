import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme/app_theme.dart';

class AdService {
  // ─── Real Production Ad Unit IDs ───────────────────────────────────────────
  static const String rewardedAdUnitId = 'ca-app-pub-2914481734058093/6194763828';
  static const String bannerAdUnitId = 'ca-app-pub-2914481734058093/4561540966';
  static const String interstitialAdUnitId = 'ca-app-pub-2914481734058093/7866592668';

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  // Preloaded interstitial ad
  static InterstitialAd? _preloadedInterstitial;
  static bool _isInterstitialLoading = false;

  // Preloaded rewarded ad
  static RewardedAd? _preloadedRewarded;
  static bool _isRewardedLoading = false;

  // Global 60-Second Cooldown Timer Between Rewarded Ads
  static DateTime? _lastRewardedAdCompletedTime;
  static const int rewardedCooldownDurationSeconds = 60;

  static int get rewardedCooldownRemainingSeconds {
    if (_lastRewardedAdCompletedTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastRewardedAdCompletedTime!).inSeconds;
    final remaining = rewardedCooldownDurationSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  static bool get canShowRewardedAd => rewardedCooldownRemainingSeconds == 0;

  // ─── Initialize ─────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('AdMob initialized successfully');

      // Preload ads immediately so they are instantly ready when user plays/resets
      _preloadInterstitial();
      _preloadRewarded();
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
  }

  // ─── Interstitial: Preload ───────────────────────────────────────────────────
  static void _preloadInterstitial() {
    if (kIsWeb || _isInterstitialLoading || _preloadedInterstitial != null) return;
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _preloadedInterstitial = ad;
          _isInterstitialLoading = false;
          debugPrint('Interstitial ad preloaded and ready!');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialLoading = false;
          debugPrint('Interstitial preload failed: ${error.message} (code ${error.code})');
          // Retry fast (in 5s) to guarantee an ad is always cached
          Timer(const Duration(seconds: 5), _preloadInterstitial);
        },
      ),
    );
  }

  // ─── Interstitial: Show ──────────────────────────────────────────────────────
  static Future<void> showInterstitialAd({
    VoidCallback? onDismissed,
  }) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      onDismissed?.call();
      return;
    }

    // 1. If preloaded ad is ready, show it instantly!
    if (_preloadedInterstitial != null) {
      final ad = _preloadedInterstitial!;
      _preloadedInterstitial = null;

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          onDismissed?.call();
          _preloadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial failed to show: $error');
          ad.dispose();
          onDismissed?.call();
          _preloadInterstitial();
        },
      );

      await ad.show();
      return;
    }

    // 2. If no ad is preloaded yet, actively load & show on-demand with fallback
    debugPrint('No preloaded interstitial, loading on-demand...');
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onDismissed?.call();
              _preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onDismissed?.call();
              _preloadInterstitial();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('On-demand interstitial load failed: ${error.message}');
          _preloadInterstitial();
          onDismissed?.call();
        },
      ),
    );
  }

  // ─── Rewarded Ad: Preload ───────────────────────────────────────────────────
  static void _preloadRewarded() {
    if (kIsWeb || _isRewardedLoading || _preloadedRewarded != null) return;
    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _preloadedRewarded = ad;
          _isRewardedLoading = false;
          debugPrint('Rewarded ad preloaded and ready for instant playback!');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedLoading = false;
          debugPrint('Rewarded ad preload failed: ${error.message}');
          Timer(const Duration(seconds: 5), _preloadRewarded);
        },
      ),
    );
  }

  // ─── Rewarded Ad: Show ──────────────────────────────────────────────────────
  static Future<void> showRewardedAd({
    required BuildContext context,
    required VoidCallback onRewarded,
    VoidCallback? onDismissed,
    bool ignoreCooldown = false,
  }) async {
    // 🛑 Check 60-second cooldown timer (bypassed if ignoreCooldown is true, e.g. for mini-game revive / 2X bonus)
    final remainingCooldown = rewardedCooldownRemainingSeconds;
    if (!ignoreCooldown && remainingCooldown > 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppTheme.primaryGold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '⏳ कृपया $remainingCooldown सेकंड प्रतीक्षा करें (60s Cooldown Active)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.bgCard,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      onDismissed?.call();
      return;
    }

    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS)) {
      _showSimulatedRewardedAd(context, () {
        _lastRewardedAdCompletedTime = DateTime.now();
        onRewarded();
      }, onDismissed);
      return;
    }

    // 1. If preloaded rewarded ad is already available, SHOW INSTANTLY without waiting!
    if (_preloadedRewarded != null) {
      final ad = _preloadedRewarded!;
      _preloadedRewarded = null;

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          onDismissed?.call();
          _preloadRewarded(); // Queue up the next rewarded ad right away
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Rewarded ad failed to show: $error');
          ad.dispose();
          onDismissed?.call();
          _preloadRewarded();
        },
      );

      await ad.show(
        onUserEarnedReward: (AdWithoutView adWithoutView, RewardItem reward) {
          _lastRewardedAdCompletedTime = DateTime.now();
          onRewarded();
        },
      );
      return;
    }

    // 2. If not preloaded yet, show a brief loading dialog and fetch immediately
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold),
            ),
            SizedBox(width: 12),
            Text('Loading video ad...'),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: AppTheme.bgCard,
      ),
    );

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onDismissed?.call();
              _preloadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: $error');
              ad.dispose();
              onDismissed?.call();
              _preloadRewarded();
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView adWithoutView, RewardItem reward) {
              _lastRewardedAdCompletedTime = DateTime.now();
              onRewarded();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reward granted! Keeping tournament alive.'),
                backgroundColor: AppTheme.bgCardLight,
              ),
            );
            onRewarded();
          }
          onDismissed?.call();
          _preloadRewarded();
        },
      ),
    );
  }

  static void _showSimulatedRewardedAd(
    BuildContext context,
    VoidCallback onRewarded,
    VoidCallback? onDismissed,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryGold, size: 28),
              const SizedBox(width: 8),
              Text('Bonus Round', style: AppTheme.gamingTitle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stars_rounded, color: AppTheme.primaryGold, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Tournament Boost Active',
                      style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sponsor utility unlocked',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Claim bonus utility to keep your tournament streak alive!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textWhite, fontSize: 13),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _lastRewardedAdCompletedTime = DateTime.now();
                onRewarded();
                onDismissed?.call();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
              child: const Text('Claim Bonus', style: TextStyle(color: AppTheme.bgDark, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ─── Banner Ad ──────────────────────────────────────────────────────────────
  static BannerAd? createBannerAd({BannerAdListener? listener}) {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS)) {
      return null;
    }
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener ?? const BannerAdListener(),
    );
  }

  // ─── Large Banner (for Leaderboard / Profile) ────────────────────────────────
  static BannerAd? createLargeBannerAd({BannerAdListener? listener}) {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS)) {
      return null;
    }
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: listener ?? const BannerAdListener(),
    );
  }
}
