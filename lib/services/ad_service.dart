import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/video_ad_modal.dart';

class AdService {
  // Official Google Mobile Ads App ID (SW Gyan Bhumi: AI Study App)
  static const String appId = "ca-app-pub-2914481734058093~1029535853";

  // Official Live Rewarded Video Ad Unit ID (booyehrewardads)
  static const String liveRewardedAdUnitId = "ca-app-pub-2914481734058093/6194763828";

  // Google Official Test Rewarded Ad Unit ID (Always available for testing)
  static const String testRewardedAdUnitId = "ca-app-pub-3940256099942544/5224354917";

  static String activeRewardedAdUnitId = liveRewardedAdUnitId;
  static bool _isInitialized = false;

  /// Initialize Google Mobile Ads SDK
  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdService] Google Mobile Ads Initialized Successfully with App ID: $appId');
    } catch (e) {
      debugPrint('[AdService] MobileAds initialize error: $e');
    }
  }

  /// Update Ad Unit ID at runtime
  static void setRewardedAdUnitId(String unitId) {
    if (unitId.trim().isNotEmpty) {
      activeRewardedAdUnitId = unitId.trim();
    }
  }

  /// Load and Show Rewarded Video Ad
  /// Works across Android Native (Google Mobile Ads) and Web (Interactive VideoAdModal fallback)
  static Future<void> showRewardedAd({
    required BuildContext context,
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdDismissed,
  }) async {
    if (kIsWeb) {
      // Flutter Web: Show high quality interactive video simulation modal
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

    // Android / iOS: Load and show real Google AdMob Rewarded Video
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading snackbar/indicator
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
            Text('Loading Rewarded Video Ad...'),
          ],
        ),
      ),
    );

    _loadAndShow(
      adUnitId: activeRewardedAdUnitId,
      context: context,
      onUserEarnedReward: onUserEarnedReward,
      onAdDismissed: onAdDismissed,
      isRetry: false,
    );
  }

  static void _loadAndShow({
    required String adUnitId,
    required BuildContext context,
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdDismissed,
    required bool isRetry,
  }) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('[AdService] RewardedAd loaded successfully from unit: $adUnitId');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              if (onAdDismissed != null) onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              debugPrint('[AdService] Failed to show RewardedAd: ${error.message}');
              ad.dispose();
              _showFallbackModal(context, onUserEarnedReward, onAdDismissed);
            },
          );

          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
              onUserEarnedReward();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdService] Failed to load RewardedAd ($adUnitId): ${error.message} (code: ${error.code})');

          // If Live Ad failed (e.g. AdMob ad unit pending approval or no-fill during new setup),
          // seamlessly fallback to official Google Test Video Ad so testing NEVER breaks.
          if (!isRetry && adUnitId != testRewardedAdUnitId) {
            debugPrint('[AdService] Retrying with Google Test Rewarded Ad Unit ID for instant verification...');
            _loadAndShow(
              adUnitId: testRewardedAdUnitId,
              context: context,
              onUserEarnedReward: onUserEarnedReward,
              onAdDismissed: onAdDismissed,
              isRetry: true,
            );
          } else {
            _showFallbackModal(context, onUserEarnedReward, onAdDismissed);
          }
        },
      ),
    );
  }

  static void _showFallbackModal(
    BuildContext context,
    VoidCallback onUserEarnedReward,
    VoidCallback? onAdDismissed,
  ) {
    if (context.mounted) {
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
    }
  }
}
