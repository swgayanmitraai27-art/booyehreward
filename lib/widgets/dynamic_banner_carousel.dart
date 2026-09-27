import 'dart:async';
import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../theme/app_theme.dart';
import '../utils/url_launcher_util.dart';

class DynamicBannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;

  const DynamicBannerCarousel({super.key, required this.banners});

  @override
  State<DynamicBannerCarousel> createState() => _DynamicBannerCarouselState();
}

class _DynamicBannerCarouselState extends State<DynamicBannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (widget.banners.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          final nextPage = (_currentPage + 1) % widget.banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant DynamicBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: child,
                  );
                },
                child: InkWell(
                  onTap: () {
                    if (banner.clickUrl.isNotEmpty) {
                      UrlLauncherUtil.openUrl(banner.clickUrl);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Banner Image (Network or Asset)
                          banner.imageUrl.startsWith('http')
                              ? Image.network(
                                  banner.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildFallbackBanner(banner),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: const Color(0xFF1E293B),
                                      child: const Center(
                                        child: CircularProgressIndicator(color: AppTheme.primaryAmber, strokeWidth: 2),
                                      ),
                                    );
                                  },
                                )
                              : Image.asset(
                                  banner.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => _buildFallbackBanner(banner),
                                ),

                          // Subtle Gradient Shadow Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(190),
                                ],
                              ),
                            ),
                          ),

                          // Banner Content
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 12,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (banner.title.isNotEmpty)
                                        Text(
                                          banner.title,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(color: Colors.black, blurRadius: 4),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 2),
                                      const Row(
                                        children: [
                                          Icon(Icons.touch_app, size: 12, color: AppTheme.primaryAmber),
                                          SizedBox(width: 4),
                                          Text(
                                            'Tap to Open',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryAmber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAmber,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.arrow_forward, size: 14, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Indicator Dots
        if (widget.banners.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (index) {
              final isSelected = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryAmber : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildFallbackBanner(BannerModel banner) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_esports, size: 36, color: AppTheme.primaryAmber),
            const SizedBox(height: 4),
            Text(
              banner.title.isNotEmpty ? banner.title : 'BOOYAH REWARDS ESPORTS',
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
