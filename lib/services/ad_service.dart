import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/video_ad_modal.dart';

class AdService {
  // Official Google Mobile Ads App ID (SW Gyan Bhumi: AI Study App)
  static const String appId = "ca-app-pub-2914481734058093~1029535853";

  // Official 100% Live Rewarded Video Ad Unit ID (booyehrewardads)
  static const String liveRewardedAdUnitId = "ca-app-pub-2914481734058093/6194763828";

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

  /// Update Ad Unit ID at runtime if needed
  static void setRewardedAdUnitId(String unitId) {
    if (unitId.trim().isNotEmpty) {
      activeRewardedAdUnitId = unitId.trim();
    }
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

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading indicator
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
              if (onAdDismissed != null) onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              debugPrint('[AdService] Failed to show RewardedAd: ${error.message}');
              ad.dispose();
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
