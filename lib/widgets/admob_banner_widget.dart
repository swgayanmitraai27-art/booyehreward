import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class AdmobBannerWidget extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsetsGeometry padding;
  final int refreshIntervalSeconds;

  const AdmobBannerWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    this.refreshIntervalSeconds = 35, // Complies with Google AdMob 30s+ minimum policy
  });

  @override
  State<AdmobBannerWidget> createState() => _AdmobBannerWidgetState();
}

class _AdmobBannerWidgetState extends State<AdmobBannerWidget> with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  Timer? _refreshTimer;
  DateTime _lastLoadTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBannerAd();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    if (widget.refreshIntervalSeconds < 30) return;

    _refreshTimer = Timer.periodic(
      Duration(seconds: widget.refreshIntervalSeconds),
      (_) {
        if (!mounted || AdService.isAdsDisabled) return;
        _loadBannerAd();
      },
    );
  }

  void _loadBannerAd({bool isFallback = false}) {
    if (kIsWeb || AdService.isAdsDisabled) return;

    final targetSize = isFallback ? AdSize.banner : widget.adSize;
    final oldAd = _bannerAd;

    final newAd = BannerAd(
      adUnitId: AdService.activeBannerAdUnitId,
      size: targetSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdmobBannerWidget] Fresh Banner Ad loaded & rotated ($targetSize): ${AdService.activeBannerAdUnitId}');
          oldAd?.dispose();
          _lastLoadTime = DateTime.now();
          if (mounted) {
            setState(() {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdmobBannerWidget] Banner load failed for size $targetSize: ${error.message} (code: ${error.code})');
          ad.dispose();
          if (!isFallback && widget.adSize != AdSize.banner) {
            // Automatically try standard banner size if larger size had no fill
            _loadBannerAd(isFallback: true);
            return;
          }
          if (oldAd != null && mounted) {
            // Keep existing banner visible if refresh fails temporarily
            setState(() {
              _bannerAd = oldAd;
              _isLoaded = true;
            });
          } else if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },
      ),
    );

    newAd.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (DateTime.now().difference(_lastLoadTime).inSeconds >= 30) {
        _loadBannerAd();
      }
      _startRefreshTimer();
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || AdService.isAdsDisabled || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: widget.padding,
      alignment: Alignment.center,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
