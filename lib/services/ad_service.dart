import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/video_ad_modal.dart';

class AdService {
  // Official Google Mobile Ads App ID (SW Gyan Bhumi: AI Study App)
  static const String appId = "ca-app-pub-2914481734058093~1029535853";

  // Official 100% Live Rewarded Video Ad Unit ID (booyehrewardads)
  static const String liveRewardedAdUnitId = "ca-app-pub-2914481734058093/6194763828";

  // Official 100% Live Interstitial Ad Unit ID (Booyah Rewards Interstitial)
  static const String liveInterstitialAdUnitId = "ca-app-pub-2914481734058093/7866592668";

  static String activeRewardedAdUnitId = liveRewardedAdUnitId;
  static String activeInterstitialAdUnitId = liveInterstitialAdUnitId;
  static bool _isInitialized = false;

  static InterstitialAd? _cachedInterstitialAd;
  static bool _isPreloadingInterstitial = false;
  static DateTime? _lastInterstitialShownTime;

  static RewardedAd? _cachedRewardedAd;
  static bool _isPreloadingRewarded = false;

  /// Initialize Google Mobile Ads SDK
  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdService] Google Mobile Ads Initialized Successfully with App ID: $appId');
      preloadInterstitialAd();
      preloadRewardedAd();
    } catch (e) {
      debugPrint('[AdService] MobileAds initialize error: $e');
    }
  }

  /// Update Ad Unit IDs at runtime if needed
  static void setRewardedAdUnitId(String unitId) {
    if (unitId.trim().isNotEmpty) {
      activeRewardedAdUnitId = unitId.trim();
    }
  }

  static void setInterstitialAdUnitId(String unitId) {
    if (unitId.trim().isNotEmpty) {
      activeInterstitialAdUnitId = unitId.trim();
    }
  }

  /// Preload Rewarded Video Ad in background for instant 0-second display
  static void preloadRewardedAd() {
    if (kIsWeb || _isPreloadingRewarded || _cachedRewardedAd != null) return;

    _isPreloadingRewarded = true;
    RewardedAd.load(
      adUnitId: activeRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _cachedRewardedAd = ad;
          _isPreloadingRewarded = false;
          debugPrint('[AdService] Rewarded Video Ad preloaded & ready for instant display.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _cachedRewardedAd = null;
          _isPreloadingRewarded = false;
          debugPrint('[AdService] Rewarded Ad preload error: ${error.message} (code: ${error.code})');
        },
      ),
    );
  }

  /// Preload Interstitial Ad in background for instant 0-latency display
  static void preloadInterstitialAd() {
    if (kIsWeb || _isPreloadingInterstitial || _cachedInterstitialAd != null) return;

    _isPreloadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: activeInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _cachedInterstitialAd = ad;
          _isPreloadingInterstitial = false;
          debugPrint('[AdService] Interstitial Ad preloaded & ready for mediation display.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _cachedInterstitialAd = null;
          _isPreloadingInterstitial = false;
          debugPrint('[AdService] Interstitial Ad preload failed: ${error.message} (code: ${error.code})');
        },
      ),
    );
  }

  /// Show Interstitial Ad (Triggered on Match Join, Room Access, Screen Transitions)
  static Future<void> showInterstitialAd({
    BuildContext? context,
    VoidCallback? onAdDismissed,
    bool force = false,
  }) async {
    if (kIsWeb) {
      if (onAdDismissed != null) onAdDismissed();
      return;
    }

    // Smart Cooldown: Avoid annoying users if shown in last 20 seconds (unless forced)
    final now = DateTime.now();
    if (!force && _lastInterstitialShownTime != null) {
      final diff = now.difference(_lastInterstitialShownTime!).inSeconds;
      if (diff < 20) {
        debugPrint('[AdService] Interstitial skipped due to 20s cooldown ($diff s elapsed)');
        if (onAdDismissed != null) onAdDismissed();
        return;
      }
    }

    // If preloaded ad is available, show instantly
    if (_cachedInterstitialAd != null) {
      final ad = _cachedInterstitialAd!;
      _cachedInterstitialAd = null; // Consume ad

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          debugPrint('[AdService] Interstitial Ad dismissed.');
          ad.dispose();
          _lastInterstitialShownTime = DateTime.now();
          preloadInterstitialAd(); // Preload next
          if (onAdDismissed != null) onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          debugPrint('[AdService] Interstitial Ad failed to show: ${error.message}');
          ad.dispose();
          preloadInterstitialAd();
          if (onAdDismissed != null) onAdDismissed();
        },
      );

      _lastInterstitialShownTime = now;
      ad.show();
      return;
    }

    // If not preloaded, load on the fly and show
    InterstitialAd.load(
      adUnitId: activeInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _lastInterstitialShownTime = DateTime.now();
              preloadInterstitialAd();
              if (onAdDismissed != null) onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              preloadInterstitialAd();
              if (onAdDismissed != null) onAdDismissed();
            },
          );
          _lastInterstitialShownTime = DateTime.now();
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdService] Direct Interstitial load failed: ${error.message}');
          if (onAdDismissed != null) onAdDismissed();
        },
      ),
    );
  }

  /// Load and Show 100% Real Live Google AdMob Rewarded Video Ad
  static Future<void> showRewardedAd({
    required BuildContext context,
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdDismissed,
  }) async {
    if (kIsWeb) {
      // Web Player Simulation
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => VideoAdModal(
          title: 'Rewarded Ad Player',
          rewardDescription: '+1 Ad Progress Recorded!',
          onAdCompleted: () {
            onUserEarnedReward();
            if (onAdDismissed != null) onAdDismissed();
          },
        ),
      );
      return;
    }

    // If preloaded Rewarded Ad is already ready in memory -> PLAY INSTANTLY with 0 delay!
    if (_cachedRewardedAd != null) {
      final ad = _cachedRewardedAd!;
      _cachedRewardedAd = null; // Consume ad

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          debugPrint('[AdService] RewardedAd dismissed.');
          ad.dispose();
          preloadRewardedAd(); // Immediately preload next ad in background!
          if (onAdDismissed != null) onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          debugPrint('[AdService] Failed to show cached RewardedAd: ${error.message}');
          ad.dispose();
          preloadRewardedAd();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade800,
                content: Text('Failed to show ad: ${error.message}'),
              ),
            );
          }
        },
      );

      ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('[AdService] User earned real reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward();
        },
      );
      return;
    }

    // Fallback: If not cached yet, show loading snackbar and fetch directly
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
            ),
            SizedBox(width: 12),
            Text('Loading Live Video Ad...'),
          ],
        ),
      ),
    );

    RewardedAd.load(
      adUnitId: activeRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('[AdService] Real Live RewardedAd loaded successfully: $activeRewardedAdUnitId');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              preloadRewardedAd(); // Preload next
              if (onAdDismissed != null) onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              debugPrint('[AdService] Failed to show RewardedAd: ${error.message}');
              ad.dispose();
              preloadRewardedAd();
              if (context.mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red.shade800,
                    content: Text('Failed to show ad: ${error.message}'),
                  ),
                );
              }
            },
          );

          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              debugPrint('[AdService] User earned real reward: ${reward.amount} ${reward.type}');
              onUserEarnedReward();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdService] Failed to load Real Live RewardedAd: ${error.message} (code: ${error.code})');
          preloadRewardedAd();
          if (context.mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade800,
                content: Text('Ad loading error: ${error.message}'),
              ),
            );
          }
        },
      ),
    );
  }
}
